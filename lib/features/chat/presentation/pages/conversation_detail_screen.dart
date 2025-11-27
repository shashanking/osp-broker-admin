import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/chat/domain/chat_message.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;

  const ConversationDetailScreen({
    super.key,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
  });

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  bool _isLoading = true;
  List<ChatMessage> _messages = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(baseApiServiceProvider);
      
      // Fetch all messages and filter for this conversation
      final res = await apiService.get('/admin/getALLIndividualChats');
      final list = (res.data['data'] as List?) ?? const [];

      final messages = <ChatMessage>[];

      for (final item in list.whereType<Map>()) {
        final json = item as Map<String, dynamic>;
        final senderId = json['senderId']?.toString() ?? '';
        final recipientId = json['recipientId']?.toString() ?? '';

        // Filter messages between these two users
        if ((senderId == widget.user1Id && recipientId == widget.user2Id) ||
            (senderId == widget.user2Id && recipientId == widget.user1Id)) {
          try {
            final message = ChatMessage(
              id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
              senderId: senderId,
              recipientId: recipientId,
              content: json['content']?.toString() ?? '',
              timestamp: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
              isRead: json['read'] as bool? ?? false,
            );
            messages.add(message);
          } catch (e) {
            print('DEBUG Error parsing message: $e');
          }
        }
      }

      // Sort by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.user1Name} ↔ ${widget.user2Name}'),
            Text(
              '${_messages.length} messages',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMessages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No messages in this conversation',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser1 = message.senderId == widget.user1Id;
                        final senderName = isUser1 ? widget.user1Name : widget.user2Name;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                backgroundColor:
                                    isUser1 ? Colors.blue : Colors.green,
                                child: Text(
                                  senderName.isNotEmpty
                                      ? senderName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Message content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeago.format(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (!message.isRead) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Unread',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isUser1
                                            ? Colors.blue[50]
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isUser1
                                              ? Colors.blue[200]!
                                              : Colors.green[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        message.content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
