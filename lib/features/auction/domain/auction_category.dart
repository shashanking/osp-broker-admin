import 'package:freezed_annotation/freezed_annotation.dart';
import 'auction.dart';

part 'auction_category.freezed.dart';
part 'auction_category.g.dart';

@freezed
class AuctionCategory with _$AuctionCategory {
  const factory AuctionCategory({
    required String id,
    required String name,
    required String description,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<Auction> auctions,
  }) = _AuctionCategory;

  factory AuctionCategory.fromJson(Map<String, dynamic> json) =>
      _$AuctionCategoryFromJson(json);
}
