import 'shop_pin_model.dart';

class ShopBundleModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final List<String> pinIds;
  final bool isActive;
  final bool isDeleted;
  final int totalPins;
  final int totalPrice;
  final List<ShopPinModel> pins;

  const ShopBundleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.pinIds,
    required this.isActive,
    required this.isDeleted,
    required this.totalPins,
    required this.totalPrice,
    required this.pins,
  });

  factory ShopBundleModel.fromJson(Map<String, dynamic> json) {
    final rawPinIds = (json['pinIds'] as List?) ?? const [];
    final rawPins = (json['pins'] as List?) ?? const [];

    return ShopBundleModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      pinIds: rawPinIds.map((e) => e.toString()).toList(),
      isActive: json['isActive'] == true,
      isDeleted: json['isDeleted'] == true,
      totalPins: (json['totalPins'] is num)
          ? (json['totalPins'] as num).toInt()
          : int.tryParse((json['totalPins'] ?? 0).toString()) ?? 0,
      totalPrice: (json['totalPrice'] is num)
          ? (json['totalPrice'] as num).toInt()
          : int.tryParse((json['totalPrice'] ?? 0).toString()) ?? 0,
      pins: rawPins
          .whereType<Map>()
          .map((e) => ShopPinModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
