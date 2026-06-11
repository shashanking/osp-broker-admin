import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/dashboard/domain/activity.dart'
    show Activity, ActivityType;
import 'package:osp_broker_admin/features/dashboard/domain/dashboard_stats.dart'
    show DashboardStat;
import 'package:osp_broker_admin/features/dashboard/domain/dashboard_state.dart';

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(ref.watch(baseApiServiceProvider)),
);

class DashboardNotifier extends StateNotifier<DashboardState> {
  final BaseApiService _api;

  DashboardNotifier(this._api) : super(const DashboardState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Real metrics from GET /admin/dashboard/stats (was hardcoded mock data).
      final response = await _api.get('/admin/dashboard/stats', requireAuth: true);
      final data = response.data['data'] as Map<String, dynamic>;
      final s = (data['stats'] as Map<String, dynamic>? ?? {});

      String n(dynamic v) => (v ?? 0).toString();

      final stats = <DashboardStat>[
        DashboardStat(label: 'Total Users', value: n(s['totalUsers'])),
        DashboardStat(label: 'Active Memberships', value: n(s['activeMemberships'])),
        DashboardStat(label: 'Businesses', value: n(s['totalBusinesses'])),
        DashboardStat(label: 'Auctions', value: n(s['totalAuctions'])),
        DashboardStat(label: 'Pending Scrapes', value: n(s['pendingScrapedBusinesses'])),
        DashboardStat(label: 'Banned Users', value: n(s['bannedUsers'])),
        DashboardStat(label: 'RFPs', value: n(s['totalRFPs'])),
        DashboardStat(
          label: 'Revenue',
          value: '\$${n(s['totalRevenue'])}',
        ),
      ];

      // Recent activity from real recent signups.
      final recentUsers = (data['recentUsers'] as List?) ?? const [];
      final activities = recentUsers.map<Activity>((u) {
        final m = u as Map<String, dynamic>;
        return Activity(
          id: m['id']?.toString() ?? '',
          description: 'New user registered: ${m['fullName'] ?? m['email'] ?? 'Unknown'}',
          timestamp: m['createdAt'] != null
              ? (DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now())
              : DateTime.now(),
          type: ActivityType.user,
          userId: m['id']?.toString(),
          userName: m['fullName']?.toString(),
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        activities: activities,
      );
    } catch (e) {
      // Surface an empty-but-not-crashing dashboard on failure.
      state = state.copyWith(isLoading: false);
    }
  }
}
