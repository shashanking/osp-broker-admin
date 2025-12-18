import '../domain/shop_pin_model.dart';

class ShopPinState {
  final List<ShopPinModel> pins;
  final bool isLoading;
  final String? error;

  const ShopPinState({
    this.pins = const [],
    this.isLoading = false,
    this.error,
  });

  ShopPinState copyWith({
    List<ShopPinModel>? pins,
    bool? isLoading,
    String? error,
  }) {
    return ShopPinState(
      pins: pins ?? this.pins,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
