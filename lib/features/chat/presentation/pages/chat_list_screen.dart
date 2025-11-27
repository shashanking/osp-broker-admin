import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:osp_broker_admin/features/chat/application/chat_inbox_provider.dart';
import 'package:osp_broker_admin/features/chat/presentation/widgets/new_message_dialog.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatInboxProvider.notifier).fetchRecipients());
  }

  Future<void> _refresh() async {
    await ref.read(chatInboxProvider.notifier).fetchRecipients(isRefresh: true);
  }

  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => const NewMessageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(chatInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewMessageDialog,
        icon: const Icon(Icons.edit),
        label: const Text('New Message'),
      ),
      body: Column(
        children: [
          // Show loading indicator at top when refreshing
          if (inboxState.isRefreshing)
            const LinearProgressIndicator(),
          
          // Main content
          Expanded(
            child: inboxState.isLoading && inboxState.recipients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : inboxState.error != null && inboxState.recipients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${inboxState.error}'),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : inboxState.recipients.isEmpty
                        ? const Center(
                            child: Text('No conversations yet'),
                          )
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.builder(
                              itemCount: inboxState.recipients.length,
                              itemBuilder: (context, index) {
                                final recipient = inboxState.recipients[index];
                                print('DEBUG UI [$index] ${recipient.recipientName} - ${recipient.content} - ${recipient.createdAt}');
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      recipient.recipientName.isNotEmpty
                                          ? recipient.recipientName[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    recipient.recipientName.isNotEmpty
                                        ? recipient.recipientName
                                        : 'Unknown User',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    recipient.content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    timeago.format(recipient.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () {
                                    context.push(
                                      '/chat/${recipient.recipientId}?recipientName=${Uri.encodeComponent(recipient.recipientName)}',
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
