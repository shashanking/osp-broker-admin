import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class DashboardLayout extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Future<void> Function() onLogout;

  const DashboardLayout({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
    required this.onLogout,
    this.actions,
  });

  String _getPageTitle(String route) {
    final routeTitles = {
      '/dashboard': 'Dashboard',
      '/forums': 'Forums',
      '/auctions': 'Auctions',
      '/directories': 'Business Directories',
      '/shop': 'Shop',
      '/users': 'Users',
      '/plans': 'Membership Plans',
      '/games': 'Games',
      '/reports': 'Reports & Analytics',
      '/settings': 'Settings',
    };
    return routeTitles[route] ?? route;
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = _getPageTitle(title);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          // Left Navigation Rail
          Container(
            width: 240,
            color: AppColors.sidebarBackground,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                Image.asset(
                  'assets/images/osp-logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => 
                      const FlutterLogo(size: 40),
                ),
                const SizedBox(height: 32),
                // Navigation Items
                _buildNavItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Overview',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () {
                    if (currentRoute != '/dashboard') {
                      context.go('/dashboard');
                    }
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.forum,
                  label: 'Forums',
                  isSelected: currentRoute == '/forums',
                  onTap: () => context.go('/forums'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.gavel,
                  label: 'Auctions',
                  isSelected: currentRoute == '/auctions',
                  onTap: () => context.go('/auctions'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.business,
                  label: 'Business Directories',
                  isSelected: currentRoute == '/directories',
                  onTap: () => context.go('/directories'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.shopping_cart,
                  label: 'Shop',
                  isSelected: currentRoute == '/shop',
                  onTap: () => context.go('/shop'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.people,
                  label: 'Users',
                  isSelected: currentRoute == '/users',
                  onTap: () => context.go('/users'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.credit_card,
                  label: 'Membership Plans',
                  isSelected: currentRoute == '/plans',
                  onTap: () => context.go('/plans'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.games,
                  label: 'Games',
                  isSelected: currentRoute == '/games',
                  onTap: () => context.go('/games'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.analytics,
                  label: 'Reports & Analytics',
                  isSelected: currentRoute == '/reports',
                  onTap: () => context.go('/reports'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: currentRoute == '/settings',
                  onTap: () => context.go('/settings'),
                ),
                const Spacer(),
                _buildNavItem(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  isSelected: false,
                  onTap: () {
                    onLogout().then((_) {
                      if (context.mounted) {
                        context.go('/login');
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // App Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pageTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (actions != null) Row(children: actions!),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Container(
                    color: AppColors.backgroundDark,
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
