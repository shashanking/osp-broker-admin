import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/forums/application/forum_admin_notifier.dart';

class AnnouncementsDialog extends ConsumerStatefulWidget {
  const AnnouncementsDialog({super.key});

  @override
  ConsumerState<AnnouncementsDialog> createState() => _AnnouncementsDialogState();
}

class _AnnouncementsDialogState extends ConsumerState<AnnouncementsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(forumAdminNotifierProvider.notifier).addAnnouncement(
        title: _titleController.text,
        description: _descriptionController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add announcement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Announcement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addAnnouncement,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}

class AnnouncementsListDialog extends ConsumerStatefulWidget {
  const AnnouncementsListDialog({super.key});

  @override
  ConsumerState<AnnouncementsListDialog> createState() => _AnnouncementsListDialogState();
}

class _AnnouncementsListDialogState extends ConsumerState<AnnouncementsListDialog> {
  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(forumAdminNotifierProvider).announcements;
    final isLoading = ref.watch(forumAdminNotifierProvider).isLoading;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Announcements'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (ctx) => const AnnouncementsDialog(),
              );
              if (result == true) {
                await ref.read(forumAdminNotifierProvider.notifier).fetchAllAnnouncements();
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : announcements.isEmpty
                ? const Center(child: Text('No announcements found'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(announcement.title),
                          subtitle: Text(announcement.description),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Announcement'),
                                  content: const Text('Are you sure you want to delete this announcement?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true && mounted) {
                                await ref.read(forumAdminNotifierProvider.notifier)
                                    .deleteAnnouncement(announcement.id);
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Announcement deleted')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }
}
