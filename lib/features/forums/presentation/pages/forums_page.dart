import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';

class ForumsPage extends ConsumerStatefulWidget {
  const ForumsPage({super.key});

  @override
  ConsumerState<ForumsPage> createState() => _ForumsPageState();
}

class _ForumsPageState extends ConsumerState<ForumsPage> {
  @override
  Widget build(BuildContext context) {
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
                  _buildTabBarAndSearch(),
                  const SizedBox(height: 24),

                  // Forum Categories Table
                  _buildCategoriesTable(),
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

  Widget _buildTabBarAndSearch() {
    // Custom pill tab bar and search row matching Figma
    final selectedTab = 1; // 0 = Forum Category, 1 = Threads List
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              _buildPillTab('Forum Category', selectedTab == 0, onTap: () {}),
              const SizedBox(width: 8),
              _buildPillTab(
                'Threads List',
                selectedTab == 1,
                badge: '24,352',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Search
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: selectedTab == 0
                    ? 'Search for Categories...'
                    : 'Search for Threads...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Sort and Filter
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.sort, size: 20),
          label: const Text('Sort'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 20, color: Colors.red),
          label: const Text('Filter', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillTab(String label, bool selected,
      {String? badge, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF24439B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF24439B) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: selected ? const Color(0xFF24439B) : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTable() {
    // Sample data for threads list (matching Figma columns)
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 32, child: Checkbox(value: false, onChanged: null)),
                Expanded(flex: 3, child: _TableHeader('Title', sortable: true, alignLeft: true)),
                Expanded(flex: 2, child: _TableHeader('Author', sortable: true, alignLeft: true)),
                Expanded(flex: 1, child: _TableHeader('Likes', sortable: true, alignLeft: true)),
                Expanded(flex: 2, child: _TableHeader('Comments', sortable: true, alignLeft: true)),
                Expanded(flex: 1, child: _TableHeader('Date', sortable: true, alignLeft: true)),
                Expanded(flex: 2, child: _TableHeader('Category', sortable: true, alignLeft: true)),
                Expanded(flex: 1, child: _TableHeader('Status', sortable: true, alignLeft: true)),
                Expanded(flex: 2, child: _TableHeader('Actions', sortable: true, alignLeft: true)),
              ],
            ),
          ),
          const Divider(height: 0),
          // Table rows
          ...threads.map((thread) => _buildThreadRow(thread)).toList(),
        ],
      ),
    );
  }
}

// Private header widget inside _ForumsPageState
class _TableHeader extends StatelessWidget {
  final String label;
  final bool sortable;
  final bool alignLeft;
  const _TableHeader(this.label, {this.sortable = false, this.alignLeft = false, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
          textAlign: TextAlign.left,
        ),
        if (sortable)
          const Icon(Icons.unfold_more, size: 18, color: Colors.black26),
      ],
    );
  }
}

Widget _buildThreadRow(Map<String, dynamic> thread) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 32,
          child: Checkbox(
            value: thread['selected'] as bool,
            onChanged: (v) {},
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            thread['title'] as String,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            thread['author'] as String,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            thread['likes'].toString(),
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            thread['comments'].toString(),
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            thread['date'] as String,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (thread['isPrivate'] as bool) ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              thread['category'] as String,
              style: TextStyle(
                color: (thread['isPrivate'] as bool) ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (thread['isPrivate'] as bool) ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              thread['status'] as String,
              style: TextStyle(
                color: (thread['isPrivate'] as bool) ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF232323),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Manage'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final categories = [
  {
    'name': 'Startups & Pitches',
    'threads': '3,495',
    'status': 'Public',
    'isPrivate': false,
  },
  {
    'name': 'Private Roundtable',
    'threads': '2,535',
    'status': 'Private',
    'isPrivate': true,
  },
  {
    'name': 'Developer Talk',
    'threads': '1,892',
    'status': 'Public',
    'isPrivate': false,
  },
  {
    'name': 'Product Feedback',
    'threads': '1,745',
    'status': 'Public',
    'isPrivate': false,
  },
];
