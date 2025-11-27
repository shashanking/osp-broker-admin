class Bid {
  final String id;
  final String auctionId;
  final String userId;
  final String response;
  final bool matched;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BidUser? user;

  Bid({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.response,
    required this.matched,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'] as String,
      auctionId: json['auctionId'] as String,
      userId: json['userId'] as String,
      response: json['response'] as String,
      matched: json['matched'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: json['User'] != null ? BidUser.fromJson(json['User']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auctionId': auctionId,
      'userId': userId,
      'response': response,
      'matched': matched,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'User': user?.toJson(),
    };
  }

  /// Extracts the bid amount from the response string
  /// Expected format: "Bid: $X" or "Bid: $X,XXX"
  double? get bidAmount {
    try {
      // Match pattern like "Bid: $101" or "Bid: $1,234"
      final regex = RegExp(r'Bid:\s*\$\s*([\d,]+)');
      final match = regex.firstMatch(response);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        return double.tryParse(amountStr ?? '');
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class BidUser {
  final String id;
  final String fullName;
  final String email;

  BidUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory BidUser.fromJson(Map<String, dynamic> json) {
    return BidUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }
}
