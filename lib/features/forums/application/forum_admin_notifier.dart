import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:osp_broker_admin/core/infrastructure/dio_provider.dart';
import 'package:osp_broker_admin/features/forums/data/repositories/forum_repository.dart';
import '../domain/forum_models.dart';
import 'package:dio/dio.dart';

part 'forum_admin_notifier.freezed.dart';

@freezed
class ForumAdminState with _$ForumAdminState {
  const factory ForumAdminState({
    @Default(false) bool isLoading,
    String? error,
    @Default(<Category>[]) List<Category> categories,
    @Default(<Forum>[]) List<Forum> forums,
    @Default(<Topic>[]) List<Topic> topics,
    Category? selectedCategory,
    Forum? selectedForum,
    Topic? selectedTopic,
  }) = _ForumAdminState;
}

class ForumAdminNotifier extends StateNotifier<ForumAdminState> {
  final ForumRepository repository;
  final Dio _dio;
  ForumAdminNotifier(this.repository, this._dio)
      : super(const ForumAdminState());

  // Categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await repository.fetchAllCategories();
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Forums
  Future<void> loadForums({String? categoryId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final forums = await repository.fetchAllForums();
      state = state.copyWith(forums: forums, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Topics
  Future<void> loadTopics({required String forumId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final topics = await repository.fetchAllTopics(forumId: forumId);
      state = state.copyWith(topics: topics, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Example CRUD for Category
  Future<void> createCategory(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/admin/forum/categories', data: data);
      await loadCategories();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.put('/admin/forum/categories/$id', data: data);
      await loadCategories();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.delete('/admin/forum/categories/$id');
      await loadCategories();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add similar CRUD for Forum and Topic as needed
}

final forumAdminNotifierProvider =
    StateNotifierProvider<ForumAdminNotifier, ForumAdminState>((ref) {
  final dio = ref.watch(dioProvider);
  final repo = ForumRepository(dio);

  return ForumAdminNotifier(repo, dio);
});
