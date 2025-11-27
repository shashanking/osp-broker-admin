import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/core/realtime/socket_service.dart';
import 'package:osp_broker_admin/features/chat/application/chat_notifier.dart';
import 'package:osp_broker_admin/features/chat/application/chat_state.dart';

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, recipientId) {
    final apiService = ref.watch(baseApiServiceProvider);
    final socketService = ref.watch(socketServiceProvider);
    
    // Get current user ID from Hive
    String? currentUserId;
    if (Hive.isBoxOpen('auth')) {
      final box = Hive.box('auth');
      currentUserId = box.get('userId') as String?;
    }

    final notifier = ChatNotifier(
      apiService: apiService,
      recipientId: recipientId,
      socketService: socketService,
      currentUserId: currentUserId,
    );

    notifier.init();
    notifier.fetchMessages();

    return notifier;
  },
);
