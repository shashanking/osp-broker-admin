import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../domain/shop_pin_model.dart';
import 'shop_pin_state.dart';

final shopPinNotifierProvider =
    StateNotifierProvider<ShopPinNotifier, ShopPinState>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return ShopPinNotifier(api);
});

class ShopPinNotifier extends StateNotifier<ShopPinState> {
  final BaseApiService _api;

  ShopPinNotifier(this._api) : super(const ShopPinState());

  Future<void> fetchPins() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/shop/pin', requireAuth: true);
      final rawPins = (response.data['data']?['pins'] as List?) ?? const [];
      final pins = rawPins
          .whereType<Map>()
          .map((e) => ShopPinModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(pins: pins, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createPin({
    required String color,
    required int price,
    required int duration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/pin',
        requireAuth: true,
        data: {
          'color': color,
          'price': price,
          'duration': duration,
        },
      );
      await fetchPins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updatePin({
    required String id,
    required String color,
    required int price,
    required int duration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(
        '/shop/pin/$id',
        requireAuth: true,
        data: {
          'color': color,
          'price': price,
          'duration': duration,
        },
      );
      await fetchPins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> softDeletePin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/pin/softDelete/$id',
        requireAuth: true,
      );
      await fetchPins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deletePin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete(
        '/shop/pin/$id',
        requireAuth: true,
      );
      await fetchPins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
