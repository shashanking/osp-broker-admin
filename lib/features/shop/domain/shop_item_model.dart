import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_item_model.freezed.dart';
part 'shop_item_model.g.dart';

@freezed
class ShopItemModel with _$ShopItemModel {
  const factory ShopItemModel({
    required String id,
    required String name,
    required String description,
    required double price,
    @Default(0) int stock,
    required String categoryId,
    @Default(true) bool active,
    @Default('') String image,
    ShopCategoryModel? category,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ShopItemModel;

  factory ShopItemModel.fromJson(Map<String, dynamic> json) =>
      _$ShopItemModelFromJson(json);
}

@freezed
class ShopCategoryModel with _$ShopCategoryModel {
  const factory ShopCategoryModel({
    required String id,
    required String name,
    @Default('') String description,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ShopCategoryModel;

  factory ShopCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ShopCategoryModelFromJson(json);
}

@freezed
class ShopItemsState with _$ShopItemsState {
  const factory ShopItemsState({
    @Default([]) List<ShopItemModel> items,
    @Default([]) List<ShopCategoryModel> categories,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingCategories,
    String? error,
  }) = _ShopItemsState;

  factory ShopItemsState.initial() => const ShopItemsState();
}
