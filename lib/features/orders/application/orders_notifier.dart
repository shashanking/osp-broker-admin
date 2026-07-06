import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/orders/domain/order_model.dart';

/// Loads all orders / payment receipts for the admin from
/// GET /payment/admin/orders.
class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final BaseApiService _api;
  OrdersNotifier(this._api) : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/payment/admin/orders');
      final data = response.data['data']?['orders'] as List? ?? const [];
      final orders = data
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch();
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>(
  (ref) => OrdersNotifier(ref.watch(baseApiServiceProvider)),
);
