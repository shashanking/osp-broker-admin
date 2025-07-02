import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../models/user_model.dart';
import '../models/user_membership_model.dart';

class UserRepository {
  final BaseApiService apiService;
  UserRepository(this.apiService);

  Future<UserModel> banUser(String userId) async {
    final response = await apiService.post('/moderator/banUser/$userId', requireAuth: true);
    return UserModel.fromJson(response.data['data']);
  }

  Future<bool> deleteUser(String userId) async {
    final response = await apiService.delete('/user/$userId', requireAuth: true);
    return response.data['success'] == true;
  }

  Future<List<UserModel>> fetchAllUsers() async {
    final response = await apiService.get('/user', requireAuth: true);
    final data = response.data['data']['users'] as List;
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> fetchModerators() async {
    final users = await fetchAllUsers();
    return users.where((user) => user.role.toLowerCase() == 'moderator').toList();
  }

  Future<void> assignModerator(String userId) async {
    await apiService.post('/admin/assignModerator/$userId', requireAuth: true);
  }

  Future<void> removeModerator(String userId) async {
    await apiService.delete('/admin/assignModerator/$userId', requireAuth: true);
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
    return memberships;
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
      '/membership/userMembership',
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

  Future<List<UserMembershipModel>> getAllUserMemberships({bool forceRefresh = false}) async {
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
}
