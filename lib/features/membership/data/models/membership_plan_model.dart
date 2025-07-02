class MembershipPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String billingCycle;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? duration; // Make duration nullable
  final List<Map<String, String>> userMembership;

  MembershipPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.billingCycle,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
    this.duration, // Optional parameter
    required this.userMembership,
  });

  factory MembershipPlanModel.fromJson(Map<String, dynamic> json) {
    // one more layer inside json
    return MembershipPlanModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      billingCycle: json['billingCycle'],
      features: List<String>.from(json['features'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      duration: json['duration'] != null ? json['duration'] as int : null,
      userMembership: List<Map<String, String>>.from(
        (json['userMembership'] as List?)
                ?.map((e) => Map<String, String>.from(e)) ??
            [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'billingCycle': billingCycle,
      'features': features,
      'price': price,
      'duration': duration,
    };
  }

  String get durationText {
    if (duration == null) return 'N/A';
    return '${duration!} days';
  }
}
