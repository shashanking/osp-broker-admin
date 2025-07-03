import 'package:flutter/material.dart';
import 'package:osp_broker_admin/features/forums/presentation/widgets/add_category_dialog.dart';
import '../../domain/forum_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/forum_admin_notifier.dart';

import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';

class ForumCategoriesTable extends StatelessWidget {
  final List<Category> categories;
  final List<MembershipPlanModel> membershipPlans;
  const ForumCategoriesTable(
      {super.key, required this.categories, required this.membershipPlans});

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
              children: [
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
                    child: Text('Category Name',
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
                    child: Text('Moderator',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Plans',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 1,
                    child: Text('Forums',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Created At',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
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
          ...categories.asMap().entries.map((entry) {
            final idx = entry.key;
            final category = entry.value;
            return Column(
              children: [
                _CategoryRow(
                  category: category,
                  membershipPlans: membershipPlans,
                  rowColor:
                      idx % 2 == 0 ? const Color(0xFFF7F9FC) : Colors.white,
                ),
                if (idx != categories.length - 1)
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

class _CategoryRow extends ConsumerWidget {
  final Category category;
  final List<MembershipPlanModel> membershipPlans;
  final Color? rowColor;
  const _CategoryRow(
      {required this.category, required this.membershipPlans, this.rowColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get moderators from Riverpod provider
    final moderators = ref.watch(forumAdminNotifierProvider).moderators;

    String moderatorName = category.moderatorId;
    if (moderators.isNotEmpty) {
      final foundList = moderators.where((m) => m.id == category.moderatorId);
      if (foundList.isNotEmpty && foundList.first.fullName.isNotEmpty)
        moderatorName = foundList.first.fullName;
    }

    String membershipNames = '';
    if (membershipPlans.isNotEmpty && category.membershipAccess.isNotEmpty) {
      membershipNames = category.membershipAccess.map((id) {
        final planList = membershipPlans.where((p) => p.id == id);
        return planList.isNotEmpty ? planList.first.name : id;
      }).join(', ');
    } else if (category.membershipAccess.isEmpty) {
      membershipNames = 'Public';
    }

    String createdAtStr = '';
    try {
      createdAtStr =
          '${category.createdAt.day.toString().padLeft(2, '0')}-${category.createdAt.month.toString().padLeft(2, '0')}-${category.createdAt.year}';
    } catch (_) {
      createdAtStr = '';
    }

    // Count forums in this category
    final forums = ref.watch(forumAdminNotifierProvider).forums;
    final forumCount = forums.where((f) => f.categoryId == category.id).length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Icon
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              child: category.icon.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(category.icon),
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFD7E1F3), width: 2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const CircleAvatar(
                      backgroundColor: Color(0xFFEDF1FA),
                      radius: 22,
                      child: Icon(Icons.category,
                          color: Color(0xFFB0B8C1), size: 22),
                    ),
            ),
          ),
          // Name
          Expanded(
            flex: 2,
            child: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Description
          Expanded(
            flex: 3,
            child: Text(
              category.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          // Moderator
          Expanded(
            flex: 2,
            child: Text(
              moderatorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          // Membership Plans
          Expanded(
            flex: 2,
            child: Text(
              membershipNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          // Forums count
          Expanded(
            flex: 1,
            child: Text(
              forumCount.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ),
          // Created At
          Expanded(
            flex: 2,
            child: Text(
              createdAtStr,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          // Status

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
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AddCategoryDialog(category: category),
                      );
                      if (result == true) {
                        // Force reload to guarantee table reflects update
                        await ref
                            .read(forumAdminNotifierProvider.notifier)
                            .loadCategories();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child:
                          Icon(Icons.edit, color: Colors.blue[600], size: 22),
                    ),
                    hoverColor: Colors.blue.withOpacity(0.08),
                  ),
                ),
                Tooltip(
                  message: 'Delete',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Category'),
                          content: Text(
                              'Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          // ignore: use_build_context_synchronously
                          await ref
                              .read(forumAdminNotifierProvider.notifier)
                              .deleteCategory(category.id);
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Failed to delete category. Please try again.')),
                          );
                        }
                      }
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
    );
  }
}
