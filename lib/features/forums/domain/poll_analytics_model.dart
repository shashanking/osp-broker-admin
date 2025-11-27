class PollAnalytics {
  final String id;
  final String pollId;
  final List<int> votes;
  final String createdAt;
  final String updatedAt;

  PollAnalytics({
    required this.id,
    required this.pollId,
    required this.votes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PollAnalytics.fromJson(Map<String, dynamic> json) {
    return PollAnalytics(
      id: json['id'] as String? ?? '',
      pollId: json['pollId'] as String? ?? '',
      votes: (json['votes'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
