import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/forums/presentation/widgets/hover_action_cards.dart';
import '../widgets/forum_tabs.dart';
import '../widgets/forum_categories_table.dart';
import '../widgets/forum_forums_table.dart';
import '../../application/forum_admin_notifier.dart';
import '../widgets/forum_topics_table.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_forum_dialog.dart';
import '../widgets/announcements_dialog.dart';
import '../widgets/polls_dialog.dart';
import '../widgets/events_dialog.dart';

class ForumsPage extends ConsumerStatefulWidget {
  const ForumsPage({super.key});

  @override
  ConsumerState<ForumsPage> createState() => _ForumsPageState();
}

class _ForumsPageState extends ConsumerState<ForumsPage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(forumAdminNotifierProvider.notifier);

      // Load all required data in parallel
      await Future.wait([
        notifier.loadForums(),
        notifier.loadCategories(),
        notifier.loadModerators(),
        notifier.loadMembershipPlans(),
      ]);

      // Fetch topics for the first forum if available
      final forums = ref.read(forumAdminNotifierProvider).forums;
      if (forums.isNotEmpty) {
        await notifier.loadTopics(forumId: forums.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final categories = forumState.categories;

    final forums = forumState.forums;
    final isLoading = forumState.isLoading;
    final error = forumState.error;

    // Load forums on first build
    // Call in initState instead of here

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Bar with user info
        const TopBar(
          userName: 'Admin',
          userRole: 'Administrator',
        ),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  const Text(
                    'Forum Listing and Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Cards
                  _buildActionCards(),
                  const SizedBox(height: 24),

                  // Stats Cards
                  // _buildStatsCards(),
                  // const SizedBox(height: 32),

                  // Tabs and Search Bar
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ForumTabs(
                            selectedTab: _selectedTab,
                            onTabSelected: (idx) =>
                                setState(() => _selectedTab = idx),
                            badges: [
                              '', // No badge for categories
                              forums.length.toString(),
                              forumState.topics.length.toString(),
                            ],
                          ),
                          // (You can add search/sort/filter bar here if needed)
                        ],
                      ),
                      const SizedBox(height: 24),
                      _selectedTab == 0
                          ? ForumCategoriesTable(
                              categories: categories,
                              membershipPlans: forumState.membershipPlans)
                          : _selectedTab == 1
                              ? isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : error != null
                                      ? Center(child: Text('Error: $error'))
                                      : ForumForumsTable(
                                          forums: forums,
                                          categories: categories)
                              : _selectedTab == 2
                                  ? isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : error != null
                                          ? Center(child: Text('Error: $error'))
                                          : ForumTopicsTable(
                                              topics: forumState.topics,
                                              forums: forums)
                                  : isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : error != null
                                          ? Center(child: Text('Error: $error'))
                                          : Container()
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    // Define gradients for each card
    final gradients = [
      {
        'light': const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFEF3DE), Color(0xFFFFFFFF)],
          stops: [0.0, 0.9988],
        ),
        'dark': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24439B), Color(0xFF15A5CD)],
        ),
      },
      {
        'light': const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF0F1FF), Color(0xFFFFFFFF)],
          stops: [0.0, 0.9988],
        ),
        'dark': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24439B), Color(0xFF15A5CD)],
        ),
      },
      {
        'light': const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFD9F1F8), Color(0xFFFFFFFF)],
          stops: [0.0, 0.9988],
        ),
        'dark': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25B4DC), Color(0xFF1876B9)],
        ),
      },
      {
        'light': const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF6EFFF), Color(0xFFFFFFFF)],
          stops: [0.0, 0.9988],
        ),
        'dark': const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8F5FE8), Color(0xFF6C3AE6)],
        ),
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.8,
      children: [
        HoverActionCard(
          assetName: 'add-category.png',
          title: 'Add Category',
          onTap: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (ctx) => const AddCategoryDialog(),
            );
            if (result == true) {
              await ref
                  .read(forumAdminNotifierProvider.notifier)
                  .loadCategories();
            }
          },
          iconColor: Colors.blue,
          titleColor: Colors.black,
          lightGradient: gradients[0]['light'] as Gradient,
          darkGradient: gradients[0]['dark'] as Gradient,
        ),
        HoverActionCard(
          assetName: 'add-poll.png',
          title: 'Create Forum',
          onTap: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (ctx) => const AddForumDialog(),
            );
            if (result == true) {
              await ref.read(forumAdminNotifierProvider.notifier).loadForums();
            }
          },
          iconColor: const Color(0xFF25B4DC),
          titleColor: Colors.black,
          lightGradient: gradients[2]['light'] as Gradient,
          darkGradient: gradients[2]['dark'] as Gradient,
        ),
        HoverActionCard(
          assetName: 'add-poll.png',
          title: 'Announcements',
          onTap: () async {
            final notifier = ref.read(forumAdminNotifierProvider.notifier);
            await notifier.fetchAllAnnouncements();
            if (mounted) {
              await showDialog(
                context: context,
                builder: (ctx) => const AnnouncementsListDialog(),
              );
            }
          },
          iconColor: Colors.orange,
          titleColor: Colors.black,
          lightGradient: gradients[1]['light'] as Gradient,
          darkGradient: gradients[1]['dark'] as Gradient,
        ),
        HoverActionCard(
          assetName: 'add-poll.png',
          title: 'Polls',
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => const PollsListDialog(),
            );
          },
          iconColor: const Color(0xFF25B4DC),
          titleColor: Colors.black,
          lightGradient: gradients[3]['light'] as Gradient,
          darkGradient: gradients[3]['dark'] as Gradient,
        ),
        HoverActionCard(
          assetName: 'add-poll.png',
          title: 'Events',
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => const EventsListDialog(),
            );
          },
          iconColor: Colors.purple,
          titleColor: Colors.black,
          lightGradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.purple.shade100, Colors.white],
            stops: const [0.0, 0.9988],
          ),
          darkGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple, Colors.purple.shade800],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'Announcements',
        'count': '18',
        'change': '-1.3%',
        'icon': 'announcements.png',
        'changePositive': false,
      },
      {
        'title': 'Active Events',
        'count': '26',
        'change': '+3.7%',
        'icon': 'events.png',
        'changePositive': true,
      },
      {
        'title': 'Active polls',
        'count': '26',
        'change': '+3.7%',
        'icon': 'events.png',
        'changePositive': true,
      },
      {
        'title': 'Approval pending',
        'count': '32',
        'change': '-4.3%',
        'icon': 'approvals.png',
        'changePositive': false,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.8,
      children: stats
          .map((stat) => _buildStatCard(
                title: stat['title'] as String,
                count: stat['count'] as String,
                change: stat['change'] as String,
                iconAsset: stat['icon'] as String,
                isChangePositive: stat['changePositive'] as bool,
              ))
          .toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required String change,
    required String iconAsset,
    required bool isChangePositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF24439B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/forum/$iconAsset',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title, value, view button
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Change indicator
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isChangePositive
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: isChangePositive ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  Text(
                    change,
                    style: TextStyle(
                      color: isChangePositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
