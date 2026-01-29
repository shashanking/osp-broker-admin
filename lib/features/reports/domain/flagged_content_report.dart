import 'package:flutter/foundation.dart';

@immutable
class FlaggedContentReport {
  final String id;
  final String flaggedBy;
  final String contentType;
  final String reason;
  final bool isDeleted;
  final String? categoryId;
  final String? topicId;
  final String? commentId;
  final String? userId;
  final String? auctionId;
  final String? auctionBidId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlaggedContentReport({
    required this.id,
    required this.flaggedBy,
    required this.contentType,
    required this.reason,
    required this.isDeleted,
    required this.categoryId,
    required this.topicId,
    required this.commentId,
    required this.userId,
    required this.auctionId,
    required this.auctionBidId,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Map) {
      final maybe = value[r'$date'];
      if (maybe is String) {
        return DateTime.tryParse(maybe) ?? DateTime.now();
      }
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory FlaggedContentReport.fromJson(Map<String, dynamic> json) {
    return FlaggedContentReport(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      flaggedBy: json['flaggedBy']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      isDeleted: json['isDeleted'] == true,
      categoryId: json['categoryId']?.toString(),
      topicId: json['topicId']?.toString(),
      commentId: json['commentId']?.toString(),
      userId: json['userId']?.toString(),
      auctionId: json['auctionId']?.toString(),
      auctionBidId: json['auctionBidId']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  String get targetId {
    return topicId ?? commentId ?? userId ?? auctionId ?? auctionBidId ?? '';
  }

  String get targetKind {
    if (topicId != null && topicId!.isNotEmpty) return 'TOPIC';
    if (commentId != null && commentId!.isNotEmpty) return 'COMMENT';
    if (userId != null && userId!.isNotEmpty) return 'USER';
    if (auctionId != null && auctionId!.isNotEmpty) return 'AUCTION';
    if (auctionBidId != null && auctionBidId!.isNotEmpty) return 'AUCTION_BID';
    return 'UNKNOWN';
  }
}
