class PinModel {
  final String id;
  final String color;
  final double price;
  final int duration; // in days
  final String image;
  final bool? bought;
  final DateTime createdAt;
  final DateTime updatedAt;

  PinModel({
    required this.id,
    required this.color,
    required this.price,
    required this.duration,
    required this.image,
    this.bought,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PinModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return PinModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      color: (json['color'])?.toString() ?? '',
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as int,
      image: (json['image'])?.toString() ?? '',
      bought: json['bought'] as bool?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color,
      'price': price,
      'duration': duration,
      'image': image,
      'bought': bought,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
