import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import '../widgets/forum_tabs.dart';
import '../widgets/forum_categories_table.dart';
import '../widgets/forum_forums_table.dart';
import '../widgets/forum_threads_table.dart';
import '../../application/forum_admin_notifier.dart';
import '../widgets/forum_topics_table.dart';

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
      await ref.read(forumAdminNotifierProvider.notifier).loadForums();
      ref.read(forumAdminNotifierProvider.notifier).loadCategories();
      // Fetch topics for the first forum if available
      final forums = ref.read(forumAdminNotifierProvider).forums;
      if (forums.isNotEmpty) {
        ref
            .read(forumAdminNotifierProvider.notifier)
            .loadTopics(forumId: forums.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final categories = forumState.categories;
    final isLoadingCategories = forumState.isLoading && _selectedTab == 0;
    final errorCategories = forumState.error;

    // Load categories on first build

    final forums = forumState.forums;
    final isLoading = forumState.isLoading;
    final error = forumState.error;

    // Load forums on first build
    // Call in initState instead of here

    final threads = [
      {
        'selected': false,
        'title': 'VCs or Bootstrapping in 2025?',
        'author': '@yachtexpert',
        'likes': 56,
        'comments': 32,
        'date': '23-04-25',
        'category': 'Startups & Pitches',
        'status': 'Public',
        'isPrivate': false,
      },
      {
        'selected': false,
        'title': 'API rate limiting issue',
        'author': '@devmike',
        'likes': 43,
        'comments': 12,
        'date': '23-04-25',
        'category': 'Developer Talk',
        'status': 'Private',
        'isPrivate': true,
      },
      {
        'selected': false,
        'title': 'Hidden investor list leak?',
        'author': '@anon77',
        'likes': 21,
        'comments': 10,
        'date': '22-04-25',
        'category': 'Private Roundtable',
        'status': 'Public',
        'isPrivate': false,
      },
      {
        'selected': false,
        'title': 'Feature request: dark mode',
        'author': '@designx',
        'likes': 32,
        'comments': 14,
        'date': '22-04-25',
        'category': 'Product Feedback',
        'status': 'Private',
        'isPrivate': true,
      },
    ];

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
                  _buildStatsCards(),
                  const SizedBox(height: 32),

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
                              threads.length.toString(),
                              forumState.topics.length.toString(),
                            ],
                          ),
                          // (You can add search/sort/filter bar here if needed)
                        ],
                      ),
                      const SizedBox(height: 24),
                      _selectedTab == 0
                          ? ForumCategoriesTable(categories: categories)
                          : _selectedTab == 1
                              ? isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : error != null
                                      ? Center(child: Text('Error: ' + error))
                                      : ForumForumsTable(forums: forums)
                              : _selectedTab == 2
                                  ? isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : error != null
                                          ? Center(
                                              child: Text('Error: ' + error))
                                          : ForumTopicsTable(topics: forumState.topics, forums: forums)
                                  : isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : error != null
                                          ? Center(
                                              child: Text('Error: ' + error))
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _buildActionCard(
          assetName: 'add-category.png',
          title: 'Add Category',
          onTap: () {},
          iconColor: Colors.white,
          titleColor: Colors.white,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF24439B), Color(0xFF15A5CD)],
          ),
        ),
        _buildActionCard(
          assetName: 'add-announcement.png',
          title: 'Create Announcement',
          onTap: () {},
          iconColor: const Color(0xFF24439B),
          titleColor: Colors.black,
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFE6EDFF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.9988],
          ),
        ),
        _buildActionCard(
          assetName: 'add-event.png',
          title: 'Create an Event',
          onTap: () {},
          iconColor: const Color(0xFFD49823),
          titleColor: Colors.black,
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFEF3DE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.9988],
          ),
        ),
        _buildActionCard(
          assetName: 'add-poll.png',
          title: 'Create a Poll',
          onTap: () {},
          iconColor: const Color(0xFF25B4DC),
          titleColor: Colors.black,
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFD9F1F8), Color(0xFFFFFFFF)],
            stops: [0.0, 0.9988],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String assetName,
    required String title,
    required Color titleColor,
    required VoidCallback onTap,
    required Color iconColor,
    Gradient? gradient,
    Color? bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        color: gradient == null ? bgColor : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/forum/$assetName',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      overflow: TextOverflow.visible,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                'assets/icons/forum/' + iconAsset,
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
