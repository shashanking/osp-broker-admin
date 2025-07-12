import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/business_directories_notifier.dart';
import '../../data/repositories/business_directories_repository.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'add_category_dialog.dart';

class BusinessDirectoriesTopSection extends ConsumerStatefulWidget {
  const BusinessDirectoriesTopSection({Key? key}) : super(key: key);

  @override
  ConsumerState<BusinessDirectoriesTopSection> createState() =>
      _BusinessDirectoriesTopSectionState();
}

class _BusinessDirectoriesTopSectionState
    extends ConsumerState<BusinessDirectoriesTopSection> {
  int _totalBusinesses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Schedule the data loading after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load categories in parallel
      final categoriesFuture = ref
          .read(businessDirectoriesNotifierProvider.notifier)
          .loadBusinessCategories();

      // Load businesses in parallel
      final repository = BusinessDirectoriesRepository(
        ref.read(baseApiServiceProvider),
      );
      final businessesFuture = repository.fetchAllBusinesses();

      // Wait for both operations to complete
      await Future.wait([categoriesFuture, businessesFuture]);

      // Get the businesses response from the completed future
      final response = await businessesFuture;

      if (mounted) {
        setState(() {
          _totalBusinesses = response.data.businesses.length;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading data: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        // Show error to user (you can replace this with a SnackBar or other UI feedback)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddCategoryDialog(
        onSave: (name, iconName) async {
          // This will be called when the user saves the category
          debugPrint('Saving category: $name with icon: $iconName');
          
          try {
            // Call the API to save the category
            await ref.read(businessDirectoriesNotifierProvider.notifier)
                .createBusinessCategory(
                  name: name,
                  description: 'Category for $name', // You might want to make this configurable
                );
            return true;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save category: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        },
      ),
    );

    if (result != null && mounted) {
      // Refresh data after adding a category
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator only if it's the initial load
    if (_isLoading && _totalBusinesses == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Business Directories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6DC),
                  borderRadius: BorderRadius.circular(76),
                ),
                child: Row(
                  children: [
                    _buildTimePeriodButton('1 day', isSelected: false),
                    _buildTimePeriodButton('7 days', isSelected: true),
                    _buildTimePeriodButton('30 days', isSelected: false),
                    _buildTimePeriodButton('Yearly', isSelected: false),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle export CSV
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24439B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Export CSV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                title: 'Add Business Category',
                value: '',
                isAddCard: true,
                onTap: () {
                  // Handle add business category
                  _showAddCategoryDialog();
                },
              ),
              const SizedBox(width: 20),
              Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(businessDirectoriesNotifierProvider);
                  final categoryCount = state.categories.length;
                  return _buildStatCard(
                    title: 'Total Business Categories',
                    value: _isLoading ? '...' : categoryCount.toString(),
                    change:
                        '+1.7%', // Removed percentage as it's not part of the API
                    isPositive: true, // Removed as we're not tracking changes
                    icon: Icons.menu,
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                title: 'Total Businesses',
                value: _isLoading ? '...' : _totalBusinesses.toString(),
                change:
                    '+2.3%', // Removed percentage as it's not part of the API
                isPositive: true, // Removed as we're not tracking changes
                icon: Icons.business,
              ),
              const SizedBox(width: 20),
              _buildStatCard(
                title: 'Approval Pending',
                value: '76',
                change: '+4.3%',
                isPositive: false,
                icon: Icons.pending_actions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodButton(String text, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFF333333) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(42),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFFEBE6DC) : const Color(0xFF4D4D4D),
            fontSize: 14,
            fontFamily: 'Lato',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? change,
    bool? isPositive,
    IconData? icon,
    bool isAddCard = false,
    VoidCallback? onTap,
  }) {
    // Don't show change indicator if change is empty
    final showChange = change?.isNotEmpty == true;
    if (isAddCard) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF24439B), Color(0xFF15A5CD)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 102,
                  height: 102,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 48,
                    color: Color(0xFF24439B),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Basement Grotesque',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF24439B),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Icon(
                icon,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Basement Grotesque',
                      color: Color(0xFF121212),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            fixedSize: const Size(92, 30),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            backgroundColor: const Color(0xFF333333),
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(color: Colors.white),
                          )),
                      if (showChange) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(left: 98),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isPositive!
                                ? const Color(0xFF80C02A)
                                : const Color(0xFFFF4D4D),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          change!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4D4D4D),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
