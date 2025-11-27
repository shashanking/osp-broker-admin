import 'package:osp_broker_admin/features/chat/domain/chat_message.dart';

class ChatState {
  final bool isLoading;
  final List<ChatMessage> messages;
  final String? error;
  final String? typingStatus;

  ChatState({
    this.isLoading = false,
    this.messages = const [],
    this.typingStatus,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
    Object? typingStatus = const _Sentinel(),
    Object? error = const _Sentinel(),
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      typingStatus: typingStatus is _Sentinel ? this.typingStatus : typingStatus as String?,
      error: error is _Sentinel ? this.error : error as String?,
    );
  }
}

// Sentinel class to distinguish between "not provided" and "explicitly null"
class _Sentinel {
  const _Sentinel();
}
