import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/utils/csv_export.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/forums/presentation/widgets/hover_action_cards.dart';

import '../../application/forum_admin_notifier.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/add_forum_dialog.dart';
import '../widgets/announcements_dialog.dart';
import '../widgets/events_dialog.dart';
import '../widgets/forum_categories_table.dart';
import '../widgets/forum_forums_table.dart';
import '../widgets/forum_tabs.dart';
import '../widgets/forum_topics_table.dart';
import '../widgets/polls_dialog.dart';

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
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 768 ? 12.0 : 24.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    'Forum Listing and Management',
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width < 768 ? 20 : 24,
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
                          const Spacer(),
                          PopupMenuButton<String>(
                            tooltip: 'Export CSV',
                            icon: const Icon(Icons.download),
                            onSelected: (value) async {
                              final state =
                                  ref.read(forumAdminNotifierProvider);
                              if (value == 'categories') {
                                final rows = state.categories
                                    .map(
                                      (c) => <String, Object?>{
                                        'id': c.id,
                                        'name': c.name,
                                        'description': c.description,
                                        'moderatorId': c.moderatorId,
                                        'icon': c.icon,
                                        'membershipAccess': c.membershipAccess,
                                        'createdAt': c.createdAt,
                                        'updatedAt': c.updatedAt,
                                        'isActive': c.isActive,
                                        'count': c.count,
                                      },
                                    )
                                    .toList();
                                await exportCsv(
                                  fileName: 'forum_categories.csv',
                                  rows: rows,
                                );
                                return;
                              }

                              if (value == 'forums') {
                                final rows = state.forums
                                    .map(
                                      (f) => <String, Object?>{
                                        'id': f.id,
                                        'title': f.title,
                                        'description': f.description,
                                        'categoryId': f.categoryId,
                                        'userId': f.userId,
                                        'author': f.author,
                                        'comments': f.comments,
                                        'isDeleted': f.isDeleted,
                                        'createdAt': f.createdAt,
                                        'updatedAt': f.updatedAt,
                                        'topics': f.topics,
                                        'count': f.count,
                                      },
                                    )
                                    .toList();
                                await exportCsv(
                                  fileName: 'forums.csv',
                                  rows: rows,
                                );
                                return;
                              }

                              if (value == 'topics') {
                                final rows = state.topics
                                    .map(
                                      (t) => <String, Object?>{
                                        'id': t.id,
                                        'title': t.title,
                                        'content': t.content,
                                        'author': t.author,
                                        'views': t.views,
                                        'forumId': t.forumId,
                                        'createdAt': t.createdAt,
                                        'updatedAt': t.updatedAt,
                                        'comments': t.comments,
                                        'isClosed': t.isClosed,
                                        'attachments': t.attachments,
                                      },
                                    )
                                    .toList();
                                await exportCsv(
                                  fileName: 'forum_topics.csv',
                                  rows: rows,
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'categories',
                                child: Text('Export Categories (CSV)'),
                              ),
                              PopupMenuItem(
                                value: 'forums',
                                child: Text('Export Forums (CSV)'),
                              ),
                              PopupMenuItem(
                                value: 'topics',
                                child: Text('Export Topics (CSV)'),
                              ),
                            ],
                          ),
                          // (You can add search/sort/filter bar here if needed)
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildResponsiveTable(
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
                                            ? Center(
                                                child: Text('Error: $error'))
                                            : ForumTopicsTable(
                                                topics: forumState.topics,
                                                forums: forums)
                                    : isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : error != null
                                            ? Center(
                                                child: Text('Error: $error'))
                                            : Container(),
                      )
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

  Widget _buildResponsiveTable(Widget table) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      // Wrap table in horizontal scroll for mobile with proper constraints
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width:
              screenWidth * 1.5, // Give table 1.5x screen width for scrolling
          child: table,
        ),
      );
    }

    return table;
  }

  Widget _buildActionCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // Determine grid layout based on screen size
    int crossAxisCount;
    double childAspectRatio;

    if (isMobile) {
      crossAxisCount = 2; // 2 columns on mobile
      childAspectRatio = 1.5;
    } else if (isTablet) {
      crossAxisCount = 3; // 3 columns on tablet
      childAspectRatio = 2.0;
    } else {
      crossAxisCount = 4; // 4 columns on desktop
      childAspectRatio = 2.8;
    }

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
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
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
}
