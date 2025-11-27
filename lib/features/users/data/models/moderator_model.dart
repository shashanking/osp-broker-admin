class ModeratorModel {
  final String id;
  final String userId;
  final List<String> categoryIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModeratorModel({
    required this.id,
    required this.userId,
    required this.categoryIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModeratorModel.fromJson(Map<String, dynamic> json) {
    return ModeratorModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryIds: (json['categoryIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryIds': categoryIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
