import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/forum_admin_notifier.dart';
import '../../domain/forum_models.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

class AddForumDialog extends ConsumerStatefulWidget {
  final Forum? forum;
  const AddForumDialog({super.key, this.forum});

  @override
  ConsumerState<AddForumDialog> createState() => _AddForumDialogState();
}

class _AddForumDialogState extends ConsumerState<AddForumDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  String? _author;
  String? _userId; // Will be auto-filled

  @override
  void initState() {
    super.initState();
    if (widget.forum != null) {
      _titleController.text = widget.forum!.title;
      _descriptionController.text = widget.forum!.description;
      _selectedCategoryId = widget.forum!.categoryId;
      _author = widget.forum!.author;
      _userId = widget.forum!.userId;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(forumAdminNotifierProvider);
        if (state.categories.isNotEmpty) {
          _selectedCategoryId = state.categories.first.id;
        }
        final baseApi = ref.read(baseApiServiceProvider);
        _userId = baseApi.userId;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.forum == null && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_author == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing author or userId')),
      );
      return;
    }
    try {
      if (widget.forum != null) {
        // Edit mode: only update title and description
        await ref.read(forumAdminNotifierProvider.notifier).updateForum(
          forumId: widget.forum!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      } else {
        // Create mode
        await ref.read(forumAdminNotifierProvider.notifier).createForum(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          author: _author!,
          categoryId: _selectedCategoryId!,
          userId: _userId!,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${widget.forum != null ? 'update' : 'create'} forum: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(forumAdminNotifierProvider).categories;
    final validCategoryIds = categories.map((c) => c.id).toSet();
    if (_selectedCategoryId != null && !validCategoryIds.contains(_selectedCategoryId)) {
      _selectedCategoryId = null;
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.forum != null ? 'Edit Forum' : 'Create Forum',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                if (widget.forum == null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (val) => val == null ? 'Select a category' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Author'),
                    onChanged: (val) => _author = val,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // User ID field removed, auto-filled from storage
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.forum != null ? 'Update' : 'Create'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
