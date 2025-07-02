class UserMembershipModel {
  final String id;
  final String userId;
  final String membershipPlanId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserMembershipModel({
    required this.id,
    required this.userId,
    required this.membershipPlanId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserMembershipModel.fromJson(Map<String, dynamic> json) {
    return UserMembershipModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      membershipPlanId: json['membershipPlanId'] as String,
      startDate: DateTime.parse(json['startDate'] as String).toLocal(),
      endDate: DateTime.parse(json['endDate'] as String).toLocal(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'membershipPlanId': membershipPlanId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
