import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../domain/shop_review_model.dart';
import 'shop_review_state.dart';

final shopReviewNotifierProvider =
    StateNotifierProvider<ShopReviewNotifier, ShopReviewState>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return ShopReviewNotifier(api);
});

class ShopReviewNotifier extends StateNotifier<ShopReviewState> {
  final BaseApiService _api;

  ShopReviewNotifier(this._api) : super(const ShopReviewState());

  Future<void> fetchReviews() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/shop/reviews', requireAuth: true);
      final raw = (response.data['data']?['reviews'] as List?) ?? const [];
      final reviews = raw
          .whereType<Map>()
          .map((e) => ShopReviewModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(reviews: reviews, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createReview({
    required String itemId,
    required int rating,
    required String text,
    required String reviewerName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/reviews',
        requireAuth: true,
        data: {
          'itemId': itemId,
          'rating': rating,
          'text': text,
          'reviewerName': reviewerName,
        },
      );
      await fetchReviews();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteReview(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('/shop/reviews/$id', requireAuth: true);
      await fetchReviews();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
