import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';

export 'top_bar.dart';

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

  @override
  /// Builds the main dashboard layout.
  ///
  /// This widget is used to display the main content of the application,
  /// including the navigation rail and the main content area.
  ///
  /// The [currentRoute] parameter is used to determine which navigation item
  /// should be highlighted as the current route.
  ///
  /// The [title] parameter is used to display the title of the current route in
  /// the top bar.
  ///
  /// The [child] parameter is used to display the main content of the current
  /// route.
  ///
  /// The [actions] parameter is used to display a list of actions in the top
  /// bar.
  ///
  /// The [onLogout] parameter is used to log the user out of the application.
  ///
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Navigation Rail
          Container(
            width: 280,
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
                Container(
                  margin: const EdgeInsets.only(
                    top: 4,
                    bottom: 4,
                    left: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFCC1919),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      bottomLeft: Radius.circular(50),
                    ),
                  ),
                  child: _buildNavItem(
                    context,
                    icon: Icons.logout,
                    label: 'Logout',
                    isSelected: false,
                    onTap: () async {
                      await onLogout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: child,
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
        margin: const EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: 16,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sidebarSelected : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            bottomLeft: Radius.circular(50),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.background : AppColors.sidebarSelected,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.background
                    : AppColors.sidebarSelected,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
