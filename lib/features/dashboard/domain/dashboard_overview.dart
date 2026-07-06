/// Plain (non-freezed) models for the full admin dashboard overview payload
/// returned by GET /admin/dashboard/stats.
///
/// Parsing is deliberately defensive: any missing/odd-typed key falls back to
/// 0 / empty so the page keeps working against older backends.
class DashboardOverview {
  // Users
  final int totalUsers;
  final int bannedUsers;
  final int newUsers7d;
  final int activeMemberships;

  // Businesses
  final int totalBusinesses;
  final int pendingReps;

  // Auctions
  final int totalAuctions;
  final int pendingAuctions;
  final int activeAuctions;
  final int totalBids;

  // Forum
  final int totalForums;
  final int totalTopics;
  final int totalComments;

  // Misc
  final int totalRFPs;
  final int pendingScrapedBusinesses;
  final int totalOrders;
  final int totalShopItems;
  final int flaggedContent;

  // Revenue
  final num totalRevenue;
  final num revenue30d;

  final List<MembershipPlanCount> membershipBreakdown;
  final List<SignupDay> signupsByDay;
  final List<RecentUser> recentUsers;
  final List<RecentAuction> recentAuctions;
  final List<RecentBusiness> recentBusinesses;

  const DashboardOverview({
    this.totalUsers = 0,
    this.bannedUsers = 0,
    this.newUsers7d = 0,
    this.activeMemberships = 0,
    this.totalBusinesses = 0,
    this.pendingReps = 0,
    this.totalAuctions = 0,
    this.pendingAuctions = 0,
    this.activeAuctions = 0,
    this.totalBids = 0,
    this.totalForums = 0,
    this.totalTopics = 0,
    this.totalComments = 0,
    this.totalRFPs = 0,
    this.pendingScrapedBusinesses = 0,
    this.totalOrders = 0,
    this.totalShopItems = 0,
    this.flaggedContent = 0,
    this.totalRevenue = 0,
    this.revenue30d = 0,
    this.membershipBreakdown = const [],
    this.signupsByDay = const [],
    this.recentUsers = const [],
    this.recentAuctions = const [],
    this.recentBusinesses = const [],
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    final stats = _asMap(json['stats']);
    int i(String key) => _asInt(stats[key]);
    num n(String key) => _asNum(stats[key]);

    return DashboardOverview(
      totalUsers: i('totalUsers'),
      bannedUsers: i('bannedUsers'),
      newUsers7d: i('newUsers7d'),
      activeMemberships: i('activeMemberships'),
      totalBusinesses: i('totalBusinesses'),
      pendingReps: i('pendingReps'),
      totalAuctions: i('totalAuctions'),
      pendingAuctions: i('pendingAuctions'),
      activeAuctions: i('activeAuctions'),
      totalBids: i('totalBids'),
      totalForums: i('totalForums'),
      totalTopics: i('totalTopics'),
      totalComments: i('totalComments'),
      totalRFPs: i('totalRFPs'),
      pendingScrapedBusinesses: i('pendingScrapedBusinesses'),
      totalOrders: i('totalOrders'),
      totalShopItems: i('totalShopItems'),
      flaggedContent: i('flaggedContent'),
      totalRevenue: n('totalRevenue'),
      revenue30d: n('revenue30d'),
      membershipBreakdown: _asMapList(json['membershipBreakdown'])
          .map(MembershipPlanCount.fromJson)
          .toList(),
      signupsByDay:
          _asMapList(json['signupsByDay']).map(SignupDay.fromJson).toList(),
      recentUsers:
          _asMapList(json['recentUsers']).map(RecentUser.fromJson).toList(),
      recentAuctions: _asMapList(json['recentAuctions'])
          .map(RecentAuction.fromJson)
          .toList(),
      recentBusinesses: _asMapList(json['recentBusinesses'])
          .map(RecentBusiness.fromJson)
          .toList(),
    );
  }
}

class MembershipPlanCount {
  final String planName;
  final int level;
  final int count;

  const MembershipPlanCount({
    required this.planName,
    required this.level,
    required this.count,
  });

  factory MembershipPlanCount.fromJson(Map<String, dynamic> json) {
    return MembershipPlanCount(
      planName: _asString(json['planName'], fallback: 'Unknown'),
      level: _asInt(json['level']),
      count: _asInt(json['count']),
    );
  }
}

class SignupDay {
  final String date;
  final int count;

  const SignupDay({required this.date, required this.count});

  factory SignupDay.fromJson(Map<String, dynamic> json) {
    return SignupDay(
      date: _asString(json['date']),
      count: _asInt(json['count']),
    );
  }
}

class RecentUser {
  final String id;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  const RecentUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.createdAt,
  });

  factory RecentUser.fromJson(Map<String, dynamic> json) {
    return RecentUser(
      id: _asString(json['id']),
      fullName: _asString(json['fullName']),
      email: _asString(json['email']),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class RecentAuction {
  final String id;
  final String title;
  final bool approved;
  final DateTime? createdAt;

  const RecentAuction({
    required this.id,
    required this.title,
    required this.approved,
    this.createdAt,
  });

  factory RecentAuction.fromJson(Map<String, dynamic> json) {
    return RecentAuction(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Untitled auction'),
      approved: json['approved'] == true,
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class RecentBusiness {
  final String id;
  final String businessName;
  final DateTime? createdAt;

  const RecentBusiness({
    required this.id,
    required this.businessName,
    this.createdAt,
  });

  factory RecentBusiness.fromJson(Map<String, dynamic> json) {
    return RecentBusiness(
      id: _asString(json['id']),
      businessName: _asString(json['businessName'], fallback: 'Unnamed business'),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

// ---------------------------------------------------------------------------
// Defensive parsing helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

num _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final s = value.toString();
  return s.isEmpty ? fallback : s;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
