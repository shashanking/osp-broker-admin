import 'package:freezed_annotation/freezed_annotation.dart';

part 'auction.freezed.dart';
part 'auction.g.dart';

Map<String, dynamic> _normalizeAuctionJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);

  // Normalize snake_case keys from backend to match model fields
  normalized['startingBid'] ??= normalized['starting_bid'];
  normalized['biddingType'] ??= normalized['bidding_type'];

  // Backend often uses _id while client expects id
  normalized['id'] ??= normalized['_id'];

  // Strings - avoid `null as String` crashes
  normalized['title'] ??= '';
  normalized['description'] ??= '';
  normalized['userId'] ??=
      normalized['user']?['id'] ?? normalized['user']?['_id'] ?? '';

  // Lists
  normalized['categoryIds'] ??= const <dynamic>[];

  // Dates
  normalized['timeFrame'] ??=
      normalized['createdAt'] ?? DateTime.now().toIso8601String();
  normalized['createdAt'] ??= DateTime.now().toIso8601String();
  normalized['updatedAt'] ??= normalized['createdAt'];

  // Misc
  normalized['media'] ??= const <dynamic>[];

  return normalized;
}

@freezed
class Auction with _$Auction {
  const factory Auction({
    required String id,
    required String title,
    required String description,
    required List<String> categoryIds,
    required DateTime timeFrame,
    @Default(false) bool approved,
    required String userId,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<dynamic> media,
    @Default(0) double startingBid,
    @Default('INCREASE') String biddingType,
  }) = _Auction;

  factory Auction.fromJson(Map<String, dynamic> json) =>
      _$AuctionFromJson(_normalizeAuctionJson(json));
}

extension AuctionExtension on Auction {
  // Helper to get media URLs from media objects
  List<String> get mediaUrls {
    return media
        .map((item) {
          if (item is String) {
            return item;
          } else if (item is Map<String, dynamic>) {
            return item['url'] as String? ?? '';
          }
          return '';
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
