import '../domain/shop_badge_model.dart';

class ShopBadgeState {
  final List<ShopBadgeModel> badges;
  final bool isLoading;
  final String? error;

  const ShopBadgeState({
    this.badges = const [],
    this.isLoading = false,
    this.error,
  });

  ShopBadgeState copyWith({
    List<ShopBadgeModel>? badges,
    bool? isLoading,
    String? error,
  }) {
    return ShopBadgeState(
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
