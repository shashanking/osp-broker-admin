import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';

class AddUserMembershipDialog extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const AddUserMembershipDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<AddUserMembershipDialog> createState() =>
      _AddUserMembershipDialogState();
}

class _AddUserMembershipDialogState
    extends ConsumerState<AddUserMembershipDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedPlanId;
  late DateTime _startDate;
  late DateTime _endDate;
  final String _status = 'active';
  bool _isSubmitting = false;

  void _updateEndDateBasedOnBillingCycle() {
    if (_selectedPlanId.isEmpty) return;
    
    final plan = ref.read(membershipNotifierProvider).plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => ref.read(membershipNotifierProvider).plans.first,
    );

    if (plan.billingCycle == 'monthly') {
      _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
    } else if (plan.billingCycle == 'quarterly') {
      _endDate = DateTime(_startDate.year, _startDate.month + 3, _startDate.day);
    } else if (plan.billingCycle == 'yearly') {
      _endDate = DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
    } else {
      // Default to 30 days if no valid billing cycle
      _endDate = _startDate.add(const Duration(days: 30));
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedPlanId = '';
    _startDate = DateTime.now();
    _endDate = _startDate.add(const Duration(days: 30));

    // Load membership plans if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(membershipNotifierProvider.notifier).fetchMemberships();
        if (mounted) {
          final state = ref.read(membershipNotifierProvider);
          if (state.plans.isNotEmpty) {
            setState(() {
              _selectedPlanId = state.plans.first.id;
              _updateEndDateBasedOnBillingCycle();
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading plans: $e')),
          );
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Update end date based on the billing cycle when start date changes
          _updateEndDateBasedOnBillingCycle();
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a membership plan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(userNotifierProvider.notifier).createUserMembership(
            userId: widget.userId,
            membershipPlanId: _selectedPlanId,
            startDate: _startDate,
            endDate: _endDate,
            status: _status,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membership added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add membership: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipState = ref.watch(membershipNotifierProvider);
    final plans = membershipState.plans;

    return AlertDialog(
      title: const Text('Add Membership'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${widget.userName}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPlanId.isNotEmpty ? _selectedPlanId : null,
                decoration: const InputDecoration(
                  labelText: 'Membership Plan',
                  border: OutlineInputBorder(),
                ),
                items: plans.map((plan) {
                  final durationText = plan.billingCycle != null
                      ? '${plan.billingCycle} billing cycle'
                      : 'Custom';
                  return DropdownMenuItem(
                    value: plan.id,
                    child:
                        Text('${plan.name} ($durationText) - \$${plan.price}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPlanId = value;
                      _updateEndDateBasedOnBillingCycle();
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Please select a plan' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Add Membership'),
        ),
      ],
    );
  }
}
