class ShopKudoCoinModel {
  final String id;
  final int price;
  final String description;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopKudoCoinModel({
    required this.id,
    required this.price,
    required this.description,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopKudoCoinModel.fromJson(Map<String, dynamic> json) {
    return ShopKudoCoinModel(
      id: (json['id'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toInt()
          : int.tryParse((json['price'] ?? 0).toString()) ?? 0,
      description: (json['description'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
