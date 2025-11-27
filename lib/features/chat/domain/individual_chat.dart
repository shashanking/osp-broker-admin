import 'package:freezed_annotation/freezed_annotation.dart';

part 'individual_chat.freezed.dart';
part 'individual_chat.g.dart';

@freezed
class IndividualChat with _$IndividualChat {
  const factory IndividualChat({
    required String id,
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default(0) int unreadCount,
  }) = _IndividualChat;

  factory IndividualChat.fromJson(Map<String, dynamic> json) =>
      _$IndividualChatFromJson(json);
}
