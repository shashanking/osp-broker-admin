import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../domain/shop_bundle_model.dart';
import 'shop_bundle_state.dart';

final shopBundleNotifierProvider =
    StateNotifierProvider<ShopBundleNotifier, ShopBundleState>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return ShopBundleNotifier(api);
});

class ShopBundleNotifier extends StateNotifier<ShopBundleState> {
  final BaseApiService _api;

  ShopBundleNotifier(this._api) : super(const ShopBundleState());

  Future<void> fetchBundles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/shop/pin-bundle', requireAuth: true);
      final rawBundles =
          (response.data['data']?['bundles'] as List?) ?? const [];
      final bundles = rawBundles
          .whereType<Map>()
          .map((e) => ShopBundleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(bundles: bundles, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createBundle({
    required String name,
    required String description,
    required String image,
    required List<String> pinIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/pin-bundle',
        requireAuth: true,
        data: {
          'name': name,
          'description': description,
          'image': image,
          'pinIds': pinIds,
        },
      );
      await fetchBundles();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateBundle({
    required String id,
    required String name,
    required String description,
    required String image,
    required List<String> pinIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(
        '/shop/pin-bundle/$id',
        requireAuth: true,
        data: {
          'name': name,
          'description': description,
          'image': image,
          'pinIds': pinIds,
        },
      );
      await fetchBundles();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> softDeleteBundle(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/shop/pin-bundle/softDelete/$id',
        requireAuth: true,
      );
      await fetchBundles();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteBundle(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete(
        '/shop/pin-bundle/$id',
        requireAuth: true,
      );
      await fetchBundles();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
