import 'package:osp_broker_admin/features/chat/domain/chat_recipient.dart';

class ChatInboxState {
  final bool isLoading;
  final bool isRefreshing; // For pull-to-refresh without hiding data
  final List<ChatRecipient> recipients;
  final String? error;

  const ChatInboxState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.recipients = const [],
    this.error,
  });

  ChatInboxState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<ChatRecipient>? recipients,
    String? error,
  }) {
    return ChatInboxState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      recipients: recipients ?? this.recipients,
      error: error,
    );
  }
}
