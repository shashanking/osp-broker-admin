import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';
import 'package:osp_broker_admin/features/users/data/models/user_model.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';
import 'package:osp_broker_admin/features/users/data/models/user_membership_model.dart';
import 'package:osp_broker_admin/features/users/presentation/widgets/membership_status_chip.dart';
import 'package:osp_broker_admin/features/users/presentation/widgets/add_user_membership_dialog.dart';

class UserMembershipsTable extends ConsumerStatefulWidget {
  final List<UserModel> users;
  final Set<String> selectedUserIds;
  final Function(String, bool) onUserSelected;

  const UserMembershipsTable({
    super.key,
    required this.users,
    this.selectedUserIds = const {},
    required this.onUserSelected,
  });

  @override
  ConsumerState<UserMembershipsTable> createState() =>
      _UserMembershipsTableState();
}

class _UserMembershipsTableState extends ConsumerState<UserMembershipsTable> {
  Future<void> _showDeleteConfirmation(
      BuildContext context, String membershipId, String userId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Membership'),
          content: const Text(
              'Are you sure you want to delete this membership? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref
                    .read(userNotifierProvider.notifier)
                    .deleteUserMembership(membershipId, userId);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membership deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete membership'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Load memberships for all users and plans when the table is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membershipNotifierProvider.notifier).fetchMemberships();
      ref.read(userNotifierProvider.notifier).loadAllUserMemberships();
    });
  }

  @override
  void didUpdateWidget(UserMembershipsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If users list has changed, reload memberships
    if (widget.users.length != oldWidget.users.length ||
        !const SetEquality().equals(
          widget.users.map((u) => u.id).toSet(),
          oldWidget.users.map((u) => u.id).toSet(),
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userNotifierProvider.notifier).loadAllUserMemberships();
      });
    }
  }

  Future<void> _showAddMembershipDialog(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddUserMembershipDialog(
        userId: user.id,
        userName: user.fullName,
      ),
    );

    if (result == true) {
      // Refresh the user's memberships after adding a new one
      ref.read(userNotifierProvider.notifier).loadUserMemberships(user.id);
    }
  }

  Widget _getPlanName(String? planId, List<MembershipPlanModel> plans) {
    if (planId == null || planId.isEmpty)
      return const Text('No Plan',
          style: TextStyle(fontStyle: FontStyle.italic));

    try {
      final plan = plans.firstWhere(
        (plan) => plan.id == planId,
        orElse: () => MembershipPlanModel(
          id: planId,
          name: 'Plan $planId',
          description: '',
          price: 0,
          billingCycle: 'unknown',
          features: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userMembership: [],
        ),
      );

      final billingCycle = plan.billingCycle.isNotEmpty
          ? ' • ${plan.billingCycle.capitalize()}'
          : '';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            plan.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (billingCycle.isNotEmpty)
            Text(
              billingCycle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey[600],
              ),
            ),
        ],
      );
    } catch (e) {
      debugPrint('Error getting plan name for ID $planId: $e');
      return Text('Plan $planId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipState = ref.watch(membershipNotifierProvider);
    final membershipPlans = membershipState.plans;

    if (membershipState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (membershipState.error != null) {
      return Center(
        child: Text('Error loading plans: ${membershipState.error}'),
      );
    }

    // Print debug information
    if (kDebugMode) {
      for (final user in widget.users) {
        final memberships = ref.watch(
          userNotifierProvider
              .select((state) => state.userMemberships[user.id] ?? []),
        );
        debugPrint(
            'User ${user.fullName} (${user.id}): ${memberships.length} memberships');
        for (final m in memberships) {
          debugPrint(
              '  - ${m.id}: ${m.membershipPlanId} (${m.status}) ${m.startDate} to ${m.endDate}');
        }
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 56,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          columns: [
            const DataColumn(label: Text('')), // Checkbox column
            const DataColumn(label: Text('User')),
            const DataColumn(label: Text('Email')),
            const DataColumn(label: Text('Phone')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Plan')),
            const DataColumn(label: Text('Start Date')),
            const DataColumn(label: Text('End Date')),
            const DataColumn(label: Text('Actions')),
          ],
          rows: widget.users.map((user) {
            final userMemberships = ref.watch(
              userNotifierProvider.select(
                (state) => state.userMemberships[user.id] ?? [],
              ),
            );

            final isLoading = ref.watch(
              userNotifierProvider.select(
                (state) => state.loadingMembershipUserIds.contains(user.id),
              ),
            );

            // Sort memberships by status (active first) and then by end date (newest first)
            final sortedMemberships =
                List<UserMembershipModel>.from(userMemberships)
                  ..sort((a, b) {
                    if (a.status == 'active' && b.status != 'active') return -1;
                    if (a.status != 'active' && b.status == 'active') return 1;
                    return b.endDate.compareTo(a.endDate); // Newest first
                  });
            final relevantMembership =
                sortedMemberships.isNotEmpty ? sortedMemberships.first : null;

            final isSelected = widget.selectedUserIds.contains(user.id);

            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      widget.onUserSelected(user.id, value ?? false);
                    },
                  ),
                ),
                DataCell(Text(user.fullName)),
                DataCell(Text(user.email)),
                DataCell(Text(user.phone)),
                DataCell(
                  MembershipStatusChip(
                    memberships: userMemberships,
                    isLoading: isLoading,
                  ),
                ),
                DataCell(
                  relevantMembership != null
                      ? _getPlanName(
                          relevantMembership.membershipPlanId, membershipPlans)
                      : const Text('No membership',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                ),
                DataCell(
                  relevantMembership != null
                      ? Text(
                          relevantMembership.startDate.toString().split(' ')[0])
                      : const Text('-'),
                ),
                DataCell(
                  relevantMembership != null
                      ? Text(
                          relevantMembership.endDate.toString().split(' ')[0])
                      : const Text('-'),
                ),
                DataCell(
                  Row(
                    children: [
                      if (relevantMembership != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => _showDeleteConfirmation(
                              context, relevantMembership.id, user.id),
                          tooltip: 'Delete Membership',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => _showAddMembershipDialog(user),
                        tooltip: 'Add Membership',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
