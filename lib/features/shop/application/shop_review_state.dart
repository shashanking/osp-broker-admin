import '../domain/shop_review_model.dart';

class ShopReviewState {
  final List<ShopReviewModel> reviews;
  final bool isLoading;
  final String? error;

  const ShopReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
  });

  ShopReviewState copyWith({
    List<ShopReviewModel>? reviews,
    bool? isLoading,
    String? error,
  }) {
    return ShopReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
