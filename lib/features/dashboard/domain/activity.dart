enum ActivityType {
  user,
  payment,
  system,
  other,
}

class Activity {
  final String id;
  final String description;
  final DateTime timestamp;
  final ActivityType type;
  final String? userId;
  final String? userName;

  Activity({
    required this.id,
    required this.description,
    required this.timestamp,
    this.type = ActivityType.other,
    this.userId,
    this.userName,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
        orElse: () => ActivityType.other,
      ),
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
    };
  }
}
