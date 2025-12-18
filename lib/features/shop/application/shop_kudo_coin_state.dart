import '../domain/shop_kudo_coin_model.dart';

class ShopKudoCoinState {
  final List<ShopKudoCoinModel> kudoCoins;
  final bool isLoading;
  final String? error;

  const ShopKudoCoinState({
    this.kudoCoins = const [],
    this.isLoading = false,
    this.error,
  });

  ShopKudoCoinState copyWith({
    List<ShopKudoCoinModel>? kudoCoins,
    bool? isLoading,
    String? error,
  }) {
    return ShopKudoCoinState(
      kudoCoins: kudoCoins ?? this.kudoCoins,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
