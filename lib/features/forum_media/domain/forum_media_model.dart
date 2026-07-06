class ForumMediaModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String link;
  final int order;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ForumMediaModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.link,
    required this.order,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ForumMediaModel.fromJson(Map<String, dynamic> json) {
    return ForumMediaModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      order: (json['order'] is num)
          ? (json['order'] as num).toInt()
          : int.tryParse((json['order'] ?? 0).toString()) ?? 0,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      isDeleted: json['isDeleted'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
