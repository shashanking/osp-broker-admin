import 'package:freezed_annotation/freezed_annotation.dart';

part 'forum_models.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String description,
    String? moderatorId,
    required String icon,
    @Default(<String>[]) List<String> membershipAccess,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(true) bool isActive,
    Map<String, dynamic>? count,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      moderatorId: json['moderatorId'] as String?,
      icon: json['icon'] as String? ?? '',
      membershipAccess: (json['membership_access'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] as bool? ?? true,
      count: json['count'] as Map<String, dynamic>?,
    );
  }
}

@freezed
class ForumTopicSummary with _$ForumTopicSummary {
  const factory ForumTopicSummary({
    required String forumId,
    @Default(<ForumCommentSummary>[]) List<ForumCommentSummary> comments,
  }) = _ForumTopicSummary;

  factory ForumTopicSummary.fromJson(Map<String, dynamic> json) {
    return ForumTopicSummary(
      forumId: json['forumId'] as String? ?? '',
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) =>
                  ForumCommentSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

@freezed
class ForumCommentSummary with _$ForumCommentSummary {
  const factory ForumCommentSummary({
    required String topicId,
  }) = _ForumCommentSummary;

  factory ForumCommentSummary.fromJson(Map<String, dynamic> json) {
    return ForumCommentSummary(
      topicId: json['topicId'] as String? ?? '',
    );
  }
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
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<ForumTopicSummary>[]) List<ForumTopicSummary> topics,
    @Default(<String, dynamic>{}) Map<String, dynamic> count,
  }) = _Forum;

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      author: json['author'] as String? ?? '',
      comments: json['comments'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      topics: (json['topics'] as List<dynamic>?)
              ?.map(
                  (e) => ForumTopicSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['_count'] as Map<String, dynamic>? ?? {},
    );
  }
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
    @Default(false) bool isClosed,
    @Default([]) List<dynamic> attachments,
  }) = _Topic;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      forumId: json['forumId'] as String? ?? '',
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      comments: json['comments'] as List<dynamic>? ?? [],
      isClosed: json['isClosed'] as bool? ?? false,
      attachments: json['attachments'] as List<dynamic>? ?? [],
    );
  }
}

@freezed
class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String title,
    required String description,
    required String createdAt,
    required String updatedAt,
  }) = _Announcement;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String title,
    required String description,
    required String date,
    required String createdAt,
    required String updatedAt,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

@freezed
class Poll with _$Poll {
  const factory Poll({
    required String id,
    required String question,
    required List<String> options,
    required String createdAt,
    required String updatedAt,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String comment,
    required String author,
    required String topicId,
    required String commenterId,
    required DateTime createdAt,
    required DateTime updatedAt,
    CommentTopic? topic,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      author: json['author'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      commenterId: json['commenterId'] as String? ?? '',
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      topic: json['topic'] == null
          ? null
          : CommentTopic.fromJson(json['topic'] as Map<String, dynamic>),
    );
  }
}

@freezed
class CommentTopic with _$CommentTopic {
  const factory CommentTopic({
    required String id,
    required String title,
  }) = _CommentTopic;

  factory CommentTopic.fromJson(Map<String, dynamic> json) {
    return CommentTopic(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}
