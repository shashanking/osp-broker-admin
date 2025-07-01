import 'package:flutter/material.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';

import '../../data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserUsersTable extends StatefulWidget {
  final List<UserModel> users;
  const UserUsersTable({Key? key, required this.users}) : super(key: key);

  @override
  State<UserUsersTable> createState() => _UserUsersTableState();
}

class _UserUsersTableState extends State<UserUsersTable> {
  String? sortColumn = 'created';
  bool sortAscending = false;

  List<UserModel> get sortedUsers {
    List<UserModel> sorted = List.from(widget.users);
    if (sortColumn == null) return sorted;
    sorted.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'name':
          cmp = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
          break;
        case 'email':
          cmp = a.email.toLowerCase().compareTo(b.email.toLowerCase());
          break;
        case 'phone':
          cmp = a.phone.compareTo(b.phone);
          break;
        case 'role':
          cmp = a.role.compareTo(b.role);
          break;
        case 'status':
          cmp = a.isBanned.toString().compareTo(b.isBanned.toString());
          break;
        case 'created':
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          cmp = 0;
      }
      return sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  void onSort(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }
    });
  }

  Widget _headerCell(String label, String columnKey) {
    final isActive = sortColumn == columnKey;
    return InkWell(
      onTap: () => onSort(columnKey),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 13)),
          if (isActive)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: Colors.black54,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: SizedBox(
        height: 440, // Adjust as needed to fit your layout
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header row
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 32,
                        child: Checkbox(value: false, onChanged: null)),
                    Expanded(flex: 2, child: _headerCell('Name', 'name')),
                    Expanded(flex: 2, child: _headerCell('Email', 'email')),
                    Expanded(flex: 2, child: _headerCell('Phone', 'phone')),
                    Expanded(flex: 1, child: _headerCell('Role', 'role')),
                    Expanded(
                        flex: 1,
                        child: _headerCell('Is Moderator', 'isModerator')),
                    Expanded(flex: 2, child: _headerCell('Created', 'created')),
                    const Expanded(
                        flex: 2,
                        child: Text('Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 13),
                            textAlign: TextAlign.left)),
                  ],
                ),
              ),
              const Divider(height: 0),
              if (sortedUsers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('No users found.'),
                )
              else
                ...sortedUsers.map((user) => _UserRow(user: user)).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  final UserModel user;
  const _UserRow({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Row(
        children: [
          SizedBox(width: 32, child: Checkbox(value: false, onChanged: null)),
          Expanded(flex: 2, child: Text(user.fullName)),
          Expanded(flex: 2, child: Text(user.email)),
          Expanded(flex: 2, child: Text(user.phone)),
          Expanded(flex: 1, child: Text(user.role)),
          Expanded(flex: 1, child: _StatusChip(isBanned: user.isBanned)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final updating = ref.watch(userNotifierProvider.select((s) => s.updatingUserIds.contains(user.id)));
                    if (updating) {
                      return SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return user.role.trim().toLowerCase() == 'moderator'
                        ? Tooltip(
                            message: 'Remove Moderator',
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(36, 36),
                                padding: EdgeInsets.zero,
                                side: const BorderSide(color: Colors.orange),
                              ),
                              onPressed: updating
                                  ? null
                                  : () {
                                      ref.read(userNotifierProvider.notifier).removeModerator(user.id);
                                    },
                              child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange),
                            ),
                          )
                        : Tooltip(
                            message: 'Make Moderator',
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(36, 36),
                                padding: EdgeInsets.zero,
                                side: const BorderSide(color: Colors.blue),
                              ),
                              onPressed: updating
                                  ? null
                                  : () {
                                      ref.read(userNotifierProvider.notifier).assignModerator(user.id);
                                    },
                              child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                            ),
                          );
                  },
                ),
              ],
            ),
          ),
          Expanded(
              flex: 2,
              child: Text('${user.createdAt.toLocal()}'.split(' ')[0])),
          Expanded(
              flex: 2,
              child: Row(
                children: [
                  Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Ban'),
                            content: Text(
                                'Are you sure you want to ${user.isBanned ? 'unban' : 'ban'} ${user.fullName}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await ref
                                      .read(userNotifierProvider.notifier)
                                      .banUser(user.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      user.isBanned ? Colors.green : Colors.red,
                                ),
                                child: Text(
                                    user.isBanned ? 'Unban User' : 'Ban User',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            user.isBanned ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(40, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(user.isBanned ? 'Unban' : 'Ban',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white)),
                    ),
                    child: Text(user.isBanned ? 'Unban' : 'Ban',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) => ElevatedButton(
                      onPressed: () {
                        // Show confirmation dialog for delete
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete User'),
                            content: Text(
                                'Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await ref
                                      .read(userNotifierProvider.notifier)
                                      .deleteUser(user.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(40, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isBanned;
  const _StatusChip({Key? key, required this.isBanned}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isBanned ? 'Banned' : 'Active',
          style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: isBanned ? Colors.red : Colors.green,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}
