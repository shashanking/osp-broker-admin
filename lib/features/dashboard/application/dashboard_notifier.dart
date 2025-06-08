import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/dashboard/domain/activity.dart' show Activity, ActivityType;
import 'package:osp_broker_admin/features/dashboard/domain/dashboard_stats.dart' show DashboardStat;
import 'package:osp_broker_admin/features/dashboard/domain/dashboard_state.dart';

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState()) {
    // Load initial data
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API calls
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock stats data
      final stats = [
        DashboardStat(
          label: 'Total Users',
          value: '1,234',
          change: '+12%',
          isPositive: true,
        ),
        DashboardStat(
          label: 'Active Now',
          value: '256',
          change: '+5%',
          isPositive: true,
        ),
        DashboardStat(
          label: 'Revenue',
          value: '\$12,345',
          change: '+8.5%',
          isPositive: true,
        ),
        DashboardStat(
          label: 'New Orders',
          value: '56',
          change: '-2%',
          isPositive: false,
        ),
      ];

      // Mock activities data
      final now = DateTime.now();
      final activities = [
        Activity(
          id: '1',
          description: 'New user registered: John Doe',
          timestamp: now.subtract(const Duration(minutes: 5)),
          type: ActivityType.user,
          userId: 'user123',
          userName: 'John Doe',
        ),
        Activity(
          id: '2',
          description: 'Payment received: \$120.00',
          timestamp: now.subtract(const Duration(hours: 2)),
          type: ActivityType.payment,
        ),
        Activity(
          id: '3',
          description: 'System maintenance completed',
          timestamp: now.subtract(const Duration(hours: 5)),
          type: ActivityType.system,
        ),
        Activity(
          id: '4',
          description: 'New order #1234 placed',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ];

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        activities: activities,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}
