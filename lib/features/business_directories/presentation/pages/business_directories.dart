import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_notifier.dart';
import 'package:osp_broker_admin/features/business_directories/presentation/widget/business_directories_topSection.dart';
import 'package:osp_broker_admin/features/business_directories/presentation/widget/business_directories_tableSection.dart';

// GoRoute configuration for navigation
final GoRoute goRouteBusinessDirectories = GoRoute(
  path: BusinessDirectoriesPage.routePath,
  name: BusinessDirectoriesPage.routeName,
  pageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: const BusinessDirectoriesPage(),
  ),
);

class BusinessDirectoriesPage extends ConsumerStatefulWidget {
  const BusinessDirectoriesPage({super.key});
  static const String routeName = 'business-directories';
  static const String routePath = '/business-directories';

  static Route<dynamic> route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => const BusinessDirectoriesPage(),
    );
  }

  @override
  ConsumerState<BusinessDirectoriesPage> createState() => _BusinessDirectoriesPageState();
}

class _BusinessDirectoriesPageState extends ConsumerState<BusinessDirectoriesPage> {
  @override
  void initState() {
    super.initState();
    // Fetch business categories when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(businessDirectoriesNotifierProvider.notifier).loadBusinessCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    String userName = 'User';
    String userRole = 'Admin';
    
    // Extract user info from auth state if available
    authState.whenOrNull(
      authenticated: (token, user) {
        userName = user['name']?.toString() ?? 'User';
        userRole = user['role']?.toString() ?? 'Admin';
      },
    );
    
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            userName: userName,
            userRole: userRole,
            onNotificationTap: () {
              // Handle notification tap
            },
            onProfileTap: () {
              // Handle profile tap
            },
            onCreateAuctionTap: () {
              // Handle create auction tap
            },
          ),
          const BusinessDirectoriesTopSection(),
          const Expanded(
            child: BusinessDirectoriesTableSection(),
          ),
        ],
      ),
    );
  }


}