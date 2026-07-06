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

  // tier identity + limits (null limit = unlimited)
  final String? tier;
  final int level;
  final int? monthlyMessageQuota;
  final int? dailyMessageQuota;
  final int? dailyInMailQuota;
  final int? dailyConnectionQuota;
  final int? maxConnections;
  final int? monthlyEventQuota;
  final int? outreachCredits;
  final int? messageCharLimit;
  final double? maxAuctionBidAmount;
  final int? maxConcurrentAuctions;
  final bool canCreatePrivateAuction;
  final bool canGift;

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
    this.tier,
    this.level = 0,
    this.monthlyMessageQuota,
    this.dailyMessageQuota,
    this.dailyInMailQuota,
    this.dailyConnectionQuota,
    this.maxConnections,
    this.monthlyEventQuota,
    this.outreachCredits,
    this.messageCharLimit,
    this.maxAuctionBidAmount,
    this.maxConcurrentAuctions,
    this.canCreatePrivateAuction = false,
    this.canGift = false,
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
      tier: json['tier'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 0,
      monthlyMessageQuota: (json['monthlyMessageQuota'] as num?)?.toInt(),
      dailyMessageQuota: (json['dailyMessageQuota'] as num?)?.toInt(),
      dailyInMailQuota: (json['dailyInMailQuota'] as num?)?.toInt(),
      dailyConnectionQuota: (json['dailyConnectionQuota'] as num?)?.toInt(),
      maxConnections: (json['maxConnections'] as num?)?.toInt(),
      monthlyEventQuota: (json['monthlyEventQuota'] as num?)?.toInt(),
      outreachCredits: (json['outreachCredits'] as num?)?.toInt(),
      messageCharLimit: (json['messageCharLimit'] as num?)?.toInt(),
      maxAuctionBidAmount: (json['maxAuctionBidAmount'] as num?)?.toDouble(),
      maxConcurrentAuctions: (json['maxConcurrentAuctions'] as num?)?.toInt(),
      canCreatePrivateAuction: json['canCreatePrivateAuction'] as bool? ?? false,
      canGift: json['canGift'] as bool? ?? false,
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
      'tier': tier,
      'level': level,
      'monthlyMessageQuota': monthlyMessageQuota,
      'dailyMessageQuota': dailyMessageQuota,
      'dailyInMailQuota': dailyInMailQuota,
      'dailyConnectionQuota': dailyConnectionQuota,
      'maxConnections': maxConnections,
      'monthlyEventQuota': monthlyEventQuota,
      'outreachCredits': outreachCredits,
      'messageCharLimit': messageCharLimit,
      'maxAuctionBidAmount': maxAuctionBidAmount,
      'maxConcurrentAuctions': maxConcurrentAuctions,
      'canCreatePrivateAuction': canCreatePrivateAuction,
      'canGift': canGift,
    };
  }

  String get durationText {
    if (duration == null) return 'N/A';
    return '${duration!} days';
  }
}
