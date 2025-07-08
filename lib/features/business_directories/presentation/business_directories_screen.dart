import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_notifier.dart';

class BusinessDirectoriesScreen extends ConsumerStatefulWidget {
  const BusinessDirectoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BusinessDirectoriesScreen> createState() => _BusinessDirectoriesScreenState();
}

class _BusinessDirectoriesScreenState extends ConsumerState<BusinessDirectoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when the screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref.read(businessDirectoriesNotifierProvider.notifier).loadBusinessCategories();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessDirectoriesNotifierProvider);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business Directories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Businesses'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildCategoriesTab(state),
            _buildBusinessesTab(state),
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
                      DataCell(Text(category.id ?? 'N/A')),
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
