import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/utils/role_utils.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';

class _AdminSearchItem {
  final String title;
  final String route;
  final List<String> keywords;

  const _AdminSearchItem({
    required this.title,
    required this.route,
    required this.keywords,
  });
}

class _AdminSearchDelegate extends SearchDelegate<_AdminSearchItem?> {
  final List<_AdminSearchItem> _items;

  _AdminSearchDelegate(this._items)
      : super(
          searchFieldLabel: 'Search for Forums, auctions & more...',
          keyboardType: TextInputType.text,
        );

  List<_AdminSearchItem> _filter(String q) {
    final queryLower = q.trim().toLowerCase();
    if (queryLower.isEmpty) return _items;

    return _items.where((item) {
      if (item.title.toLowerCase().contains(queryLower)) return true;
      return item.keywords.any((k) => k.contains(queryLower));
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filter(query);
    return _buildList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _filter(query);
    return _buildList(context, results);
  }

  Widget _buildList(BuildContext context, List<_AdminSearchItem> results) {
    if (results.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text(item.title),
          subtitle: Text(item.route),
          trailing: const Icon(Icons.north_east),
          onTap: () {
            close(context, item);
            context.go(item.route);
          },
        );
      },
    );
  }
}

class TopBar extends ConsumerWidget {
  final String userName;
  final String userRole;
  final String greeting;
  final String? notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCreateAuctionTap;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const TopBar({
    super.key,
    required this.userName,
    required this.userRole,
    this.greeting = 'Good Morning',
    this.notificationCount,
    this.onNotificationTap,
    this.onProfileTap,
    this.onCreateAuctionTap,
    this.showBackButton = false,
    this.onBackPressed,
  });

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    String displayName = userName;
    String displayRole = userRole;

    authState.whenOrNull(
      authenticated: (token, user) {
        final name = user['name']?.toString() ?? user['fullName']?.toString();
        final email = user['email']?.toString();
        displayName = (name != null && name.trim().isNotEmpty)
            ? name
            : (email != null && email.trim().isNotEmpty)
                ? email
                : userName;
        displayRole = formatUserRoles(
          Map<String, dynamic>.from(user),
          fallback: userRole,
        );
      },
    );

    final resolvedGreeting =
        greeting.trim() == 'Good Morning' ? _timeBasedGreeting() : greeting;

    final searchItems = <_AdminSearchItem>[
      const _AdminSearchItem(
        title: 'Dashboard',
        route: '/dashboard',
        keywords: ['home', 'overview', 'stats', 'dashboard'],
      ),
      const _AdminSearchItem(
        title: 'Forums',
        route: '/forums',
        keywords: ['forum', 'topics', 'categories', 'posts'],
      ),
      const _AdminSearchItem(
        title: 'Auctions',
        route: '/auctions',
        keywords: ['auction', 'bids', 'items', 'lots'],
      ),
      const _AdminSearchItem(
        title: 'Messages',
        route: '/chat',
        keywords: ['chat', 'messages', 'dm'],
      ),
      const _AdminSearchItem(
        title: 'All Chats',
        route: '/all-chats',
        keywords: ['chat', 'messages', 'admin chat'],
      ),
      const _AdminSearchItem(
        title: 'Business Directories',
        route: '/business-directories',
        keywords: ['business', 'directory', 'directories', 'companies'],
      ),
      const _AdminSearchItem(
        title: 'Shop',
        route: '/shop',
        keywords: ['pins', 'badges', 'kudo', 'coins', 'shop'],
      ),
      const _AdminSearchItem(
        title: 'Users',
        route: '/users',
        keywords: ['user', 'members', 'moderator', 'representative', 'admin'],
      ),
      const _AdminSearchItem(
        title: 'Membership Plans',
        route: '/plans',
        keywords: ['membership', 'plans', 'subscriptions'],
      ),
      const _AdminSearchItem(
        title: 'Settings',
        route: '/settings',
        keywords: ['settings', 'preferences', 'config'],
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppColors.primary, width: 1)),
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.warning,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBackPressed,
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Greeting and User Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$resolvedGreeting, $displayName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here is your daily preview',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                readOnly: true,
                onTap: () {
                  showSearch<_AdminSearchItem?>(
                    context: context,
                    delegate: _AdminSearchDelegate(searchItems),
                  );
                },
                decoration: const InputDecoration(
                  hintText: 'Search for Forums, auctions & More....',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  suffixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Notification Icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  size: 28,
                  color: AppColors.textPrimary,
                ),
                onPressed: onNotificationTap,
              ),
              if (notificationCount != null && notificationCount!.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationCount!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Create Auction Button
          // ElevatedButton(
          //   onPressed: onCreateAuctionTap,
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: AppColors.primary,
          //     foregroundColor: Colors.white,
          //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(32),
          //     ),
          //     elevation: 0,
          //   ),
          //   child: const Text(
          //     'Create Auction',
          //     style: TextStyle(
          //       fontSize: 16,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),

          const SizedBox(width: 16),

          // Profile Section
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/profile.png'),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // User Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                displayRole,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
