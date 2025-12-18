class ShopBadgeModel {
  final String id;
  final String name;
  final String description;
  final int price;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopBadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopBadgeModel.fromJson(Map<String, dynamic> json) {
    return ShopBadgeModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toInt()
          : int.tryParse((json['price'] ?? 0).toString()) ?? 0,
      isDeleted: json['isDeleted'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
