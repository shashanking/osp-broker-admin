import 'package:flutter/material.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/features/dashboard/domain/activity.dart';

class RecentActivities extends StatelessWidget {
  final List<Activity> activities;

  const RecentActivities({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No recent activities',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppColors.divider,
                  height: 32,
                ),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _ActivityItem(activity: activity);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Activity activity;

  const _ActivityItem({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getIconColor(activity.type),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIcon(activity.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimeAgo(activity.timestamp),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.user:
        return Icons.person_add;
      case ActivityType.payment:
        return Icons.payment;
      case ActivityType.system:
        return Icons.settings;
      case ActivityType.other:
        return Icons.notifications;
    }
  }

  Color _getIconColor(ActivityType type) {
    switch (type) {
      case ActivityType.user:
        return Colors.blue;
      case ActivityType.payment:
        return Colors.green;
      case ActivityType.system:
        return Colors.orange;
      case ActivityType.other:
        return Colors.purple;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
