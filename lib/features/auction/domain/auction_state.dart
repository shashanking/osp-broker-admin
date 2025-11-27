import 'package:freezed_annotation/freezed_annotation.dart';
import 'auction.dart';
import 'auction_category.dart';
import 'bid.dart';

part 'auction_state.freezed.dart';

@freezed
class AuctionState with _$AuctionState {
  const factory AuctionState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingCategories,
    @Default(false) bool isLoadingAuctions,
    @Default(false) bool isLoadingBids,
    String? error,
    @Default([]) List<AuctionCategory> categories,
    @Default([]) List<Auction> auctions,
    @Default([]) List<Auction> pinnedAuctions,
    @Default([]) List<Bid> bids,
    AuctionCategory? selectedCategory,
    Auction? selectedAuction,
  }) = _AuctionState;

  factory AuctionState.initial() => const AuctionState();
}
