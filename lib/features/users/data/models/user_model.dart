class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String phone;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Pinpoint GPS location captured at signup (null for legacy users).
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.phone,
    required this.isBanned,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.locationAddress,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isBanned: json['isBanned'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['locationAddress']?.toString(),
    );
  }
}

