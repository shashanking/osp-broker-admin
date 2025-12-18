import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../domain/shop_badge_model.dart';
import 'shop_badge_state.dart';

final shopBadgeNotifierProvider =
    StateNotifierProvider<ShopBadgeNotifier, ShopBadgeState>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return ShopBadgeNotifier(api);
});

class ShopBadgeNotifier extends StateNotifier<ShopBadgeState> {
  final BaseApiService _api;

  ShopBadgeNotifier(this._api) : super(const ShopBadgeState());

  Future<void> fetchBadges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/shop/badge', requireAuth: true);
      final raw = (response.data['data']?['badges'] as List?) ?? const [];
      final badges = raw
          .whereType<Map>()
          .map((e) => ShopBadgeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(badges: badges, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createBadge({
    required String name,
    required String description,
    required int price,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/badge',
        requireAuth: true,
        data: {
          'name': name,
          'description': description,
          'price': price,
        },
      );
      await fetchBadges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBadge({
    required String id,
    required String name,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(
        '/shop/badge/$id',
        requireAuth: true,
        data: {
          'name': name,
          'description': description,
        },
      );
      await fetchBadges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> softDeleteBadge(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/shop/badge/softDelete/$id', requireAuth: true);
      await fetchBadges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteBadge(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('/shop/badge/$id', requireAuth: true);
      await fetchBadges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteAllBadges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete('/shop/badge', requireAuth: true);
      await fetchBadges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
