import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';

class EditMembershipDialog extends ConsumerStatefulWidget {
  final MembershipPlanModel plan;
  const EditMembershipDialog({Key? key, required this.plan}) : super(key: key);

  @override
  _EditMembershipDialogState createState() => _EditMembershipDialogState();
}

class _EditMembershipDialogState extends ConsumerState<EditMembershipDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _featuresController;
  String _selectedBillingCycle = 'monthly';
  final _billingCycles = ['monthly', 'yearly', 'quarterly'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan.name);
    _descriptionController = TextEditingController(text: widget.plan.description);
    _priceController = TextEditingController(text: widget.plan.price.toString());
    _featuresController = TextEditingController(text: widget.plan.features.join(', '));
    _selectedBillingCycle = widget.plan.billingCycle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(membershipNotifierProvider.notifier).updateMembership(
        id: widget.plan.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        billingCycle: _selectedBillingCycle,
        features: _featuresController.text.split(',').map((f) => f.trim()).toList(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Membership Plan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBillingCycle,
                      decoration: const InputDecoration(
                        labelText: 'Billing Cycle',
                        border: OutlineInputBorder(),
                      ),
                      items: _billingCycles.map((cycle) {
                        return DropdownMenuItem<String>(
                          value: cycle,
                          child: Text(cycle[0].toUpperCase() + cycle.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedBillingCycle = value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a billing cycle';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Unlimited access, Priority support',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter features';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Plan'),
        ),
      ],
    );
  }
}
