import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/dashboard/domain/activity.dart'
    show Activity, ActivityType;
import 'package:osp_broker_admin/features/dashboard/domain/dashboard_overview.dart';
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
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Full overview from GET /admin/dashboard/stats (standard envelope:
      // response.data['data']). Parsing is defensive: missing keys -> 0/empty.
      final response =
          await _api.get('/admin/dashboard/stats', requireAuth: true);
      final raw = response.data;
      final data = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : <String, dynamic>{};

      final overview = DashboardOverview.fromJson(data);

      // Legacy flat stat list, kept for any consumer of state.stats.
      final stats = <DashboardStat>[
        DashboardStat(label: 'Total Users', value: '${overview.totalUsers}'),
        DashboardStat(
            label: 'Active Memberships',
            value: '${overview.activeMemberships}'),
        DashboardStat(
            label: 'Businesses', value: '${overview.totalBusinesses}'),
        DashboardStat(label: 'Auctions', value: '${overview.totalAuctions}'),
        DashboardStat(
            label: 'Pending Scrapes',
            value: '${overview.pendingScrapedBusinesses}'),
        DashboardStat(
            label: 'Banned Users', value: '${overview.bannedUsers}'),
        DashboardStat(label: 'RFPs', value: '${overview.totalRFPs}'),
        DashboardStat(
            label: 'Revenue', value: '\$${overview.totalRevenue}'),
      ];

      // Legacy activity feed (recent signups), kept for any consumer of
      // state.activities. The overview page builds its richer merged feed
      // directly from state.overview.
      final activities = overview.recentUsers.map<Activity>((u) {
        final name = u.fullName.isNotEmpty
            ? u.fullName
            : (u.email.isNotEmpty ? u.email : 'Unknown');
        return Activity(
          id: u.id,
          description: 'New user registered: $name',
          timestamp: u.createdAt ?? DateTime.now(),
          type: ActivityType.user,
          userId: u.id,
          userName: u.fullName.isNotEmpty ? u.fullName : null,
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        overview: overview,
        stats: stats,
        activities: activities,
      );
    } catch (e) {
      // Keep any previously loaded overview on refresh failure.
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data',
      );
    }
  }
}
