import 'package:dio/dio.dart';
import '../../domain/forum_models.dart';

class ForumRepository {
  final Dio dio;
  ForumRepository(this.dio);

  Future<List<Forum>> fetchAllForums() async {
    final response = await dio.get('/forum');
    final forums = (response.data['data']['forums'] as List)
        .map((json) => Forum.fromJson(json))
        .toList();
    return forums;
  }

  Future<List<Category>> fetchAllCategories() async {
    final response = await dio.get('/forum/categories');
    final categories = (response.data['data']['categories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();
    return categories;
  }

  Future<List<Topic>> fetchAllTopics({required String forumId}) async {
    final response = await dio.get('/forum/topics', queryParameters: {'forumId': forumId});
    final topics = (response.data['data']['topics'] as List)
        .map((json) => Topic.fromJson(json))
        .toList();
    return topics;
  }

  // Add create, update, delete methods as needed
}
