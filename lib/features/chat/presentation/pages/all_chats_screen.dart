import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/utils/role_utils.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';
import 'package:osp_broker_admin/features/chat/application/all_chats_provider.dart';
import 'package:osp_broker_admin/features/chat/presentation/pages/conversation_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class AllChatsScreen extends ConsumerStatefulWidget {
  const AllChatsScreen({super.key});

  @override
  ConsumerState<AllChatsScreen> createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends ConsumerState<AllChatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(allChatsProvider.notifier).fetchAllChats());
  }

  Future<void> _refresh() async {
    await ref.read(allChatsProvider.notifier).fetchAllChats(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final allChatsState = ref.watch(allChatsProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Individual Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Show loading indicator at top when refreshing
          if (allChatsState.isRefreshing) const LinearProgressIndicator(),

          // Main content
          Expanded(
            child: allChatsState.isLoading && allChatsState.chats.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : allChatsState.error != null && allChatsState.chats.isEmpty
                    ? (() {
                        // Show a clean placeholder for MODERATOR on 403
                        final isModerator = authState.maybeWhen(
                          authenticated: (_, user) => userHasRole(
                              Map<String, dynamic>.from(user), 'MODERATOR'),
                          orElse: () => false,
                        );
                        if (isModerator &&
                            allChatsState.error.toString().contains('403')) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Access Restricted',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Only administrators can view all individual chats.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        // Fallback to normal error display for ADMIN or other errors
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('Error: ${allChatsState.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refresh,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      })()
                    : allChatsState.chats.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No chats found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.separated(
                              itemCount: allChatsState.chats.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final chat = allChatsState.chats[index];
                                return ListTile(
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Text(
                                          chat.user1Name?.isNotEmpty == true
                                              ? chat.user1Name![0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.green,
                                          child: Text(
                                            chat.user2Name?.isNotEmpty == true
                                                ? chat.user2Name![0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    '${chat.user1Name ?? 'User 1'} ↔ ${chat.user2Name ?? 'User 2'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: chat.lastMessage != null
                                      ? Text(
                                          chat.lastMessage!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : const Text(
                                          'No messages yet',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (chat.lastMessageTime != null)
                                        Text(
                                          timeago.format(chat.lastMessageTime!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      if (chat.unreadCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${chat.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Navigate to conversation detail screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConversationDetailScreen(
                                          user1Id: chat.user1Id,
                                          user2Id: chat.user2Id,
                                          user1Name: chat.user1Name ?? 'User 1',
                                          user2Name: chat.user2Name ?? 'User 2',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
