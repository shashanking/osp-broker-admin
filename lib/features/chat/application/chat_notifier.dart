import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/chat/application/chat_state.dart';
import 'package:osp_broker_admin/features/chat/domain/chat_message.dart';
import 'package:osp_broker_admin/core/realtime/socket_service.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final BaseApiService apiService;
  final String recipientId;
  final SocketService socketService;
  final String? currentUserId;
  String? _resolvedRecipientId;
  Timer? _typingTimeout;
  Timer? _typingDebounce;

  ChatNotifier({
    required this.apiService,
    required this.recipientId,
    required this.socketService,
    required this.currentUserId,
  }) : super(ChatState());

  Future<String> _getResolvedRecipientId() async {
    if (_resolvedRecipientId != null) {
      return _resolvedRecipientId!;
    }

    _resolvedRecipientId = recipientId;
    return recipientId;
  }

  void init() {
    debugPrint('[ChatNotifier-$recipientId] ========== INIT ==========');
    debugPrint('[ChatNotifier-$recipientId] Current User ID: $currentUserId');
    debugPrint(
        '[ChatNotifier-$recipientId] Socket Connected: ${socketService.isConnected}');

    // Ensure socket is connected first
    socketService.connect().then((_) {
      debugPrint('[ChatNotifier-$recipientId] ✅ Socket connection established');
      
      // Register user with socket
      if (currentUserId != null && currentUserId!.isNotEmpty) {
        socketService.registerUser(currentUserId!);
        debugPrint('[ChatNotifier-$recipientId] ✅ User registered: $currentUserId');
      }
      
      // Register message and typing listeners AFTER connection is established
      socketService.onNewMessage(_handleIncomingMessage);
      socketService.onTypingUpdate(_handleTypingUpdate);
      debugPrint('[ChatNotifier-$recipientId] ✅ Listeners registered');
      
    }).catchError((e) {
      debugPrint('[ChatNotifier-$recipientId] ❌ Socket connection error: $e');
      // Still register listeners even if connection fails (they'll work on reconnect)
      socketService.onNewMessage(_handleIncomingMessage);
      socketService.onTypingUpdate(_handleTypingUpdate);
    });
  }

  void startTyping() async {
    final actualRecipientId = await _getResolvedRecipientId();
    debugPrint('[ChatNotifier-$recipientId] 📝 Starting typing for: $actualRecipientId');
    socketService.startTyping(actualRecipientId);
  }

  void stopTyping() async {
    final actualRecipientId = await _getResolvedRecipientId();
    debugPrint('[ChatNotifier-$recipientId] 🛑 Stopping typing for: $actualRecipientId');
    socketService.stopTyping(actualRecipientId);
  }

  void _handleTypingUpdate(Map<String, dynamic> data) async {
    debugPrint('[ChatNotifier-$recipientId] Typing event: $data');

    final isTyping = data['isTyping'] as bool? ?? false;
    final senderId = data['senderId'] as String? ?? data['userId'] as String?;
    final senderName = data['senderName'] as String? ??
        data['userName'] as String? ??
        data['fullName'] as String?;

    final actualRecipientId = await _getResolvedRecipientId();
    final isForThisThread = senderId == actualRecipientId;

    debugPrint(
        '[ChatNotifier-$recipientId] isTyping: $isTyping, senderId: $senderId, isForThisThread: $isForThisThread');

    if (!isForThisThread) {
      debugPrint('[ChatNotifier-$recipientId] Not for this thread, ignoring');
      return;
    }

    _typingTimeout?.cancel();

    if (senderId != null && senderId != currentUserId && isTyping) {
      final displayName = senderName ?? senderId;
      debugPrint('[ChatNotifier-$recipientId] ✅ SHOWING typing: $displayName');
      state = state.copyWith(typingStatus: '$displayName is typing...');

      _typingTimeout = Timer(const Duration(seconds: 3), () {
        debugPrint('[ChatNotifier-$recipientId] Typing timeout - clearing');
        state = state.copyWith(typingStatus: null);
      });
    } else if (senderId != null && senderId != currentUserId && !isTyping) {
      debugPrint('[ChatNotifier-$recipientId] ✅ HIDING typing');
      state = state.copyWith(typingStatus: null);
    }
  }

  void _handleIncomingMessage(dynamic data) async {
    debugPrint('[ChatNotifier-$recipientId] 📨 _handleIncomingMessage called');
    debugPrint('[ChatNotifier-$recipientId] Data type: ${data.runtimeType}');
    debugPrint('[ChatNotifier-$recipientId] Data: $data');
    
    ChatMessage? incoming;
    if (data is String) {
      final actualRecipientId = await _getResolvedRecipientId();
      incoming = ChatMessage(
        id: 'rt-${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId!,
        recipientId: actualRecipientId,
        content: data,
        isRead: false,
        timestamp: DateTime.now(),
      );
      debugPrint('[ChatNotifier-$recipientId] Created message from String');
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final content = map['content'] as String?;
      if (content == null) return;

      final sender =
          (map['senderId'] ?? map['sender'] ?? map['from']) as String?;
      final recipient =
          (map['recipientId'] ?? map['recipient'] ?? map['to']) as String?;
      final id = (map['id'] ??
              map['_id'] ??
              'rt-${DateTime.now().millisecondsSinceEpoch}')
          .toString();
      final tsStr = map['createdAt'] as String?;
      final ts = tsStr != null
          ? DateTime.tryParse(tsStr) ?? DateTime.now()
          : DateTime.now();
      final read = map['read'] as bool? ?? false;

      incoming = ChatMessage(
        id: id,
        senderId:
            (sender?.isNotEmpty == true) ? sender! : (currentUserId ?? ''),
        recipientId: (recipient?.isNotEmpty == true)
            ? recipient!
            : (currentUserId ?? ''),
        content: content,
        isRead: read,
        timestamp: ts,
      );
    }

    if (incoming == null) {
      debugPrint('[ChatNotifier-$recipientId] ⚠️ incoming is null, returning');
      return;
    }

    final ChatMessage message = incoming;
    final me = (currentUserId ?? '');
    final actualRecipientId = await _getResolvedRecipientId();
    final isForThisThread = (message.senderId == actualRecipientId &&
            message.recipientId == me) ||
        (message.senderId == me && message.recipientId == actualRecipientId);

    debugPrint('[ChatNotifier-$recipientId] Message check:');
    debugPrint('[ChatNotifier-$recipientId]   senderId: ${message.senderId}');
    debugPrint('[ChatNotifier-$recipientId]   recipientId: ${message.recipientId}');
    debugPrint('[ChatNotifier-$recipientId]   currentUserId: $me');
    debugPrint('[ChatNotifier-$recipientId]   actualRecipientId: $actualRecipientId');
    debugPrint('[ChatNotifier-$recipientId]   isForThisThread: $isForThisThread');

    if (me.isNotEmpty && !isForThisThread) {
      debugPrint('[ChatNotifier-$recipientId] ⚠️ Message not for this thread, ignoring');
      return;
    }

    final messages = [...state.messages];
    final existingIndex = messages.indexWhere((m) => m.id == message.id);
    if (existingIndex != -1) {
      debugPrint('[ChatNotifier-$recipientId] ⚠️ Message already exists (id: ${message.id}), ignoring');
      return;
    }

    final recentOptimisticIndex = messages.lastIndexWhere((msg) =>
        msg.id.startsWith('local-') &&
        msg.senderId == message.senderId &&
        msg.recipientId == message.recipientId &&
        msg.content == message.content &&
        message.timestamp.difference(msg.timestamp).inSeconds.abs() < 30);

    if (recentOptimisticIndex != -1) {
      debugPrint('[ChatNotifier-$recipientId] ✅ Replacing optimistic message at index $recentOptimisticIndex');
      messages[recentOptimisticIndex] = message;
    } else {
      debugPrint('[ChatNotifier-$recipientId] ✅ Adding new message to list');
      messages.add(message);
    }

    if (message.senderId != currentUserId) {
      debugPrint('[ChatNotifier-$recipientId] Message from other user, clearing typing status');
      _typingTimeout?.cancel();
      state = state.copyWith(messages: messages, typingStatus: null);
    } else {
      debugPrint('[ChatNotifier-$recipientId] Message from current user');
      state = state.copyWith(messages: messages);
    }
    
    debugPrint('[ChatNotifier-$recipientId] ✅ State updated, total messages: ${messages.length}');
  }

  Future<void> fetchMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final actualRecipientId = await _getResolvedRecipientId();
      debugPrint('[ChatNotifier] fetchMessages - recipientId: $recipientId');
      debugPrint('[ChatNotifier] fetchMessages - actualRecipientId: $actualRecipientId');
      debugPrint('[ChatNotifier] fetchMessages - currentUserId: $currentUserId');

      final response = await apiService.get('/chat/$actualRecipientId');
      debugPrint('[ChatNotifier] fetchMessages - API response received');
      final List<ChatMessage> messages = (response.data['data'] as List)
          .map((m) => ChatMessage(
                id: m['id'] as String,
                senderId: m['senderId'] as String,
                recipientId: m['recipientId'] as String,
                content: m['content'] as String,
                isRead: m['read'] as bool? ?? false,
                timestamp: DateTime.parse(m['createdAt'] as String),
              ))
          .toList();
      debugPrint('[ChatNotifier] ✅ Loaded ${messages.length} messages');
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      debugPrint('[ChatNotifier] ⚠️ Error fetching messages: $e');
      // If 404 or "No messages found", it just means this is a new conversation
      // Don't show an error, just start with empty messages
      if (e.toString().contains('404') || e.toString().contains('No messages found')) {
        debugPrint('[ChatNotifier] ℹ️ No existing messages, starting fresh conversation');
        state = state.copyWith(isLoading: false, messages: [], error: null);
      } else {
        // For other errors, show the error message
        debugPrint('[ChatNotifier] ❌ Unexpected error: $e');
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> sendMessage(String content, String senderId) async {
    try {
      final actualRecipientId = await _getResolvedRecipientId();
      debugPrint('[ChatNotifier] sendMessage - recipientId: $recipientId');
      debugPrint('[ChatNotifier] sendMessage - actualRecipientId: $actualRecipientId');
      debugPrint('[ChatNotifier] sendMessage - senderId: $senderId');
      debugPrint('[ChatNotifier] sendMessage - content: $content');

      final optimistic = ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        senderId: senderId,
        recipientId: actualRecipientId,
        content: content,
        isRead: true,
        timestamp: DateTime.now(),
      );
      debugPrint('[ChatNotifier] 📤 Adding optimistic message: ${optimistic.id}');
      debugPrint('[ChatNotifier] Current messages count: ${state.messages.length}');
      state = state.copyWith(messages: [...state.messages, optimistic]);
      debugPrint('[ChatNotifier] ✅ Optimistic message added, new count: ${state.messages.length}');

      debugPrint('[ChatNotifier] Sending POST to /chat/$actualRecipientId');
      debugPrint('[ChatNotifier] POST data: {content: $content}');
      
      final response = await apiService
          .post('/chat/$actualRecipientId', data: {'content': content});

      if (kDebugMode) {
        debugPrint('[ChatNotifier] Message sent successfully');
        debugPrint('[ChatNotifier] Response data: ${response.data}');
      }

      if (response.data != null && response.data['data'] != null) {
        debugPrint('[ChatNotifier] 📦 Processing server response');
        final serverData = response.data['data'];
        // The server returns {data: {message: {...}}}
        final serverMessage = serverData['message'] ?? serverData;
        debugPrint('[ChatNotifier] Server message: $serverMessage');
        
        final serverId = serverMessage['id']?.toString();
        final serverTimestamp = serverMessage['createdAt'] != null
            ? DateTime.tryParse(serverMessage['createdAt'])
            : null;
        
        debugPrint('[ChatNotifier] Server ID: $serverId');
        debugPrint('[ChatNotifier] Server timestamp: $serverTimestamp');
        
        if (serverId != null) {
          final updatedMessages = state.messages.map((msg) {
            if (msg.id == optimistic.id) {
              return ChatMessage(
                id: serverId,
                senderId: msg.senderId,
                recipientId: msg.recipientId,
                content: msg.content,
                isRead: msg.isRead,
                timestamp: serverTimestamp ?? msg.timestamp,
              );
            }
            return msg;
          }).toList();
          state = state.copyWith(messages: updatedMessages);
          
          debugPrint('[ChatNotifier] ✅ Message updated with server ID: $serverId');
        }
      } else {
        // If no server response data, at least keep the optimistic message
        debugPrint('[ChatNotifier] ⚠️ No server message data in response, keeping optimistic message');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _typingTimeout?.cancel();
    _typingDebounce?.cancel();
    socketService.offNewMessage(_handleIncomingMessage);
    socketService.offTypingUpdate(_handleTypingUpdate);
    super.dispose();
  }
}
