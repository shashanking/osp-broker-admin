import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/dashboard/application/dashboard_notifier.dart';
import 'package:osp_broker_admin/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:osp_broker_admin/features/dashboard/presentation/widgets/time_range_selector.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  String _selectedRange = '7 days';

  @override
  void initState() {
    super.initState();
    // Load data when the page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadDashboardData();
    });
  }

  Future<void> _refreshData() async {
    await ref.read(dashboardNotifierProvider.notifier).loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    // Dashboard state is being watched by the provider but not directly used in this widget
    // as it's currently using static data. Uncomment when dynamic data is needed.
    // final state = ref.watch(dashboardNotifierProvider);

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
                    // Header with Title and Time Range Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TimeRangeSelector(
                          selectedRange: _selectedRange,
                          onRangeSelected: (range) {
                            setState(() {
                              _selectedRange = range;
                            });
                            // TODO: Handle time range change
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        StatCard(
                          title: 'Pending Auctions',
                          value: '4',
                          change: '+2.5%',
                          isPositive: true,
                          icon: Icons.gavel,
                        ),
                        StatCard(
                          title: 'New Business Pages',
                          value: '3',
                          change: '-1.5%',
                          isPositive: false,
                          icon: Icons.business,
                        ),
                        StatCard(
                          title: 'Active Forum Threads',
                          value: '18',
                          change: '-1.3%',
                          isPositive: false,
                          icon: Icons.forum,
                        ),
                        StatCard(
                          title: 'Total Users',
                          value: '11,240',
                          change: '+4.3%',
                          isPositive: true,
                          icon: Icons.people,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Additional sections can be added here
                    // For example: Recent Activities, Charts, etc.

                    // Placeholder for additional content
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Additional content goes here',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
