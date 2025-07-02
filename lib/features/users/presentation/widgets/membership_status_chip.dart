import 'package:flutter/material.dart';
import 'package:osp_broker_admin/features/users/data/models/user_membership_model.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class MembershipStatusChip extends StatelessWidget {
  final List<UserMembershipModel> memberships;
  final bool isLoading;

  const MembershipStatusChip({
    super.key,
    required this.memberships,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (memberships.isEmpty) {
      return _buildChip('No Membership', Colors.grey);
    }

    // Sort memberships by end date (newest first) to find the most relevant one
    final now = DateTime.now();
    final sortedMemberships = List<UserMembershipModel>.from(memberships)
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
    
    // Find the most recent active membership that's not expired
    final activeMembership = sortedMemberships.firstWhere(
      (m) => m.status == 'active' && m.endDate.isAfter(now),
      orElse: () => sortedMemberships.isNotEmpty ? sortedMemberships.first : UserMembershipModel(
        id: '',
        userId: '',
        membershipPlanId: '',
        startDate: now,
        endDate: now,
        status: 'inactive',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final endDate = activeMembership.endDate;
    final isActive = activeMembership.status == 'active' && endDate.isAfter(now);
    final isExpired = endDate.isBefore(now);
    final daysRemaining = endDate.difference(now).inDays;
    final daysSinceExpired = now.difference(endDate).inDays;

    if (isActive) {
      return _buildChip(
        'Active (${daysRemaining}d left)', 
        Colors.green,
        tooltip: 'Expires on ${endDate.toString().split(' ')[0]}',
      );
    } else if (isExpired) {
      return _buildChip(
        'Expired ($daysSinceExpired${daysSinceExpired == 1 ? ' day' : ' days'} ago)', 
        Colors.red,
        tooltip: 'Expired on ${endDate.toString().split(' ')[0]}',
      );
    } else {
      return _buildChip(
        activeMembership.status.capitalize(),
        Colors.orange,
        tooltip: 'Status: ${activeMembership.status.capitalize()}',
      );
    }
  }

  Widget _buildChip(String label, Color color, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
