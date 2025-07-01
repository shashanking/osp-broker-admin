import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../models/user_model.dart';

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

  Future<void> assignModerator(String userId) async {
    await apiService.post('/admin/assignModerator/$userId', requireAuth: true);
  }

  Future<void> removeModerator(String userId) async {
    await apiService.delete('/admin/assignModerator/$userId', requireAuth: true);
  }
}
