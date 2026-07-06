import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/dashboard/application/dashboard_notifier.dart';
import 'package:osp_broker_admin/features/dashboard/domain/dashboard_overview.dart';
import 'package:osp_broker_admin/features/dashboard/presentation/widgets/stat_card.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadDashboardData();
    });
  }

  Future<void> _refreshData() async {
    await ref.read(dashboardNotifierProvider.notifier).loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);
    final overview = state.overview;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Top Bar
          const TopBar(
            userName: 'Ryan',
            userRole: 'Admin',
            notificationCount: '5',
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(state.isLoading),
                    const SizedBox(height: 16),
                    if (overview == null && state.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 120),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (overview == null)
                      _buildLoadError(state.errorMessage)
                    else ...[
                      if (state.errorMessage != null) ...[
                        _buildRefreshFailedBanner(state.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _AttentionStrip(overview: overview),
                      const SizedBox(height: 24),
                      _buildKpiGrid(overview),
                      const SizedBox(height: 24),
                      _buildChartsRow(overview),
                      const SizedBox(height: 24),
                      _RecentActivityCard(overview: overview),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isLoading) {
    return Row(
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: isLoading ? null : _refreshData,
          icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildLoadError(String? message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: _cardDecoration,
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message ?? 'Failed to load dashboard data',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshFailedBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$message — showing last loaded data.',
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DashboardOverview ov) {
    final cards = <Widget>[
      StatCard(
        title: 'Total Users',
        value: _formatCount(ov.totalUsers),
        subtitle: '+${_formatCount(ov.newUsers7d)} this week',
        icon: Icons.people,
        onViewTap: () => context.go('/users'),
      ),
      StatCard(
        title: 'Active Memberships',
        value: _formatCount(ov.activeMemberships),
        icon: Icons.card_membership,
        onViewTap: () => context.go('/plans'),
      ),
      StatCard(
        title: 'Businesses',
        value: _formatCount(ov.totalBusinesses),
        icon: Icons.business,
        onViewTap: () => context.go('/business-directories'),
      ),
      StatCard(
        title: 'Auctions',
        value: _formatCount(ov.totalAuctions),
        subtitle: '${_formatCount(ov.activeAuctions)} active',
        icon: Icons.gavel,
        onViewTap: () => context.go('/auctions'),
      ),
      StatCard(
        title: 'Forum Topics',
        value: _formatCount(ov.totalTopics),
        subtitle: '${_formatCount(ov.totalComments)} comments',
        icon: Icons.forum,
        onViewTap: () => context.go('/forums'),
      ),
      StatCard(
        title: 'RFPs',
        value: _formatCount(ov.totalRFPs),
        icon: Icons.request_quote,
        onViewTap: () => context.go('/rfps'),
      ),
      StatCard(
        title: 'Orders',
        value: _formatCount(ov.totalOrders),
        subtitle: '${_formatCount(ov.totalShopItems)} shop items',
        icon: Icons.shopping_cart,
        onViewTap: () => context.go('/orders'),
      ),
      StatCard(
        title: 'Revenue',
        value: _formatMoney(ov.totalRevenue),
        subtitle: '${_formatMoney(ov.revenue30d)} last 30d',
        icon: Icons.attach_money,
        onViewTap: () => context.go('/orders'),
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 118,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      children: cards,
    );
  }

  Widget _buildChartsRow(DashboardOverview ov) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final signups = _SignupsChartCard(days: ov.signupsByDay);
        final memberships =
            _MembershipBreakdownCard(plans: ov.membershipBreakdown);
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: signups),
              const SizedBox(width: 16),
              Expanded(child: memberships),
            ],
          );
        }
        return Column(
          children: [
            signups,
            const SizedBox(height: 16),
            memberships,
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Needs attention strip
// ---------------------------------------------------------------------------

class _AttentionStrip extends StatelessWidget {
  final DashboardOverview overview;

  const _AttentionStrip({required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = <_AttentionItem>[
      if (overview.pendingAuctions > 0)
        _AttentionItem(
          label:
              '${overview.pendingAuctions} auction${overview.pendingAuctions == 1 ? '' : 's'} pending approval',
          icon: Icons.gavel,
          severe: false,
          route: '/auctions',
        ),
      if (overview.pendingReps > 0)
        _AttentionItem(
          label:
              '${overview.pendingReps} rep application${overview.pendingReps == 1 ? '' : 's'}',
          icon: Icons.badge,
          severe: false,
          route: '/business-directories',
        ),
      if (overview.pendingScrapedBusinesses > 0)
        _AttentionItem(
          label:
              '${overview.pendingScrapedBusinesses} scraped business${overview.pendingScrapedBusinesses == 1 ? '' : 'es'} pending',
          icon: Icons.travel_explore,
          severe: false,
          route: '/bd-scraper',
        ),
      if (overview.flaggedContent > 0)
        _AttentionItem(
          label: '${overview.flaggedContent} flagged content',
          icon: Icons.flag,
          severe: true,
        ),
      if (overview.bannedUsers > 0)
        _AttentionItem(
          label:
              '${overview.bannedUsers} banned user${overview.bannedUsers == 1 ? '' : 's'}',
          icon: Icons.block,
          severe: true,
          route: '/users',
        ),
    ];

    if (items.isEmpty) {
      return Wrap(
        children: const [
          _AttentionChip(
            label: 'All clear — nothing needs attention',
            icon: Icons.check_circle_outline,
            background: AppColors.successLight,
            foreground: AppColors.success,
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return _AttentionChip(
          label: item.label,
          icon: item.icon,
          background: item.severe
              ? AppColors.errorLight
              : const Color(0xFFFFF3E0), // soft amber
          foreground: item.severe ? AppColors.error : AppColors.warning,
          onTap: item.route == null ? null : () => context.go(item.route!),
        );
      }).toList(),
    );
  }
}

class _AttentionItem {
  final String label;
  final IconData icon;
  final bool severe;
  final String? route;

  const _AttentionItem({
    required this.label,
    required this.icon,
    required this.severe,
    this.route,
  });
}

class _AttentionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _AttentionChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 11, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Signups bar chart (no chart package — plain widgets)
// ---------------------------------------------------------------------------

class _SignupsChartCard extends StatelessWidget {
  final List<SignupDay> days;

  const _SignupsChartCard({required this.days});

  static const double _chartHeight = 160;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(0, (m, d) => d.count > m ? d.count : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signups — last 30 days',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (days.isEmpty || maxCount == 0)
            _buildEmpty()
          else
            _buildBars(maxCount),
          const SizedBox(height: 8),
          _buildAxisLabels(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: _chartHeight,
      child: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'No signups yet',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
            ),
          ),
          // Flat baseline
          Container(height: 2, color: const Color(0xFFE8E2D4)),
        ],
      ),
    );
  }

  Widget _buildBars(int maxCount) {
    return SizedBox(
      height: _chartHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final factor = d.count / maxCount;
                final barHeight =
                    d.count == 0 ? 3.0 : 6 + (_chartHeight - 26) * factor;
                return Expanded(
                  child: Tooltip(
                    message: '${d.date}: ${d.count}',
                    waitDuration: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: d.count == 0
                                ? const Color(0xFFE8E2D4)
                                : AppColors.accent,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(height: 2, color: const Color(0xFFE8E2D4)),
        ],
      ),
    );
  }

  Widget _buildAxisLabels() {
    if (days.isEmpty) return const SizedBox.shrink();
    const style = TextStyle(fontSize: 11, color: AppColors.textHint);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(days.first.date, style: style),
        if (days.length > 1) Text(days.last.date, style: style),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Membership breakdown (horizontal proportional bars)
// ---------------------------------------------------------------------------

class _MembershipBreakdownCard extends StatelessWidget {
  final List<MembershipPlanCount> plans;

  const _MembershipBreakdownCard({required this.plans});

  @override
  Widget build(BuildContext context) {
    final sorted = [...plans]..sort((a, b) => b.level.compareTo(a.level));
    final maxCount =
        sorted.fold<int>(0, (m, p) => p.count > m ? p.count : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Memberships by plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty || maxCount == 0)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No active memberships',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            )
          else
            ...sorted.map((p) => _buildRow(p, maxCount)),
        ],
      ),
    );
  }

  Widget _buildRow(MembershipPlanCount plan, int maxCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              plan.planName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECDF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                    (plan.count / maxCount).clamp(0.0, 1.0).toDouble(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '${plan.count}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent activity (merged users + auctions + businesses feed)
// ---------------------------------------------------------------------------

class _FeedItem {
  final String text;
  final IconData icon;
  final Color color;
  final DateTime? time;
  final bool pending;

  const _FeedItem({
    required this.text,
    required this.icon,
    required this.color,
    this.time,
    this.pending = false,
  });
}

class _RecentActivityCard extends StatelessWidget {
  final DashboardOverview overview;

  const _RecentActivityCard({required this.overview});

  List<_FeedItem> _buildFeed() {
    final items = <_FeedItem>[
      ...overview.recentUsers.map((u) {
        final name = u.fullName.isNotEmpty
            ? u.fullName
            : (u.email.isNotEmpty ? u.email : 'Unknown');
        return _FeedItem(
          text: 'New user: $name',
          icon: Icons.person_add,
          color: AppColors.info,
          time: u.createdAt,
        );
      }),
      ...overview.recentAuctions.map((a) => _FeedItem(
            text: 'Auction created: ${a.title}',
            icon: Icons.gavel,
            color: AppColors.warning,
            time: a.createdAt,
            pending: !a.approved,
          )),
      ...overview.recentBusinesses.map((b) => _FeedItem(
            text: 'Business registered: ${b.businessName}',
            icon: Icons.business,
            color: AppColors.success,
            time: b.createdAt,
          )),
    ];

    items.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });

    return items.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    final feed = _buildFeed();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (feed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900 && feed.length > 1) {
                  final mid = (feed.length + 1) ~/ 2;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildColumn(feed.sublist(0, mid))),
                      const SizedBox(width: 32),
                      Expanded(child: _buildColumn(feed.sublist(mid))),
                    ],
                  );
                }
                return _buildColumn(feed);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildColumn(List<_FeedItem> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Divider(height: 20, color: Color(0xFFEFEAE0)),
          _FeedRow(item: items[i]),
        ],
      ],
    );
  }
}

class _FeedRow extends StatelessWidget {
  final _FeedItem item;

  const _FeedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (item.pending) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Text(
          _relativeTime(item.time),
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

final BoxDecoration _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ],
);

String _formatCount(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return value < 0 ? '-$buf' : buf.toString();
}

String _formatMoney(num value) {
  final whole = value.truncate();
  final hasCents = value != whole;
  final base = _formatCount(whole);
  if (!hasCents) return '\$$base';
  final cents =
      ((value - whole).abs() * 100).round().toString().padLeft(2, '0');
  return '\$$base.$cents';
}

String _relativeTime(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.isNegative) return 'just now';
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
