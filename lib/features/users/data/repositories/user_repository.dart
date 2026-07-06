import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../models/moderator_model.dart';
import '../models/pin_model.dart';
import '../models/user_membership_model.dart';
import '../models/user_model.dart';
import '../models/user_pin_model.dart';

class UserRepository {
  final BaseApiService apiService;
  UserRepository(this.apiService);

  Future<UserModel> banUser(String userId) async {
    final response = await apiService.post(
      '/moderator/banUser/$userId',
      requireAuth: true,
    );
    return UserModel.fromJson(response.data['data']);
  }

  /// Admin: resolved plan + permissions + usage for a user (what they can/can't
  /// do). GET /membership/usage/:userId. Returns null on failure.
  Future<Map<String, dynamic>?> getUserPlanSummary(String userId) async {
    try {
      final response = await apiService.get(
        '/membership/usage/$userId',
        requireAuth: true,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> unbanUser(String userId) async {
    final response = await apiService.post(
      '/moderator/unbanUser/$userId',
      requireAuth: true,
    );
    return UserModel.fromJson(response.data['data']);
  }

  Future<bool> deleteUser(String userId) async {
    final response = await apiService.delete(
      '/user/$userId',
      requireAuth: true,
    );
    return response.data['success'] == true;
  }

  Future<List<UserModel>> fetchAllUsers() async {
    final response = await apiService.get('/user', requireAuth: true);
    final data = response.data['data']['users'] as List;
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel?> fetchUserProfile(String userId) async {
    try {
      final response = await apiService.get('/user/$userId', requireAuth: true);
      print('DEBUG User profile response for $userId: ${response.data}');

      // Handle different response structures - the user data is nested in data.user
      final data = response.data['data'];
      final userData = data['user'] ?? data;
      print('DEBUG User data: $userData');

      return UserModel.fromJson(userData);
    } catch (e, stackTrace) {
      print('Error fetching user profile for $userId: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfileDetails(String userId) async {
    try {
      final response = await apiService.get(
        '/user/userProfile/$userId',
        requireAuth: true,
      );
      print(
        'DEBUG User profile details response for $userId: ${response.data}',
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e, stackTrace) {
      print('Error fetching user profile details for $userId: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<ModeratorModel>> fetchModerators() async {
    final response = await apiService.get('/moderator', requireAuth: true);
    final data = response.data['data'] as List;
    return data.map((e) => ModeratorModel.fromJson(e)).toList();
  }

  Future<void> assignModerator(String userId, {String? categoryId}) async {
    final data = categoryId != null ? {'categoryId': categoryId} : null;
    await apiService.post(
      '/admin/assignModerator/$userId',
      requireAuth: true,
      data: data,
    );
  }

  Future<void> assignModeratorToCategories(
    String userId, {
    required List<String> categoryIds,
  }) async {
    for (final categoryId in categoryIds) {
      await assignModerator(userId, categoryId: categoryId);
    }
  }

  Future<void> removeModerator(String userId) async {
    await apiService.delete(
      '/admin/removeModerator/$userId',
      requireAuth: true,
    );
  }

  // Membership related methods
  Future<List<UserMembershipModel>> getUserMemberships(String userId) async {
    final response = await apiService.get(
      '/membership/userMemberships',
      requireAuth: true,
      queryParameters: {'userId': userId},
    );
    final memberships = (response.data['data']['userMemberships'] as List)
        .map((e) => UserMembershipModel.fromJson(e))
        .toList();

    // Filter to only return memberships for the requested userId
    final filteredMemberships =
        memberships.where((m) => m.userId == userId).toList();

    print('DEBUG getUserMemberships: Requested userId: $userId');
    print(
      'DEBUG getUserMemberships: Total memberships from API: ${memberships.length}',
    );
    print(
      'DEBUG getUserMemberships: Filtered memberships: ${filteredMemberships.length}',
    );

    return filteredMemberships;
  }

  Future<bool> deleteUserMembership(String membershipId) async {
    final response = await apiService.delete(
      '/membership/userMembership/$membershipId',
      requireAuth: true,
    );
    return response.data['success'] == true;
  }

  Future<UserMembershipModel> createUserMembership({
    required String userId,
    required String membershipPlanId,
    required DateTime startDate,
    required DateTime endDate,
    required String status,
  }) async {
    final response = await apiService.post(
      '/membership/userMembership/admin',
      requireAuth: true,
      data: {
        'userId': userId,
        'membershipPlanId': membershipPlanId,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'status': status,
      },
    );
    return UserMembershipModel.fromJson(response.data['data']);
  }

  Future<List<UserMembershipModel>> getAllUserMemberships({
    bool forceRefresh = false,
  }) async {
    final response = await apiService.get(
      '/membership/userMemberships',
      requireAuth: true,
      queryParameters: {'forceRefresh': forceRefresh.toString()},
    );
    final memberships = (response.data['data']['userMemberships'] as List)
        .map((e) => UserMembershipModel.fromJson(e))
        .toList();
    return memberships;
  }

  Future<bool> assignMembership({
    required String userId,
    required String membershipPlanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await apiService.post(
      '/membership/assign',
      requireAuth: true,
      data: {
        'userId': userId,
        'membershipPlanId': membershipPlanId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return response.data['success'] == true;
  }

  Future<bool> cancelMembership(String userMembershipId) async {
    final response = await apiService.delete(
      '/membership/cancel/$userMembershipId',
      requireAuth: true,
    );
    return response.data['success'] == true;
  }

  Future<List<PinModel>> fetchAllPins() async {
    try {
      final response = await apiService.get('/shop/pin', requireAuth: true);
      print('DEBUG fetchAllPins response: ${response.data}');

      final data = response.data['data'];
      final pins = data['pins'] as List? ?? data as List;
      return pins.map((e) => PinModel.fromJson(e)).toList();
    } catch (e, stackTrace) {
      print('Error fetching pins: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<UserPinModel>> fetchUserPins(String userId) async {
    try {
      final response = await apiService.get(
        '/shop/pin/admin-userPins/$userId',
        requireAuth: true,
      );
      print('DEBUG fetchUserPins response for $userId: ${response.data}');

      final root = response.data;
      final data = root is Map<String, dynamic> ? root['data'] : null;

      dynamic userPins;
      if (data is List) {
        userPins = data;
      } else if (data is Map<String, dynamic>) {
        userPins = data['userPin'] ?? data['userPins'] ?? data['pins'] ?? [];
      } else {
        userPins = [];
      }

      if (userPins is List) {
        return userPins
            .whereType<Map>()
            .map((e) => UserPinModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (userPins is Map) {
        return [
          UserPinModel.fromJson(Map<String, dynamic>.from(userPins)),
        ];
      }

      return const <UserPinModel>[];
    } catch (e, stackTrace) {
      print('Error fetching user pins for $userId: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<UserPinModel> assignPinToUser({
    required String userId,
    required String pinId,
    required int count,
    required double totalCost,
  }) async {
    final response = await apiService.post(
      '/shop/pin/admin-assign/$pinId',
      requireAuth: true,
      data: {
        'userId': userId,
        'count': count,
        'totalCost': totalCost,
      },
    );

    final root = response.data;
    final data = root is Map<String, dynamic> ? root['data'] : null;

    if (data is Map<String, dynamic>) {
      final payload = (data['userPin'] is Map<String, dynamic>)
          ? (data['userPin'] as Map<String, dynamic>)
          : data;

      // If backend returns a full userPin object, use it.
      final hasId = (payload['id'] ?? payload['_id']) != null;
      if (hasId) {
        return UserPinModel.fromJson(payload);
      }
    }

    // Some implementations return a minimal payload only. Re-fetch to get the
    // created record for display.
    final pins = await fetchUserPins(userId);
    if (pins.isEmpty) {
      throw Exception('Pin assigned but unable to load assigned pins');
    }
    pins.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pins.first;
  }
}
