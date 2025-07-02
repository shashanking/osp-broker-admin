import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/forums/data/repositories/forum_repository.dart';
import 'package:osp_broker_admin/features/forums/domain/forum_models.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';
import 'package:osp_broker_admin/features/users/data/models/user_model.dart';

part 'forum_admin_notifier.freezed.dart';

@freezed
class ForumAdminState with _$ForumAdminState {
  const factory ForumAdminState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingModerators,
    @Default(false) bool isLoadingMembershipPlans,
    String? error,
    @Default(<Category>[]) List<Category> categories,
    @Default(<Forum>[]) List<Forum> forums,
    @Default(<Topic>[]) List<Topic> topics,
    @Default(<UserModel>[]) List<UserModel> moderators,
    @Default(<MembershipPlanModel>[]) List<MembershipPlanModel> membershipPlans,
    Category? selectedCategory,
    Forum? selectedForum,
    Topic? selectedTopic,
  }) = _ForumAdminState;
  
  const ForumAdminState._();
  
  factory ForumAdminState.initial() => const ForumAdminState();
}

class ForumAdminNotifier extends StateNotifier<ForumAdminState> {
  final ForumRepository _repository;
  final Ref _ref;

  ForumAdminNotifier(this._repository, this._ref) : super(ForumAdminState.initial());
  
  // Load moderators from UserNotifier
  Future<void> loadModerators() async {
    state = state.copyWith(isLoadingModerators: true);
    try {
      final moderators = await _ref.read(userNotifierProvider.notifier).fetchModerators();
      state = state.copyWith(
        moderators: moderators,
        isLoadingModerators: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load moderators: $e',
        isLoadingModerators: false,
      );
      rethrow;
    }
  }
  
  // Load membership plans from MembershipNotifier
  Future<void> loadMembershipPlans() async {
    state = state.copyWith(isLoadingMembershipPlans: true);
    try {
      await _ref.read(membershipNotifierProvider.notifier).fetchMemberships();
      final plans = _ref.read(membershipNotifierProvider).plans;
      state = state.copyWith(
        membershipPlans: plans,
        isLoadingMembershipPlans: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load membership plans: $e',
        isLoadingMembershipPlans: false,
      );
      rethrow;
    }
  }

  // Categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _repository.fetchAllCategories();
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Category> createCategory({
    required String name,
    required String description,
    required String moderatorId,
    required String icon,
    required List<String> membershipAccess,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newCategory = await _repository.createCategory(
        name: name,
        description: description,
        moderatorId: moderatorId,
        icon: icon,
        membershipAccess: membershipAccess,
      );
      state = state.copyWith(
        categories: [...state.categories, newCategory],
        isLoading: false,
      );
      return newCategory;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }



  // Forums
  Future<void> loadForums() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final forums = await _repository.fetchAllForums();
      state = state.copyWith(forums: forums, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Topics
  Future<void> loadTopics({required String forumId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final topics = await _repository.fetchAllTopics(forumId: forumId);
      state = state.copyWith(topics: topics, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateCategory(id, data: data);
      await loadCategories();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add similar CRUD for Forum and Topic as needed
}

final forumAdminNotifierProvider =
    StateNotifierProvider<ForumAdminNotifier, ForumAdminState>((ref) {
  final apiService = ref.watch(baseApiServiceProvider);
  final repo = ForumRepository(apiService);
  return ForumAdminNotifier(repo, ref);
});
