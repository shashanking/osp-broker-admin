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

  factory ChatRecipient.fromJson(Map<String, dynamic> json) {
    // Debug: Print the raw JSON to understand structure
    print('DEBUG ChatRecipient.fromJson received: $json');

    return ChatRecipient(
      recipientId: json['recipientId']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
