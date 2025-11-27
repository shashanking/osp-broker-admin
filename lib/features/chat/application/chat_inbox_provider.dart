import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/core/realtime/socket_service.dart';
import 'package:osp_broker_admin/features/chat/application/chat_inbox_notifier.dart';
import 'package:osp_broker_admin/features/chat/application/chat_inbox_state.dart';
import 'package:osp_broker_admin/features/users/data/repositories/user_repository.dart';

final chatInboxProvider = StateNotifierProvider<ChatInboxNotifier, ChatInboxState>(
  (ref) {
    final apiService = ref.watch(baseApiServiceProvider);
    final socketService = ref.watch(socketServiceProvider);
    final userRepository = UserRepository(apiService);
    
    final notifier = ChatInboxNotifier(
      apiService: apiService,
      userRepository: userRepository,
    );
    
    // Listen for new messages to refresh inbox
    void handleNewMessage(dynamic data) {
      print('DEBUG [INBOX] 🔔 New message event received!');
      print('DEBUG [INBOX] Message data: $data');
      print('DEBUG [INBOX] Socket connected: ${socketService.isConnected}');
      print('DEBUG [INBOX] Refreshing recipients list...');
      notifier.fetchRecipients(isRefresh: true);
    }
    
    print('DEBUG [INBOX] Setting up socket listener');
    print('DEBUG [INBOX] Socket connected: ${socketService.isConnected}');
    socketService.onNewMessage(handleNewMessage);
    
    // Clean up listener when provider is disposed
    ref.onDispose(() {
      print('DEBUG [INBOX] Cleaning up socket listener');
      socketService.offNewMessage(handleNewMessage);
    });
    
    return notifier;
  },
);
