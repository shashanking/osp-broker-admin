import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/forums/application/forum_admin_notifier.dart';

class CategorySelectionDialog extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const CategorySelectionDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState
    extends ConsumerState<CategorySelectionDialog> {
  final Set<String> _selectedCategoryIds = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load categories when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumAdminNotifierProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final categories = forumState.categories;
    final isLoadingCategories = forumState.isLoading;

    return AlertDialog(
      title: Text('Assign Moderator to Category'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select categories to assign ${widget.userName} as moderator:',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (isLoadingCategories)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No categories available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected =
                        _selectedCategoryIds.contains(category.id);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        setState(() {
                          if (_selectedCategoryIds.contains(category.id)) {
                            _selectedCategoryIds.remove(category.id);
                          } else {
                            _selectedCategoryIds.add(category.id);
                          }
                        });
                      },
                      tileColor: isSelected ? Colors.blue.shade50 : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedCategoryIds.isEmpty || isLoading)
              ? null
              : () async {
                  setState(() {
                    isLoading = true;
                  });

                  try {
                    // Return the selected categories to the caller
                    final selected = categories
                        .where((c) => _selectedCategoryIds.contains(c.id))
                        .toList();
                    Navigator.of(context).pop(selected);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Assign Moderator'),
        ),
      ],
    );
  }
}
