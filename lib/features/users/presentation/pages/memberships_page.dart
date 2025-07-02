import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';
import 'package:osp_broker_admin/features/users/presentation/widgets/user_memberships_table.dart';

class MembershipsPage extends ConsumerStatefulWidget {
  const MembershipsPage({super.key, this.onBackPressed});
  
  final VoidCallback? onBackPressed;

  @override
  ConsumerState<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends ConsumerState<MembershipsPage> {
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  final Set<String> _selectedUserIds = {};
  bool _isBulkActionInProgress = false;

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      if (_isInitialLoad) {
        // Only show loading indicator on first load
        _isRefreshing = true;
      }
    });

    try {
      // Load users first
      await ref.read(userNotifierProvider.notifier).fetchUsers();
      
      // Load memberships and plans in parallel
      await Future.wait([
        ref.read(userNotifierProvider.notifier).loadAllUserMemberships(),
        ref.read(membershipNotifierProvider.notifier).fetchMemberships(),
      ]);
      
      if (mounted && !_isInitialLoad) {
        // Only show success message on refresh, not initial load
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Start loading data when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(userNotifierProvider).users;
    final isLoading = ref.watch(
      userNotifierProvider.select((state) => 
        state.isLoadingMemberships || _isInitialLoad || _isRefreshing
      ),
    );
    final error = ref.watch(userNotifierProvider.select((state) => state.error));
    
    // Show loading indicator if no data is loaded yet or if we're refreshing
    if (_isInitialLoad && users.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopBar(
            userName: 'Admin',
            userRole: 'Admin',
            greeting: _selectedUserIds.isEmpty 
                ? 'User Memberships' 
                : '${_selectedUserIds.length} selected',
            showBackButton: true,
            onBackPressed: () {
              if (_selectedUserIds.isNotEmpty) {
                setState(() => _selectedUserIds.clear());
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/users');
              }
            },
          ),
          if (error != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.red[100],
              child: Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_selectedUserIds.isNotEmpty) _buildBulkActionBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                setState(() {
                  _isRefreshing = true;
                });
                return _loadData();
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : UserMembershipsTable(
                          users: users,
                          selectedUserIds: _selectedUserIds,
                          onUserSelected: (userId, selected) {
                            setState(() {
                              if (selected) {
                                _selectedUserIds.add(userId);
                              } else {
                                _selectedUserIds.remove(userId);
                              }
                            });
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar() {
    final membershipPlans = ref.read(membershipNotifierProvider).plans;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Text(
            '${_selectedUserIds.length} users selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (!_isBulkActionInProgress) ...[
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Membership'),
              onPressed: membershipPlans.isEmpty ? null : _showBulkAddMembershipDialog,
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              label: const Text('Remove Memberships', style: TextStyle(color: Colors.red)),
              onPressed: _selectedUserIds.isEmpty ? null : _showBulkRemoveConfirmation,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _showBulkAddMembershipDialog() async {
    final membershipPlans = ref.read(membershipNotifierProvider).plans;
    if (membershipPlans.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No membership plans available')),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BulkAddMembershipDialog(plans: membershipPlans),
    );

    if (result != null && mounted) {
      final planId = result['planId'] as String;
      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;
      
      setState(() => _isBulkActionInProgress = true);
      
      try {
        final notifier = ref.read(userNotifierProvider.notifier);
        int successCount = 0;
        
        for (final userId in _selectedUserIds) {
          try {
            await notifier.createUserMembership(
              userId: userId,
              membershipPlanId: planId,
              startDate: startDate,
              endDate: endDate,
              status: 'active',
            );
            successCount++;
          } catch (e) {
            debugPrint('Error adding membership to user $userId: $e');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added memberships to $successCount users')),
          );
          setState(() => _selectedUserIds.clear());
        }
      } finally {
        if (mounted) {
          setState(() => _isBulkActionInProgress = false);
        }
      }
    }
  }

  Future<void> _showBulkRemoveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Memberships'),
        content: Text(
          'Are you sure you want to remove all memberships from ${_selectedUserIds.length} users?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isBulkActionInProgress = true);
      
      try {
        final notifier = ref.read(userNotifierProvider.notifier);
        int successCount = 0;
        
        for (final userId in _selectedUserIds.toList()) {
          try {
            // Get user's memberships
            final memberships = ref.read(userNotifierProvider)
                .userMemberships[userId] ?? [];
                
            // Delete each membership
            for (final membership in memberships) {
              await notifier.deleteUserMembership(membership.id, userId);
            }
            successCount++;
          } catch (e) {
            debugPrint('Error removing memberships from user $userId: $e');
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed memberships from $successCount users')),
          );
          setState(() => _selectedUserIds.clear());
        }
      } finally {
        if (mounted) {
          setState(() => _isBulkActionInProgress = false);
        }
      }
    }
  }
}

class _BulkAddMembershipDialog extends StatefulWidget {
  final List<MembershipPlanModel> plans;

  const _BulkAddMembershipDialog({required this.plans});

  @override
  _BulkAddMembershipDialogState createState() => _BulkAddMembershipDialogState();
}

class _BulkAddMembershipDialogState extends State<_BulkAddMembershipDialog> {
  late MembershipPlanModel _selectedPlan;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.plans.first;
    _startDate = DateTime.now();
    _endDate = _calculateEndDate(_startDate, _selectedPlan.billingCycle);
  }

  DateTime _calculateEndDate(DateTime startDate, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'monthly':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case 'quarterly':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case 'yearly':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Memberships'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<MembershipPlanModel>(
              value: _selectedPlan,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Membership Plan'),
              items: widget.plans.map((plan) {
                return DropdownMenuItem(
                  value: plan,
                  child: Text(plan.name),
                );
              }).toList(),
              onChanged: (plan) {
                if (plan != null) {
                  setState(() {
                    _selectedPlan = plan;
                    _endDate = _calculateEndDate(_startDate, plan.billingCycle);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_startDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                    _endDate = _calculateEndDate(_startDate, _selectedPlan.billingCycle);
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_endDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'planId': _selectedPlan.id,
              'startDate': _startDate,
              'endDate': _endDate,
            });
          },
          child: const Text('Add to Selected Users'),
        ),
      ],
    );
  }
}
