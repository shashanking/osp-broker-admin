import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_notifier.dart';

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
    // Fetch and log categories when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndLogCategories();
    });
  }

  Future<void> _fetchAndLogCategories() async {
    try {
      log('Fetching business categories...');
      await ref.read(businessDirectoriesNotifierProvider.notifier).loadBusinessCategories();
    } catch (e) {
      log('Error in _fetchAndLogCategories: $e');
    }
  }

  Future<void> _fetchAndLogBusinesses() async {
    try {
      log('Fetching businesses...');
      await ref.read(businessDirectoriesNotifierProvider.notifier).fetchAllBusinesses();
    } catch (e) {
      log('Error in _fetchAndLogBusinesses: $e');
    }
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
    
    final state = ref.watch(businessDirectoriesNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Business Directories',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _fetchAndLogBusinesses,
                              icon: const Icon(Icons.list),
                              label: const Text('List Businesses'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement add new business directory
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Directory'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      tabs: const [
                        Tab(text: 'Categories'),
                        Tab(text: 'Businesses'),
                      ],
                      labelColor: Theme.of(context).primaryColor,
                      indicatorColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildCategoriesTab(state),
                          _buildBusinessesTab(state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(BusinessDirectoriesState state) {
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    final categories = state.categories;
    final categoryCount = categories.length;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(businessDirectoriesNotifierProvider.notifier)
          .loadBusinessCategories(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Categories: $categoryCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                // Add new category button can be added here
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                    label: Text('Businesses', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: categories.map((category) {
                  return DataRow(
                    cells: [
                      DataCell(Text(category.id)),
                      DataCell(Text(category.name)),
                      DataCell(
                        Text(
                          '${category.business.length}',
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                // Edit category action
                              },
                              color: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                // Delete category action
                              },
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessesTab(BusinessDirectoriesState state) {
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    // Get all businesses from all categories
    final allBusinesses = state.categories.expand((category) => category.business).toList();

    return RefreshIndicator(
      onRefresh: () => ref
          .read(businessDirectoriesNotifierProvider.notifier)
          .loadBusinessCategories(),
      child: allBusinesses.isEmpty
          ? const Center(child: Text('No businesses found'))
          : ListView.builder(
              itemCount: allBusinesses.length,
              itemBuilder: (context, index) {
                final business = allBusinesses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(business.name),
                    // subtitle: Text(business.businessName ?? 'No description'),
                  ),
                );
              },
            ),
    );
  }
}