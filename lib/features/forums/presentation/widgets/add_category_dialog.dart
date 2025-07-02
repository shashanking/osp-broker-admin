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
  String? _selectedModeratorId;
  final Set<String> _selectedMembershipPlanIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    final cat = widget.category;
    if (cat != null) {
      _nameController.text = cat.name;
      _descriptionController.text = cat.description;
      _selectedModeratorId = cat.moderatorId;
      _selectedMembershipPlanIds.clear();
      _selectedMembershipPlanIds.addAll(cat.membershipAccess);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(forumAdminNotifierProvider);
        if (state.moderators.isNotEmpty) {
          _selectedModeratorId = state.moderators.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModeratorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a moderator')),
      );
      return;
    }

    try {
      if (widget.category != null) {
        // Update existing category
        await ref.read(forumAdminNotifierProvider.notifier).updateCategory(
          widget.category!.id,
          {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'moderatorId': _selectedModeratorId!,
            'icon': widget.category!.icon ?? '',
            'membership_access': _selectedMembershipPlanIds.toList(),
          },
        );
      } else {
        // Create new category
        await ref.read(forumAdminNotifierProvider.notifier).createCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          moderatorId: _selectedModeratorId!,
          icon: 'https://ui-avatars.com/api/?name=${_nameController.text.trim().replaceAll(' ', '+')}&background=random',
          membershipAccess: _selectedMembershipPlanIds.toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${widget.category != null ? 'update' : 'create'} category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final moderators = forumState.moderators;
    final membershipPlans = forumState.membershipPlans;
    final isLoading =
        forumState.isLoadingModerators || forumState.isLoadingMembershipPlans;

    return AlertDialog(
      title: Text(widget.category != null ? 'Edit Category' : 'Add New Category'),
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
              const Text('Moderator',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedModeratorId,
                      items: moderators
                          .map((moderator) => DropdownMenuItem(
                                value: moderator.id,
                                child: Text(moderator.fullName ?? 'Unknown'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedModeratorId = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) =>
                          value == null ? 'Please select a moderator' : null,
                    ),
              const SizedBox(height: 24),
              const Text('Membership Plans',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select membership plans (leave empty to make it public):',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ...membershipPlans.map((plan) {
                            return CheckboxListTile(
                              title: Text(plan.name),
                              value:
                                  _selectedMembershipPlanIds.contains(plan.id),
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedMembershipPlanIds.add(plan.id);
                                  } else {
                                    _selectedMembershipPlanIds.remove(plan.id);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
              const SizedBox(height: 16),
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
                          : const Text('Create'),
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
