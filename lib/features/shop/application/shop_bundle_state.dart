import '../domain/shop_bundle_model.dart';

class ShopBundleState {
  final List<ShopBundleModel> bundles;
  final bool isLoading;
  final String? error;

  const ShopBundleState({
    this.bundles = const [],
    this.isLoading = false,
    this.error,
  });

  ShopBundleState copyWith({
    List<ShopBundleModel>? bundles,
    bool? isLoading,
    String? error,
  }) {
    return ShopBundleState(
      bundles: bundles ?? this.bundles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
