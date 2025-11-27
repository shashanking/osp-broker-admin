import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

class NewMessageDialog extends ConsumerStatefulWidget {
  const NewMessageDialog({super.key});

  @override
  ConsumerState<NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends ConsumerState<NewMessageDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final apiService = ref.read(baseApiServiceProvider);
      final response = await apiService.get('/user', requireAuth: true);

      final data = response.data['data'] as Map<String, dynamic>?;
      final users = (data?['users'] as List?) ?? [];

      // Filter users by name or email
      final searchQuery = query.trim().toLowerCase();
      final filteredUsers = users.where((user) {
        final fullName = (user['fullName']?.toString() ?? '').toLowerCase();
        final email = (user['email']?.toString() ?? '').toLowerCase();
        return fullName.contains(searchQuery) || email.contains(searchQuery);
      }).toList();

      setState(() {
        _searchResults = filteredUsers.map((user) {
          final userId = user['id']?.toString() ?? '';
          print('DEBUG NewMessageDialog: User ID=$userId, Name=${user['fullName']}, Email=${user['email']}');
          return {
            'id': userId,
            'fullName': user['fullName']?.toString() ?? 'Unknown',
            'email': user['email']?.toString() ?? '',
          };
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching users: ${e.toString()}';
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    final userId = user['id'];
    final userName = user['fullName'];
    print('DEBUG NewMessageDialog: Selected user - ID=$userId, Name=$userName');
    print('DEBUG NewMessageDialog: Navigating to /chat/$userId');
    
    Navigator.pop(context);
    context.push(
      '/chat/$userId?recipientName=${Uri.encodeComponent(userName)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Search Results
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_searchController.text.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Type to search for users...',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No users found',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user['fullName'].isNotEmpty
                              ? user['fullName'][0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        user['fullName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email']),
                      onTap: () => _selectUser(user),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
