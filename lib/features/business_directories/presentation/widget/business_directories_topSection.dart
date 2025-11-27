import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/business_directories_notifier.dart';
import '../../data/repositories/business_directories_repository.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'add_business_category_dialog.dart';

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
          _totalBusinesses = response.businesses.length;
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddBusinessCategoryDialog(
        onSave: (name, description) async {
          // This will be called when the user saves the category
          debugPrint('Saving category: $name with description: $description');
          
          try {
            // Call the API to save the category
            await ref.read(businessDirectoriesNotifierProvider.notifier)
                .createBusinessCategory(
                  name: name,
                  description: description,
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
            rethrow; // Re-throw to let the dialog handle the error
          }
        },
      ),
    );

    if (result == true && mounted) {
      // Refresh data after adding a category
      await _loadData();
      // Show confirmation message in parent widget
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category created successfully!'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Reduced padding
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
                  fontSize: 20, // Reduced from 24
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 20
          // Stats Cards - Reduced size
          SizedBox(
            height: 80, // Reduced from ~200 (60% reduction)
            child: Row(
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
                const SizedBox(width: 12), // Reduced from 20
                Consumer(
                  builder: (context, ref, _) {
                    final state = ref.watch(businessDirectoriesNotifierProvider);
                    final categoryCount = state.categories.length;
                    return _buildStatCard(
                      title: 'Total Business Categories',
                      value: _isLoading ? '...' : categoryCount.toString(),
                      change: '+1.7%',
                      isPositive: true,
                      icon: Icons.menu,
                    );
                  },
                ),
                const SizedBox(width: 12), // Reduced from 20
                _buildStatCard(
                  title: 'Total Businesses',
                  value: _isLoading ? '...' : _totalBusinesses.toString(),
                  change: '+2.3%',
                  isPositive: true,
                  icon: Icons.business,
                ),
                const SizedBox(width: 12), // Reduced from 20
                _buildStatCard(
                  title: 'Approval Pending',
                  value: '76',
                  change: '+4.3%',
                  isPositive: false,
                  icon: Icons.pending_actions,
                ),
              ],
            ),
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
            height: 80, // Fixed reduced height
            padding: const EdgeInsets.all(8), // Reduced padding
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF24439B), Color(0xFF15A5CD)],
              ),
              borderRadius: BorderRadius.circular(12), // Reduced from 16
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
                  width: 40, // Reduced from 102
                  height: 40, // Reduced from 102
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20, // Reduced from 48
                    color: Color(0xFF24439B),
                  ),
                ),
                const SizedBox(width: 8), // Reduced from 20
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
                          fontSize: 12, // Reduced from 20
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // Reduced from 8
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // Reduced from 32
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 10, // Reduced from 14
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
        height: 80, // Fixed reduced height
        padding: const EdgeInsets.all(8), // Reduced from 16
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Reduced from 16
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
              width: 28, // Reduced from 70
              height: 28, // Reduced from 70
              decoration: BoxDecoration(
                color: const Color(0xFF24439B),
                borderRadius: BorderRadius.circular(14), // Reduced from 35
              ),
              child: Icon(
                icon,
                size: 14, // Reduced from 36
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8), // Reduced from 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10, // Reduced from 16
                      color: Color(0xFF333333),
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced from 8
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16, // Reduced from 28
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Basement Grotesque',
                      color: Color(0xFF121212),
                    ),
                  ),
                  // Removed the View button and simplified the change indicator
                  if (showChange)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2), // Reduced from 4
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
                            size: 8, // Reduced from 16
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          change!,
                          style: const TextStyle(
                            fontSize: 8, // Reduced from 14
                            color: Color(0xFF4D4D4D),
                            fontFamily: 'Montserrat',
                          ),
                        ),
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
