class RfpModel {
  final String id;
  final String projectTitle;
  final String description;
  final String name;
  final String? phoneNumber;
  final String? country;
  final String email;
  final String message;
  final num? price;
  final String deadline;
  final String additionalFiles;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RfpModel({
    required this.id,
    required this.projectTitle,
    required this.description,
    required this.name,
    required this.phoneNumber,
    this.country,
    required this.email,
    required this.message,
    required this.price,
    required this.deadline,
    required this.additionalFiles,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RfpModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return RfpModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      projectTitle: (json['Projecttitle'] ?? json['projectTitle'] ?? '')
          .toString(),
      description: (json['description'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      // phonenumber is a String on the backend, but legacy rows may still
      // arrive as a number — accept either and keep it as a String.
      phoneNumber: (json['phonenumber'] ?? json['phoneNumber'])?.toString(),
      country: json['country']?.toString(),
      email: (json['email'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      price: (json['price'] as num?),
      deadline: (json['deadline'] ?? '').toString(),
      additionalFiles:
          (json['additionalfiles'] ?? json['additionalFiles'] ?? '').toString(),
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
