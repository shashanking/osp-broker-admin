import 'package:freezed_annotation/freezed_annotation.dart';

part 'auction.freezed.dart';
part 'auction.g.dart';

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
    @JsonKey(name: 'starting_bid') @Default(0) double startingBid,
    @JsonKey(name: 'bidding_type') @Default('INCREASE') String biddingType,
  }) = _Auction;

  factory Auction.fromJson(Map<String, dynamic> json) =>
      _$AuctionFromJson(json);
}

extension AuctionExtension on Auction {
  // Helper to get media URLs from media objects
  List<String> get mediaUrls {
    return media.map((item) {
      if (item is String) {
        return item;
      } else if (item is Map<String, dynamic>) {
        return item['url'] as String? ?? '';
      }
      return '';
    }).where((url) => url.isNotEmpty).toList();
  }
}
