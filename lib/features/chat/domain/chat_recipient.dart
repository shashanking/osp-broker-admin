class ChatRecipient {
  final String recipientId;
  final String recipientName;
  final String content;
  final DateTime createdAt;

  ChatRecipient({
    required this.recipientId,
    required this.recipientName,
    required this.content,
    required this.createdAt,
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;

    if (value is Map) {
      final maybe = value[r'$date'];
      if (maybe is String) {
        return DateTime.tryParse(maybe) ?? DateTime.now();
      }
    }

    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory ChatRecipient.fromJson(Map<String, dynamic> json) {
    // Debug: Print the raw JSON to understand structure
    print('DEBUG ChatRecipient.fromJson received: $json');

    return ChatRecipient(
      recipientId: json['recipientId']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }
}
