import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/api_urls.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/auction/domain/auction.dart';
import 'package:osp_broker_admin/features/auction/domain/auction_category.dart';
import 'package:osp_broker_admin/features/auction/domain/auction_state.dart';
import 'package:osp_broker_admin/features/auction/domain/bid.dart';

final auctionNotifierProvider =
    StateNotifierProvider<AuctionNotifier, AuctionState>((ref) {
  final apiService = ref.watch(baseApiServiceProvider);
  return AuctionNotifier(apiService);
});

class AuctionNotifier extends StateNotifier<AuctionState> {
  final BaseApiService _apiService;

  AuctionNotifier(this._apiService) : super(AuctionState.initial()) {
    loadCategories();
    loadAuctions();
  }

  // Load auction categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      final response = await _apiService.get(ApiUrls.auctionCategories);
      final data = response.data['data'] as Map<String, dynamic>;
      final categories = (data['categories'] as List<dynamic>? ?? [])
          .map((json) => AuctionCategory.fromJson(json))
          .toList();
      state =
          state.copyWith(categories: categories, isLoadingCategories: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Load auctions
  Future<void> loadAuctions() async {
    state = state.copyWith(isLoadingAuctions: true, error: null);
    try {
      final response = await _apiService.get(ApiUrls.auctions);
      final data = response.data['data'] as Map<String, dynamic>;
      final auctionsData = data['auctions'] as Map<String, dynamic>;

      final auctions = (auctionsData['allAuctions'] as List<dynamic>? ?? [])
          .map((json) => Auction.fromJson(json))
          .toList();
      final pinnedAuctions =
          (auctionsData['pinnedAuctions'] as List<dynamic>? ?? [])
              .map((json) => Auction.fromJson(json))
              .toList();
      state = state.copyWith(
        auctions: auctions,
        pinnedAuctions: pinnedAuctions,
        isLoadingAuctions: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAuctions: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Create auction category
  Future<AuctionCategory> createCategory({
    required String name,
    required String description,
  }) async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      final response = await _apiService.post(
        ApiUrls.auctionCategories,
        data: {
          'name': name,
          'description': description,
        },
      );
      final newCategory =
          AuctionCategory.fromJson(response.data['data']['category']);
      state = state.copyWith(
        categories: [...state.categories, newCategory],
        isLoadingCategories: false,
      );
      return newCategory;
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Update auction category
  Future<AuctionCategory> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      final response = await _apiService.put(
        '${ApiUrls.auctionCategories}/$id',
        data: {
          'name': name,
          'description': description,
        },
      );
      final updatedCategory =
          AuctionCategory.fromJson(response.data['data']['category']);
      final updatedCategories = state.categories.map((category) {
        return category.id == id ? updatedCategory : category;
      }).toList();
      state = state.copyWith(
        categories: updatedCategories,
        isLoadingCategories: false,
      );
      return updatedCategory;
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Delete auction category
  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      await _apiService.delete('${ApiUrls.auctionCategories}/$id');
      final updatedCategories =
          state.categories.where((category) => category.id != id).toList();
      state = state.copyWith(
        categories: updatedCategories,
        isLoadingCategories: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Approve auction
  Future<Auction> approveAuction(String id) async {
    state = state.copyWith(isLoadingAuctions: true, error: null);
    try {
      final response = await _apiService.put(
        '${ApiUrls.auctions}/approve/$id',
        data: {'approved': true},
      );
      final updatedAuction = Auction.fromJson(response.data['data']['auction']);
      final updatedAuctions = state.auctions.map((auction) {
        return auction.id == id ? updatedAuction : auction;
      }).toList();
      state = state.copyWith(
        auctions: updatedAuctions,
        isLoadingAuctions: false,
      );
      return updatedAuction;
    } catch (e) {
      state = state.copyWith(
        isLoadingAuctions: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Create auction
  Future<Auction> createAuction({
    required String title,
    required String description,
    required List<String> categoryIds,
    required String timeFrame,
    List<String>? files, // File paths or URLs for uploaded files
    int? startingBid,
  }) async {
    state = state.copyWith(isLoadingAuctions: true, error: null);
    try {
      // Get authenticated user ID
      final userId = _apiService.userId;
      if (userId == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Prepare the request data
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'categoryIds': categoryIds,
        'timeFrame': timeFrame, // Already in ISO-8601 format from frontend
        'userId': userId,
      };

      // Add files if provided (for future implementation)
      if (files != null && files.isNotEmpty) {
        data['files'] = files;
      }

      // Add starting bid if provided
      if (startingBid != null) {
        data['starting_bid'] = startingBid;
      }

      final response = await _apiService.post(
        ApiUrls.auctions,
        data: data,
      );

      final newAuction = Auction.fromJson(response.data['data']['auction']);
      state = state.copyWith(
        auctions: [...state.auctions, newAuction],
        isLoadingAuctions: false,
      );
      return newAuction;
    } catch (e) {
      state = state.copyWith(
        isLoadingAuctions: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Soft delete auction (sets isDeleted flag)
  Future<void> softDeleteAuction(String id) async {
    state = state.copyWith(isLoadingAuctions: true, error: null);
    try {
      await _apiService.post(
        '${ApiUrls.auctions}/softDelete/$id',
      );
      // Reload auctions to reflect the change
      await loadAuctions();
    } catch (e) {
      state = state.copyWith(
        isLoadingAuctions: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Hard delete auction (permanently removes from database)
  Future<void> hardDeleteAuction(String id) async {
    state = state.copyWith(isLoadingAuctions: true, error: null);
    try {
      await _apiService.delete('${ApiUrls.auctions}/$id');
      final updatedAuctions =
          state.auctions.where((auction) => auction.id != id).toList();
      state = state.copyWith(
        auctions: updatedAuctions,
        isLoadingAuctions: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAuctions: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // Fetch single auction by ID
  Future<Auction?> fetchAuctionById(String id) async {
    state = state.copyWith(isLoadingAuctions: true, error: null);
    try {
      final response = await _apiService.get('${ApiUrls.auctions}/$id');
      final auction = Auction.fromJson(response.data['data']['auction']);
      state = state.copyWith(
        selectedAuction: auction,
        isLoadingAuctions: false,
      );
      return auction;
    } catch (e) {
      state = state.copyWith(
        isLoadingAuctions: false,
        error: e.toString(),
      );
      return null;
    }
  }

  // Load bids for an auction
  Future<void> loadBids(String auctionId) async {
    state = state.copyWith(isLoadingBids: true, error: null);
    try {
      final response = await _apiService.get(
        '/auction/bid/auctionId/$auctionId',
      );

      final responseData = response.data as Map<String, dynamic>;

      // Handle case where no bids exist or server returns error
      if (responseData['success'] == true && responseData['data'] != null) {
        final bidsData = responseData['data']['bids'] as List<dynamic>? ?? [];
        final bids = bidsData.map((json) => Bid.fromJson(json)).toList();
        state = state.copyWith(bids: bids, isLoadingBids: false);
      } else {
        // No bids found or error - set empty list
        state = state.copyWith(bids: [], isLoadingBids: false);
      }
    } catch (e) {
      // Handle error gracefully - set empty bids list
      state = state.copyWith(bids: [], isLoadingBids: false, error: null);
    }
  }

  // Select winner for an auction
  Future<Map<String, dynamic>> selectWinner({
    required String auctionId,
    required String bidId,
    required String userId,
  }) async {
    try {
      final result = await _apiService.put(
        '/auction/bid/$auctionId/select-winner/$bidId',
        data: {
          'userId': userId,
        },
      );

      // Reload bids after selecting winner to update matched status
      await loadBids(auctionId);

      return result.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await loadCategories();
    await loadAuctions();
  }
}
