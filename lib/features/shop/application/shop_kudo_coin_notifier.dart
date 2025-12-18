import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../domain/shop_kudo_coin_model.dart';
import 'shop_kudo_coin_state.dart';

final shopKudoCoinNotifierProvider =
    StateNotifierProvider<ShopKudoCoinNotifier, ShopKudoCoinState>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return ShopKudoCoinNotifier(api);
});

class ShopKudoCoinNotifier extends StateNotifier<ShopKudoCoinState> {
  final BaseApiService _api;

  ShopKudoCoinNotifier(this._api) : super(const ShopKudoCoinState());

  Future<void> fetchKudoCoins() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/shop/kudoCoin', requireAuth: true);
      final raw = (response.data['data']?['kudoCoins'] as List?) ?? const [];
      final kudoCoins = raw
          .whereType<Map>()
          .map((e) => ShopKudoCoinModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state =
          state.copyWith(kudoCoins: kudoCoins, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createKudoCoin({
    required int price,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/kudoCoin',
        requireAuth: true,
        data: {
          'price': price,
          'description': description,
        },
      );
      await fetchKudoCoins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateKudoCoin({
    required String id,
    required int price,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(
        '/shop/kudoCoin/$id',
        requireAuth: true,
        data: {
          'price': price,
          'description': description,
        },
      );
      await fetchKudoCoins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> softDeleteKudoCoin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/shop/kudoCoin/softDelete/$id', requireAuth: true);
      await fetchKudoCoins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteKudoCoin(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('/shop/kudoCoin/$id', requireAuth: true);
      await fetchKudoCoins();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
