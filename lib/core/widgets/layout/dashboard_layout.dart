import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';

export 'top_bar.dart';

class DashboardLayout extends StatefulWidget {
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
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarCollapsed = false;

  static const String _sidebarCollapsedKey = 'sidebar_collapsed';

  @override
  void initState() {
    super.initState();
    _restoreSidebarCollapsedState();
  }

  Future<void> _restoreSidebarCollapsedState() async {
    try {
      final Box box = Hive.isBoxOpen('auth')
          ? Hive.box('auth')
          : await Hive.openBox('auth');
      bool collapsed = (box.get(_sidebarCollapsedKey) as bool?) ?? false;
      if (collapsed) {
        collapsed = false;
        await box.put(_sidebarCollapsedKey, false);
      }
      if (!mounted) return;
      setState(() {
        _isSidebarCollapsed = collapsed;
      });
    } catch (_) {
      // If Hive isn't available for some reason, just fall back to default.
    }
  }

  Future<void> _persistSidebarCollapsedState(bool value) async {
    try {
      final Box box = Hive.isBoxOpen('auth')
          ? Hive.box('auth')
          : await Hive.openBox('auth');
      await box.put(_sidebarCollapsedKey, value);
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;
    final shouldCollapseSidebar =
        !isMobile && (isTablet || _isSidebarCollapsed);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      // Mobile: Show app bar with menu button
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.sidebarBackground,
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: widget.actions,
            )
          : null,
      // Mobile: Navigation drawer
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          // Desktop/Tablet: Left Navigation Rail
          if (!isMobile)
            Container(
              width: shouldCollapseSidebar ? 80 : 280,
              color: AppColors.sidebarBackground,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!shouldCollapseSidebar)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const FlutterLogo(size: 40),
                            ),
                          ),
                        )
                      else
                        Image.asset(
                          'assets/images/logo.png',
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const FlutterLogo(size: 40),
                        ),
                      if (!isTablet)
                        IconButton(
                          tooltip: shouldCollapseSidebar
                              ? 'Expand sidebar'
                              : 'Collapse sidebar',
                          onPressed: () {
                            setState(() {
                              _isSidebarCollapsed = !_isSidebarCollapsed;
                            });
                            _persistSidebarCollapsedState(_isSidebarCollapsed);
                          },
                          icon: Icon(
                            shouldCollapseSidebar
                                ? Icons.keyboard_double_arrow_right
                                : Icons.keyboard_double_arrow_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Navigation Items
                  // _buildNavItem(
                  //   context,
                  //   icon: Icons.dashboard,
                  //   label: 'Overview',
                  //   isSelected: widget.currentRoute == '/dashboard',
                  //   onTap: () {
                  //     if (widget.currentRoute != '/dashboard') {
                  //       context.go('/dashboard');
                  //     }
                  //   },
                  // ),
                  _buildNavItem(
                    context,
                    icon: Icons.forum,
                    label: 'Forums',
                    isSelected: widget.currentRoute == '/forums',
                    onTap: () => context.go('/forums'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.gavel,
                    label: 'Auctions',
                    isSelected: widget.currentRoute == '/auctions',
                    onTap: () => context.go('/auctions'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.chat,
                    label: 'Messages',
                    isSelected: widget.currentRoute.startsWith('/chat') &&
                        widget.currentRoute != '/all-chats',
                    onTap: () => context.go('/chat'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'All Chats',
                    isSelected: widget.currentRoute == '/all-chats',
                    onTap: () => context.go('/all-chats'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.business,
                    label: 'Business Directories',
                    isSelected:
                        widget.currentRoute.startsWith('/business-directories'),
                    onTap: () => context.go('/business-directories'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Shop',
                    isSelected: widget.currentRoute.startsWith('/shop'),
                    onTap: () => context.go('/shop'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people,
                    label: 'Users',
                    isSelected: widget.currentRoute == '/users',
                    onTap: () => context.go('/users'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.credit_card,
                    label: 'Membership Plans',
                    isSelected: widget.currentRoute == '/plans',
                    onTap: () => context.go('/plans'),
                    isTablet: shouldCollapseSidebar,
                  ),
                  // _buildNavItem(
                  //   context,
                  //   icon: Icons.games,
                  //   label: 'Games',
                  //   isSelected: currentRoute == '/games',
                  //   onTap: () => context.go('/games'),
                  // ),
                  // _buildNavItem(
                  //   context,
                  //   icon: Icons.analytics,
                  //   label: 'Reports & Analytics',
                  //   isSelected: currentRoute == '/reports',
                  //   onTap: () => context.go('/reports'),
                  // ),
                  // _buildNavItem(
                  //   context,
                  //   icon: Icons.settings,
                  //   label: 'Settings',
                  //   isSelected: currentRoute == '/settings',
                  //   onTap: () => context.go('/settings'),
                  // ),
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
                        await widget.onLogout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      isTablet: shouldCollapseSidebar,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: widget.child,
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
    bool isTablet = false,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: 16,
          ),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isTablet ? 8 : 16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sidebarSelected : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              bottomLeft: Radius.circular(50),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.background
                    : AppColors.sidebarSelected,
                size: 20,
              ),
              if (!isTablet) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.sidebarSelected,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.sidebarBackground,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const FlutterLogo(size: 40),
            ),
            const SizedBox(height: 32),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.forum,
                    label: 'Forums',
                    isSelected: widget.currentRoute == '/forums',
                    onTap: () {
                      context.go('/forums');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.gavel,
                    label: 'Auctions',
                    isSelected: widget.currentRoute == '/auctions',
                    onTap: () {
                      context.go('/auctions');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat,
                    label: 'Messages',
                    isSelected: widget.currentRoute.startsWith('/chat') &&
                        widget.currentRoute != '/all-chats',
                    onTap: () {
                      context.go('/chat');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'All Chats',
                    isSelected: widget.currentRoute == '/all-chats',
                    onTap: () {
                      context.go('/all-chats');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people,
                    label: 'Users',
                    isSelected: widget.currentRoute == '/users',
                    onTap: () {
                      context.go('/users');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Shop',
                    isSelected: widget.currentRoute.startsWith('/shop'),
                    onTap: () {
                      context.go('/shop');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.credit_card,
                    label: 'Membership Plans',
                    isSelected: widget.currentRoute == '/plans',
                    onTap: () {
                      context.go('/plans');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Logout
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFCC1919),
                borderRadius: BorderRadius.circular(50),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await widget.onLogout();
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
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : AppColors.sidebarSelected,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.sidebarSelected,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.sidebarSelected.withOpacity(0.2),
      onTap: onTap,
    );
  }
}
