class ShopPinModel {
  final String id;
  final String color;
  final int price;
  final bool bought;
  final int duration;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopPinModel({
    required this.id,
    required this.color,
    required this.price,
    required this.bought,
    required this.duration,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopPinModel.fromJson(Map<String, dynamic> json) {
    return ShopPinModel(
      id: (json['id'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toInt()
          : int.tryParse((json['price'] ?? 0).toString()) ?? 0,
      bought: json['bought'] == true,
      duration: (json['duration'] is num)
          ? (json['duration'] as num).toInt()
          : int.tryParse((json['duration'] ?? 0).toString()) ?? 0,
      isDeleted: json['isDeleted'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
