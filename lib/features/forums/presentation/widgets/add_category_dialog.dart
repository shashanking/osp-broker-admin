import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/forum_admin_notifier.dart';

import '../../domain/forum_models.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  const AddCategoryDialog({super.key, this.category});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _iconUrl = '';
  // Bytes of the just-picked image, shown immediately as the preview so the user
  // sees their selection without waiting on (or depending on) the S3 upload.
  Uint8List? _pickedBytes;
  bool _uploadingIcon = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    final cat = widget.category;
    if (cat != null) {
      _nameController.text = cat.name;
      _descriptionController.text = cat.description;
      _iconUrl = cat.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
      }
      return;
    }

    // Show the picked image right away, then upload in the background.
    setState(() {
      _pickedBytes = bytes;
      _uploadingIcon = true;
    });
    try {
      final url =
          await ref.read(forumAdminNotifierProvider.notifier).uploadCategoryIcon(
                bytes: bytes,
                fileName: file.name,
              );
      if (mounted && url != null) {
        setState(() => _iconUrl = url);
      }
    } catch (e) {
      // Upload failed — drop the local preview so we don't imply it was saved.
      if (mounted) setState(() => _pickedBytes = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Icon upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingIcon = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.category != null) {
        // Update existing category
        await ref.read(forumAdminNotifierProvider.notifier).updateCategory(
          widget.category!.id,
          {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'icon': _iconUrl,
          },
        );
      }
      // Category creation is no longer supported (channels are fixed and
      // membership-bound). This dialog is now used only to edit existing
      // categories; the create path has been removed.

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to ${widget.category != null ? 'update' : 'create'} category: $e')),
        );
      }
    }
  }

  Widget _iconPlaceholder() {
    final name = _nameController.text.trim();
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '#',
      style: const TextStyle(
        color: Color(0xFF24439B),
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final isLoading = forumState.isLoading;

    return AlertDialog(
      title:
          Text(widget.category != null ? 'Edit Category' : 'Add New Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text('Category Icon',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF24439B).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickedBytes != null
                        // just-picked image, shown from memory immediately
                        ? Image.memory(
                            _pickedBytes!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : (_iconUrl.startsWith('http://') ||
                                _iconUrl.startsWith('https://'))
                            ? Image.network(
                                _iconUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _iconPlaceholder(),
                              )
                            : _iconPlaceholder(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadingIcon ? null : _pickAndUploadIcon,
                      icon: _uploadingIcon
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                      label: Text(_uploadingIcon
                          ? 'Uploading...'
                          : ((_iconUrl.isEmpty && _pickedBytes == null)
                              ? 'Upload Icon'
                              : 'Change Icon')),
                    ),
                  ),
                  if ((_iconUrl.isNotEmpty || _pickedBytes != null) &&
                      !_uploadingIcon)
                    IconButton(
                      tooltip: 'Remove icon',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _iconUrl = '';
                        _pickedBytes = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
