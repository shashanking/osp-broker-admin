import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'dart:async';
import '../widgets/user_stat_card.dart';
import '../widgets/user_users_table.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/user_notifier.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  String _selectedRole = 'All';
  final List<String> _roles = [
    'All',
    'USER',
    'MODERATOR',
    'REPRESENTATIVE',
    'ADMIN'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Fetch users when the page loads
    Future.microtask(
        () => ref.read(userNotifierProvider.notifier).fetchUsers());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          userName: 'Admin',
          userRole: 'Admin',
          notificationCount: '5',
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final userState = ref.watch(userNotifierProvider);
                    final users = userState.users;
                    final totalUsers = users.length;
                    final totalModerators = users
                        .where((u) => u.role.toUpperCase() == 'MODERATOR')
                        .length;
                    final totalRepresentatives = users
                        .where((u) => u.role.toUpperCase() == 'REPRESENTATIVE')
                        .length;
                    final now = DateTime.now();
                    final newUsers = users
                        .where((u) => u.createdAt
                            .isAfter(now.subtract(const Duration(days: 7))))
                        .length;
                    return Row(
                      children: [
                        Expanded(
                          child: UserStatCard(
                            color: const Color(0xFF2196F3),
                            icon: Icons.person_add_alt_1,
                            title: 'Add User',
                            value: '',
                            actionLabel: 'Add',
                            onAction: () {},
                            dense: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: UserStatCard(
                            color: const Color(0xFF3B3E4C),
                            icon: Icons.groups,
                            title: 'Total Users',
                            value: totalUsers.toString(),
                            dense: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: UserStatCard(
                            color: const Color(0xFF7E57C2),
                            icon: Icons.group_add,
                            title: 'New Users',
                            value: newUsers.toString(),
                            dense: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: UserStatCard(
                            color: const Color(0xFFFFB300),
                            icon: Icons.admin_panel_settings,
                            title: 'Representatives',
                            value: totalRepresentatives.toString(),
                            dense: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: UserStatCard(
                            color: Colors.green,
                            icon: Icons.shield,
                            title: 'Moderators',
                            value: totalModerators.toString(),
                            dense: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Role filter
        Row(
          children: [
            Container(
              width: 0.45.sw,
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _roles
                      .map((role) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                role,
                                overflow: TextOverflow.visible,
                              ),
                              selected: _selectedRole == role,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedRole = selected ? role : '';
                                });
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            // Search bar and actions
            Row(
              children: [
                Container(
                  width: 0.2.sw,
                  height: 70,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/memberships');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.card_membership, size: 16),
                    label: const Text('View Memberships'),
                  ),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final userState = ref.watch(userNotifierProvider);
              final users = userState.users;
              final filtered = users.where((u) {
                final query = _searchQuery.toLowerCase();
                final matchesSearch =
                    u.fullName.toLowerCase().contains(query) ||
                        u.email.toLowerCase().contains(query) ||
                        u.phone.contains(query);
                final matchesRole =
                    _selectedRole == 'All' || u.role == _selectedRole;
                return matchesSearch && matchesRole;
              }).toList();
              return UserUsersTable(users: filtered);
            },
          ),
        ),
      ],
    );
  }
}
