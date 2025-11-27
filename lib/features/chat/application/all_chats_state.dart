import 'package:osp_broker_admin/features/chat/domain/individual_chat.dart';

class AllChatsState {
  final bool isLoading;
  final bool isRefreshing;
  final List<IndividualChat> chats;
  final String? error;

  const AllChatsState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.chats = const [],
    this.error,
  });

  AllChatsState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<IndividualChat>? chats,
    String? error,
  }) {
    return AllChatsState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      chats: chats ?? this.chats,
      error: error,
    );
  }
}
