import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/api_urls.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/shop/domain/shop_item_model.dart';

final shopItemsNotifierProvider =
    StateNotifierProvider<ShopItemsNotifier, ShopItemsState>((ref) {
  final apiService = ref.watch(baseApiServiceProvider);
  return ShopItemsNotifier(apiService);
});

class ShopItemsNotifier extends StateNotifier<ShopItemsState> {
  final BaseApiService _apiService;

  ShopItemsNotifier(this._apiService) : super(ShopItemsState.initial()) {
    loadItems();
    loadCategories();
  }

  // Load all shop items
  Future<void> loadItems({String? categoryId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams =
          categoryId != null ? {'categoryId': categoryId} : null;
      final response = await _apiService.get(
        ApiUrls.shopItems,
        queryParameters: queryParams?.map((k, v) => MapEntry(k, v)),
      );

      final data = response.data;
      List<ShopItemModel> items = [];

      if (data['success'] == true && data['data'] != null) {
        final itemsData = data['data'];
        if (itemsData is List) {
          items = itemsData
              .map((json) =>
                  ShopItemModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Load shop categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      final response = await _apiService.get(ApiUrls.shopCategories);

      final data = response.data;
      List<ShopCategoryModel> categories = [];

      if (data['success'] == true && data['data'] != null) {
        final categoriesData = data['data'];
        if (categoriesData is List) {
          categories = categoriesData
              .map((json) =>
                  ShopCategoryModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      state =
          state.copyWith(categories: categories, isLoadingCategories: false);
    } catch (e) {
      // Categories might not be available yet
      state = state.copyWith(isLoadingCategories: false);
    }
  }

  // Create a new category
  Future<ShopCategoryModel> createCategory({
    required String name,
    required String description,
  }) async {
    state = state.copyWith(isLoadingCategories: true, error: null);
    try {
      final response = await _apiService.post(
        ApiUrls.shopCategories,
        data: {
          'name': name,
          'description': description,
        },
      );

      final newCategory =
          ShopCategoryModel.fromJson(response.data['data']['category']);
      state = state.copyWith(
        categories: [...state.categories, newCategory],
        isLoadingCategories: false,
      );
      return newCategory;
    } catch (e) {
      state = state.copyWith(isLoadingCategories: false, error: e.toString());
      rethrow;
    }
  }

  // Create a new shop item
  Future<ShopItemModel> createItem({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.post(
        ApiUrls.shopItems,
        data: {
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
          'categoryId': categoryId,
        },
      );

      final newItem = ShopItemModel.fromJson(response.data['data']);
      state = state.copyWith(
        items: [newItem, ...state.items],
        isLoading: false,
      );
      return newItem;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Update an existing shop item
  Future<ShopItemModel> updateItem({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (stock != null) updateData['stock'] = stock;
      if (categoryId != null) updateData['categoryId'] = categoryId;

      final response = await _apiService.put(
        '${ApiUrls.shopItems}/$id',
        data: updateData,
      );

      final updatedItem = ShopItemModel.fromJson(response.data['data']);
      final updatedItems = state.items.map((item) {
        return item.id == id ? updatedItem : item;
      }).toList();

      state = state.copyWith(items: updatedItems, isLoading: false);
      return updatedItem;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Soft delete a shop item
  Future<void> softDeleteItem(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.post('${ApiUrls.shopItems}/softDelete/$id');

      // Remove from local state
      final updatedItems = state.items.where((item) => item.id != id).toList();
      state = state.copyWith(items: updatedItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Hard delete a shop item
  Future<void> deleteItem(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.delete('${ApiUrls.shopItems}/$id');

      // Remove from local state
      final updatedItems = state.items.where((item) => item.id != id).toList();
      state = state.copyWith(items: updatedItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Get item by ID
  Future<ShopItemModel?> getItemById(String id) async {
    try {
      final response = await _apiService.get('${ApiUrls.shopItems}/$id');
      return ShopItemModel.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadItems();
    await loadCategories();
  }
}
