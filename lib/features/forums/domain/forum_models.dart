import 'package:freezed_annotation/freezed_annotation.dart';

part 'forum_models.freezed.dart';
part 'forum_models.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String description,
    required String moderatorId,
    required String icon,
    @Default(<String>[]) @JsonKey(name: 'membership_access') List<String> membershipAccess,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(true) bool isActive,
    Map<String, dynamic>? count,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}

@freezed
class Forum with _$Forum {
  const factory Forum({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required String userId,
    required String author,
    required int comments,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<dynamic> topics,
    @JsonKey(name: '_count') required Map<String, dynamic> count,
  }) = _Forum;

  factory Forum.fromJson(Map<String, dynamic> json) => _$ForumFromJson(json);
}

@freezed
class Topic with _$Topic {
  const factory Topic({
    required String id,
    required String title,
    required String content,
    required String author,
    required int views,
    required String forumId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<dynamic> comments,
  }) = _Topic;

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
}
