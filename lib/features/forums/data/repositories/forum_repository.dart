import 'package:dio/dio.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../../domain/forum_models.dart';

class ForumRepository {
  final BaseApiService _apiService;

  ForumRepository(this._apiService);

  Future<List<Forum>> fetchAllForums() async {
    final response = await _apiService.get('/forum');
    final forums = (response.data['data']['forums'] as List)
        .map((json) => Forum.fromJson(json))
        .toList();
    return forums;
  }

  Future<List<Category>> fetchAllCategories() async {
    final response = await _apiService.get('/forum/categories');
    final categories = (response.data['data']['categories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();
    return categories;
  }

  Future<List<Topic>> fetchAllTopics({required String forumId}) async {
    final response = await _apiService
        .get('/forum/topics', queryParameters: {'forumId': forumId});
    final topics = (response.data['data']['topics'] as List)
        .map((json) => Topic.fromJson(json))
        .toList();
    return topics;
  }

  // Category CRUD
  Future<Category> createCategory({
    required String name,
    required String description,
    required String moderatorId,
    required String icon,
    required List<String> membershipAccess,
  }) async {
    final response = await _apiService.post(
      '/forum/category',
      requireAuth: true,
      data: {
        'name': name,
        'description': description,
        'moderatorId': moderatorId,
        'icon': icon,
        'membership_access': membershipAccess,
      },
    );
    return Category.fromJson(response.data['data']['Category']);
  }

  Future<Category> updateCategory(
    String id, {
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiService.put(
      '/forum/category/$id',
      data: data,
      requireAuth: true,
    );
    return Category.fromJson(response.data['data']['Category']);
  }

  Future<void> deleteCategory(String id) async {
    await _apiService.delete(
      '/forum/category/$id',
      requireAuth: true,
    );
  }

  // Forum CRUD
  Future<Forum> createForum({
    required String title,
    required String description,
    required String author,
    required String categoryId,
    required String userId,
  }) async {
    final response = await _apiService.post(
      '/forum',
      requireAuth: true,
      data: {
        'title': title,
        'description': description,
        'author': author,
        'categoryId': categoryId,
        'userId': userId,
      },
    );
    return Forum.fromJson(response.data['data']['forum']);
  }

  Future<Forum> updateForum({
    required String forumId,
    required String title,
    required String description,
  }) async {
    final response = await _apiService.put(
      '/forum/$forumId',
      requireAuth: true,
      data: {
        'title': title,
        'description': description,
      },
    );
    return Forum.fromJson(response.data['data']['forum']);
  }

  Future<void> deleteForum({required String forumId}) async {
    final response = await _apiService.delete(
      '/forum/$forumId',
      requireAuth: true,
    );
    if (response.data is Map && response.data['message'] == 'unauthorized access') {
      throw Exception('unauthorized access');
    }
  }
}
