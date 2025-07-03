import 'package:flutter/material.dart';

import '../../domain/forum_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_forum_dialog.dart';
import '../../application/forum_admin_notifier.dart';

class ForumForumsTable extends StatelessWidget {
  final List<Forum> forums;
  final List<Category> categories;
  const ForumForumsTable(
      {super.key, required this.forums, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F8FA), Color(0xFFE4ECF7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 1,
                    child: Text('Icon',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Forum Name',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Category',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 3,
                    child: Text('Description',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Author',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 1,
                    child: Text('Topics',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2),
                        textAlign: TextAlign.left)),
                Expanded(
                    flex: 2,
                    child: Text('Created',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2),
                        textAlign: TextAlign.left)),
                SizedBox(
                    width: 72,
                    child: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          ...forums.asMap().entries.map((entry) {
            final idx = entry.key;
            final forum = entry.value;
            return Column(
              children: [
                _ForumRow(
                  forum: forum,
                  categories: categories,
                  rowColor:
                      idx % 2 == 0 ? const Color(0xFFF7F9FC) : Colors.white,
                ),
                if (idx != forums.length - 1)
                  const Divider(
                      height: 0, thickness: 1, color: Color(0xFFE9EDF5)),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _ForumRow extends ConsumerWidget {
  final Forum forum;
  final List<Category> categories;
  final Color? rowColor;
  const _ForumRow(
      {required this.forum, required this.categories, this.rowColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        color: rowColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.blue.withOpacity(0.06),
          onTap: () {}, // Optionally open forum details
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                // Icon/avatar
                Expanded(
                  flex: 1,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFEDF1FA),
                    radius: 22,
                    child:
                        Icon(Icons.forum, color: Color(0xFFB0B8C1), size: 22),
                  ),
                ),
                // Name
                Expanded(
                  flex: 2,
                  child: Text(
                    forum.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                // Category
                Expanded(
                  flex: 2,
                  child: Text(
                    categories
                        .firstWhere(
                          (cat) => cat.id == forum.categoryId,
                          orElse: () => Category(
                            id: '',
                            name: 'Unknown',
                            description: '',
                            moderatorId: '',
                            icon: '',
                            membershipAccess: const [],
                            createdAt: DateTime(2000),
                            updatedAt: DateTime(2000),
                            isActive: true,
                            count: const {},
                          ),
                        )
                        .name,
                    style: const TextStyle(
                        color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Description
                Expanded(
                  flex: 3,
                  child: Text(
                    forum.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                // Author
                Expanded(
                  flex: 2,
                  child: Text(
                    forum.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                // Topics
                Expanded(
                  flex: 1,
                  child: Text(
                    (forum.count['topics'] ?? 0).toString(),
                    textAlign: TextAlign.left,
                  ),
                ),
                // Created At
                Expanded(
                  flex: 2,
                  child: Text(
                    forum.createdAt.toIso8601String().substring(0, 10),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
                // Actions
                SizedBox(
                  width: 72,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Edit',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            // final result = await showDialog<bool>(
                            //   context: context,
                            //   builder: (ctx) => AddForumDialog(forum: forum),
                            // );
                            // if (result == true) {
                            //   await ref
                            //       .read(forumAdminNotifierProvider.notifier)
                            //       .loadForums();
                            // }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.edit,
                                color: Colors.blue[600], size: 22),
                          ),
                          hoverColor: Colors.blue.withOpacity(0.08),
                        ),
                      ),
                      Tooltip(
                        message: 'Delete',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            // final confirm = await showDialog<bool>(
                            //   context: context,
                            //   builder: (ctx) => AlertDialog(
                            //     title: const Text('Delete Forum'),
                            //     content: const Text('Are you sure you want to delete this forum?'),
                            //     actions: [
                            //       TextButton(
                            //         onPressed: () => Navigator.of(ctx).pop(false),
                            //         child: const Text('Cancel'),
                            //       ),
                            //       TextButton(
                            //         onPressed: () => Navigator.of(ctx).pop(true),
                            //         child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            //       ),
                            //     ],
                            //   ),
                            // );
                            // if (confirm == true) {
                            //   try {
                            //     await ref.read(forumAdminNotifierProvider.notifier).deleteForum(forum.id);
                            //     // Optionally reload forums if needed
                            //     // await ref.read(forumAdminNotifierProvider.notifier).loadForums();
                            //   } catch (e) {
                            //     if (context.mounted) {
                            //       final msg = e.toString();
                            //       if (msg.contains('unauthorized access')) {
                            //         ScaffoldMessenger.of(context).showSnackBar(
                            //           const SnackBar(content: Text('Unauthorized access. Please login again.')),
                            //         );
                            //         Navigator.of(context).pop();
                            //       } else {
                            //         ScaffoldMessenger.of(context).showSnackBar(
                            //           SnackBar(content: Text('Failed to delete forum: $e')),
                            //         );
                            //       }
                            //     }
                            //   }
                            // }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.delete_outline,
                                color: Colors.red[600], size: 22),
                          ),
                          hoverColor: Colors.red.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
