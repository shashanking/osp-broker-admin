import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';

class DashboardNavigationRail extends StatelessWidget {
  const DashboardNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    bool isSelected(String route) => currentRoute == route;

    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authNotifierProvider);
        final isLoggingOut = authState.maybeMap(
          loading: (_) => true,
          orElse: () => false,
        );

        return _buildNavigationRail(context, currentRoute, isSelected, isLoggingOut);
      },
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    String currentRoute,
    bool Function(String) isSelected,
    bool isLoggingOut,
  ) {
    return Container(
      width: 240,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // Logo
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Image.asset(
              'assets/images/osp-logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const FlutterLogo(size: 120);
              },
            ),
          ),
          
          // Divider
          const Divider(color: AppColors.divider, height: 1, thickness: 1),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  label: 'Overview',
                  isSelected: isSelected('/dashboard'),
                  route: '/dashboard',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.forum_outlined,
                  label: 'Forums',
                  isSelected: isSelected('/forums'),
                  route: '/forums',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.gavel_outlined,
                  label: 'Auctions',
                  isSelected: isSelected('/auctions'),
                  route: '/auctions',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.business_outlined,
                  label: 'Business Directories',
                  isSelected: isSelected('/directories'),
                  route: '/directories',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Shop',
                  isSelected: isSelected('/shop'),
                  route: '/shop',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.people_outline,
                  label: 'Users',
                  isSelected: isSelected('/users'),
                  route: '/users',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.card_membership_outlined,
                  label: 'Membership Plans',
                  isSelected: isSelected('/membership'),
                  route: '/membership',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.games_outlined,
                  label: 'Games',
                  isSelected: isSelected('/games'),
                  route: '/games',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Reports & Analytics',
                  isSelected: isSelected('/reports'),
                  route: '/reports',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isSelected: isSelected('/settings'),
                  route: '/settings',
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    return _buildMenuItem(
                      context: context,
                      icon: isLoggingOut ? null : Icons.logout,
                      label: isLoggingOut ? 'Logging out...' : 'Logout',
                      isSelected: false,
                      isLoading: isLoggingOut,
                      onTap: isLoggingOut
                          ? null
                          : () async {
                              final container = ProviderScope.containerOf(context);
                              await container.read(authNotifierProvider.notifier).logout();
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData? icon,
    required String label,
    required bool isSelected,
    bool isLoading = false,
    String? route,
    VoidCallback? onTap,
  }) {
    // Create a handler that uses onTap if provided, otherwise uses the route
    void handleTap() {
      if (onTap != null) {
        onTap();
      } else if (route != null) {
        context.go(route);
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor,
              ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: handleTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        minLeadingWidth: 24,
        horizontalTitleGap: 8,
      ),
    );
  }
}
