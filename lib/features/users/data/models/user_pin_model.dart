class UserPinModel {
  final String id;
  final String userId;
  final String pinId;
  final int count;
  final double totalCost;
  final DateTime? expirationDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPinModel({
    required this.id,
    required this.userId,
    required this.pinId,
    required this.count,
    required this.totalCost,
    required this.expirationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPinModel.fromJson(Map<String, dynamic> json) {
    final idValue = (json['id'] ?? json['_id'])?.toString();
    final userIdValue = (json['userId'] ?? json['user_id'])?.toString();
    final pinIdValue = (json['pinId'] ?? json['pin_id'])?.toString();
    final expRaw = json['expirationDate'] ?? json['expiration_date'];
    DateTime? exp;
    if (expRaw != null) {
      try {
        exp = DateTime.parse(expRaw.toString());
      } catch (_) {
        exp = null;
      }
    }

    DateTime parseDate(dynamic v) {
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return UserPinModel(
      id: idValue ?? '',
      userId: userIdValue ?? '',
      pinId: pinIdValue ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      expirationDate: exp,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'pinId': pinId,
      'count': count,
      'totalCost': totalCost,
      'expirationDate': expirationDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isExpired =>
      expirationDate != null && expirationDate!.isBefore(DateTime.now());

  bool get isActive => !isExpired && count > 0;
}
