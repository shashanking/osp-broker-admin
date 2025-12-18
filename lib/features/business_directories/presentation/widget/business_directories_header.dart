import 'package:flutter/material.dart';
import 'business_category_tableSection.dart';
import 'business_list_tableSection.dart';
import 'business_category_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_notifier.dart';
import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart';

class BusinessDirectoriesTableSection extends ConsumerStatefulWidget {
  const BusinessDirectoriesTableSection({super.key});

  @override
  ConsumerState<BusinessDirectoriesTableSection> createState() =>
      _BusinessDirectoriesTableSectionState();
}

class _BusinessDirectoriesTableSectionState
    extends ConsumerState<BusinessDirectoriesTableSection> {
  bool isBusinessCategory = true;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selectedCategories = [];
  String _sortBy = 'name';
  bool _sortAscending = true;
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load business categories when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(businessDirectoriesNotifierProvider.notifier)
          .loadBusinessCategories();
    });
  }

  // Filter and sort categories based on current filters and sort options
  List<BusinessCategory> _getFilteredAndSortedCategories(
      List<BusinessCategory> categories) {
    // Apply search filter
    var filtered = categories.where((category) {
      final nameMatch =
          category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final statusMatch = _statusFilter == 'all' ||
          (_statusFilter == 'active' && category.business.isNotEmpty) ||
          (_statusFilter == 'inactive' && category.business.isEmpty);
      return nameMatch && statusMatch;
    }).toList();

    // Apply sorting
    filtered.sort((a, b) {
      int compareResult;
      switch (_sortBy) {
        case 'name':
          compareResult = a.name.compareTo(b.name);
          break;
        case 'count':
          compareResult = a.business.length.compareTo(b.business.length);
          break;
        default:
          compareResult = a.name.compareTo(b.name);
      }
      return _sortAscending ? compareResult : -compareResult;
    });

    return filtered;
  }

  // Handle category deletion
  Future<void> _deleteSelectedCategories() async {
    if (_selectedCategories.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete ${_selectedCategories.length} selected categories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFC02A2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete categories one by one
        for (var category in _selectedCategories) {
          await ref
              .read(businessDirectoriesNotifierProvider.notifier)
              .deleteBusinessCategory(category['id']);
        }

        // Clear selection after deletion
        setState(() {
          _selectedCategories.clear();
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${_selectedCategories.length} categories deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting categories: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show sort options dialog
  Future<void> _showSortOptions() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Name (A-Z)'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _sortAscending = true;
                });
                Navigator.of(context).pop({'sortBy': value, 'ascending': true});
              },
            ),
            RadioListTile<String>(
              title: const Text('Business Count (Low to High)'),
              value: 'count',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _sortAscending = true;
                });
                Navigator.of(context).pop({'sortBy': value, 'ascending': true});
              },
            ),
            RadioListTile<String>(
              title: const Text('Business Count (High to Low)'),
              value: 'count',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _sortAscending = false;
                });
                Navigator.of(context)
                    .pop({'sortBy': value, 'ascending': false});
              },
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _sortBy = result['sortBy'] as String;
        _sortAscending = result['ascending'] as bool;
      });
    }
  }

  // Show filter options dialog
  Future<void> _showFilterOptions() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter By Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Categories'),
              value: 'all',
              groupValue: _statusFilter,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
            RadioListTile<String>(
              title: const Text('Active (With Businesses)'),
              value: 'active',
              groupValue: _statusFilter,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
            RadioListTile<String>(
              title: const Text('Inactive (No Businesses)'),
              value: 'inactive',
              groupValue: _statusFilter,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _statusFilter = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessDirectoriesNotifierProvider);
    final categories = _getFilteredAndSortedCategories(state.categories);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header with tabs and search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: Column(
              // Changed from Row to Column for better layout
              children: [
                // Tabs row
                Row(
                  children: [
                    Container(
                      width: 300, // Reduced from 407
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F2ED),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(
                              'Business Category', isBusinessCategory),
                          _buildTabButton('Business List', !isBusinessCategory),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search and filter row
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6EF),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search for Business Categories...',
                            hintStyle: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(Icons.search,
                                size: 16, color: Color(0xFF333333)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // Reduced from 24

                    // Sort button
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF333333)),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(42),
                          right: Radius.zero,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: _showSortOptions,
                        icon: const Icon(Icons.sort,
                            size: 14, color: Color(0xFF333333)),
                        label: const Text(
                          'Sort',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),

                    // Filter button
                    Container(
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF333333),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.zero,
                          right: Radius.circular(42),
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: _showFilterOptions,
                        icon: const Icon(Icons.filter_alt_outlined,
                            size: 14, color: Colors.white),
                        label: const Text(
                          'Filter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Delete button (only show if items are selected)
                    if (_selectedCategories.isNotEmpty)
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC02A2A),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _deleteSelectedCategories,
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.white),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Add filter widget for business categories
          if (isBusinessCategory) const BusinessCategoryFilters(),

          // Loading indicator
          if (state.isLoading && categories.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.error != null)
            SizedBox(
              height: 200,
              child: Center(
                child: Text('Error: ${state.error}'),
              ),
            )
          else
            SizedBox(
              height: 400, // Fixed height for content area
              child: isBusinessCategory
                  ? const BusinessCategoryTableSection()
                  : const BusinessListTableSection(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isBusinessCategory = text == 'Business Category';
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF333333) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4D4D4D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
