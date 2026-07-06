class ShopReviewModel {
  final String id;
  final String itemId;
  final String itemName;
  final int rating;
  final String text;
  final bool isAdmin;
  final String userName;
  final DateTime createdAt;

  const ShopReviewModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.rating,
    required this.text,
    required this.isAdmin,
    required this.userName,
    required this.createdAt,
  });

  factory ShopReviewModel.fromJson(Map<String, dynamic> json) {
    return ShopReviewModel(
      id: (json['id'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toInt()
          : int.tryParse((json['rating'] ?? 0).toString()) ?? 0,
      text: (json['text'] ?? '').toString(),
      isAdmin: json['isAdmin'] == true,
      userName: (json['userName'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
