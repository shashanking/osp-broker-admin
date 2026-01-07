import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/business_directories/presentation/widget/add_business_category_dialog.dart';

import '../../application/business_directories_notifier.dart';
import '../../domain/business_directories_model.dart';

class BusinessCategoryTableSection extends ConsumerStatefulWidget {
  final List<BusinessCategory>? categories;
  const BusinessCategoryTableSection({Key? key, this.categories})
      : super(key: key);

  @override
  ConsumerState<BusinessCategoryTableSection> createState() =>
      _BusinessCategoryTableSectionState();
}

class _BusinessCategoryTableSectionState
    extends ConsumerState<BusinessCategoryTableSection> {
  final List<Map<String, dynamic>> _selectedCategories = [];
  final Map<String, IconData> _categoryIcons = {
    'Restaurant': Icons.restaurant,
    'Attorney': Icons.gavel,
    'Law Firm': Icons.business,
    'IT Service': Icons.computer,
    'Fire Service': Icons.local_fire_department,
  };
  final Map<String, Color> _categoryColors = {
    'Restaurant': const Color(0xFFD59823),
    'Attorney': const Color(0xFF80C02A),
    'Law Firm': const Color(0xFF473DDA),
    'IT Service': const Color(0xFF25B4DC),
    'Fire Service': Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessDirectoriesNotifierProvider);
    final categories = widget.categories ?? state.filteredCategories;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0.0),
              child: Row(
                children: [
                  // Category Name with Checkbox
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Checkbox(
                          value:
                              _selectedCategories.length == categories.length &&
                                  categories.isNotEmpty,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedCategories.clear();
                                _selectedCategories.addAll(
                                  categories.map((category) => {
                                        'id': category.id,
                                        'name': category.name,
                                      }),
                                );
                              } else {
                                _selectedCategories.clear();
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Category Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Icon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  // Business Count
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Business',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  // Status
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  // Actions
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Actions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Data Rows
            ...categories.map((category) {
              final isSelected =
                  _selectedCategories.any((item) => item['id'] == category.id);
              final icon =
                  _categoryIcons[category.name] ?? Icons.category_outlined;
              final color =
                  _categoryColors[category.name] ?? const Color(0xFF6C63FF);

              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                child: Row(
                  children: [
                    // Category Name with Checkbox
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCategories.add({
                                    'id': category.id,
                                    'name': category.name,
                                  });
                                } else {
                                  _selectedCategories.removeWhere(
                                    (item) => item['id'] == category.id,
                                  );
                                }
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(34),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icon
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Business Count
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${category.business.length} ${category.business.length == 1 ? 'Business' : 'Businesses'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    // Status
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: category.statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.statusText,
                            style: TextStyle(
                              color: category.statusTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Edit button - only show for active categories
                          if (!category.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF2196F3)),
                              onPressed: () async {
                                // Open edit dialog (assuming you have an AddCategoryDialog that supports edit)
                                final result = await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AddBusinessCategoryDialog(
                                    category: category,
                                    onSave: (name, description) async {
                                      await ref
                                          .read(
                                              businessDirectoriesNotifierProvider
                                                  .notifier)
                                          .updateBusinessCategory(
                                            id: category.id,
                                            name: name,
                                            description: description,
                                          );
                                    },
                                  ),
                                );
                                if (result == true) {
                                  // Optionally refresh categories if needed
                                  ref
                                      .read(businessDirectoriesNotifierProvider
                                          .notifier)
                                      .loadBusinessCategories();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Category updated successfully!'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                }
                              },
                            ),
                          // Delete/Restore button
                          if (!category.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Color(0xFFF44336)),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Category'),
                                    content: Text(
                                        'Are you sure you want to delete "${category.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(businessDirectoriesNotifierProvider
                                          .notifier)
                                      .softDeleteBusinessCategory(category.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Category deleted successfully!'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                }
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.restore,
                                  size: 20, color: Color(0xFF4CAF50)),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Restore Category'),
                                    content: Text(
                                        'Are you sure you want to restore "${category.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white),
                                        child: const Text('Restore'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(businessDirectoriesNotifierProvider
                                          .notifier)
                                      .restoreBusinessCategory(category.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Category restored successfully!'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
