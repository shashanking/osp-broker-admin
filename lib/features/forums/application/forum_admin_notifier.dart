import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/forums/data/repositories/forum_repository.dart';
import 'package:osp_broker_admin/features/forums/domain/forum_models.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';

import 'package:osp_broker_admin/features/users/data/models/moderator_model.dart';
import 'package:osp_broker_admin/features/forums/domain/poll_analytics_model.dart';

part 'forum_admin_notifier.freezed.dart';

@freezed
class ForumAdminState with _$ForumAdminState {
  const factory ForumAdminState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingModerators,
    @Default(false) bool isLoadingMembershipPlans,
    @Default(false) bool isLoadingComments,
    String? error,
    @Default(<Category>[]) List<Category> categories,
    @Default(<Forum>[]) List<Forum> forums,
    @Default(<Topic>[]) List<Topic> topics,
    @Default(<Announcement>[]) List<Announcement> announcements,
    @Default(<Event>[]) List<Event> events,
    @Default(<Poll>[]) List<Poll> polls,
    @Default(<Comment>[]) List<Comment> comments,
    @Default(<ModeratorModel>[]) List<ModeratorModel> moderators,
    @Default(<MembershipPlanModel>[]) List<MembershipPlanModel> membershipPlans,
    Category? selectedCategory,
    Forum? selectedForum,
    Topic? selectedTopic,
  }) = _ForumAdminState;

  const ForumAdminState._();

  factory ForumAdminState.initial() => const ForumAdminState(
        isLoading: false,
        isLoadingModerators: false,
        isLoadingMembershipPlans: false,
        isLoadingComments: false,
        error: null,
        categories: [],
        forums: [],
        topics: [],
        announcements: [],
        events: [],
        polls: [],
        comments: [],
        moderators: [],
        membershipPlans: [],
        selectedCategory: null,
        selectedForum: null,
        selectedTopic: null,
      );
}

class ForumAdminNotifier extends StateNotifier<ForumAdminState> {
  final ForumRepository _repository;
  final Ref _ref;

  ForumAdminNotifier(this._repository, this._ref)
      : super(ForumAdminState.initial());

  // Load moderators from UserNotifier
  Future<void> loadModerators() async {
    state = state.copyWith(isLoadingModerators: true);
    try {
      // Ensure users are loaded first (needed for UI to show moderator names)
      await _ref.read(userNotifierProvider.notifier).fetchUsers();

      // Trigger the fetch in user notifier
      await _ref.read(userNotifierProvider.notifier).fetchModerators();

      // Get the moderators from user notifier state
      final moderators = _ref.read(userNotifierProvider).moderators;

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
    String? moderatorId,
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

  Future<Forum> createForum({
    required String title,
    required String description,
    required String author,
    required String categoryId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newForum = await _repository.createForum(
        title: title,
        description: description,
        author: author,
        categoryId: categoryId,
        userId: userId,
      );
      state = state.copyWith(
        forums: [...state.forums, newForum],
        isLoading: false,
      );
      return newForum;
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

  Future<Forum> updateForum({
    required String forumId,
    required String title,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedForum = await _repository.updateForum(
        forumId: forumId,
        title: title,
        description: description,
      );
      // Update the forum in state.forums
      final updatedForums =
          state.forums.map((f) => f.id == forumId ? updatedForum : f).toList();
      state = state.copyWith(forums: updatedForums, isLoading: false);
      return updatedForum;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
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

  Future<void> deleteForum(String forumId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteForum(forumId: forumId);
      // Remove from state
      final updatedForums = state.forums.where((f) => f.id != forumId).toList();
      state = state.copyWith(forums: updatedForums, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // fetch all announcements
  Future<void> fetchAllAnnouncements() async {
    try {
      state = state.copyWith(isLoading: true);
      final announcements = await _repository.fetchAllAnnouncements();
      state = state.copyWith(
        announcements: announcements,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Add a new announcement
  Future<void> addAnnouncement({
    required String title,
    required String description,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final announcement = await _repository.createAnnouncement(
        title: title,
        description: description,
      );

      // Update the announcements list
      state = state.copyWith(
        announcements: [...state.announcements, announcement],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Create a new poll
  Future<Poll> createPoll({
    required String question,
    required List<String> options,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final poll = await _repository.createPoll(
        question: question,
        options: options,
      );

      // Update the polls list
      state = state.copyWith(
        polls: [...state.polls, poll],
        isLoading: false,
      );

      return poll;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> deletePoll(String pollId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.deletePoll(pollId);
      // Remove poll from state
      final updatedPolls = state.polls.where((p) => p.id != pollId).toList();
      state = state.copyWith(
        polls: updatedPolls,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<PollAnalytics> getPollAnalytics(String pollId) async {
    try {
      state = state.copyWith(isLoading: true);
      final analytics = await _repository.fetchPollAnalytics(pollId);
      state = state.copyWith(isLoading: false);
      return analytics;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Delete an announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.deleteAnnouncement(id);

      // Update the announcements list by removing the deleted announcement
      state = state.copyWith(
        announcements: state.announcements.where((a) => a.id != id).toList(),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // fetch all events
  Future<void> fetchAllEvents() async {
    try {
      state = state.copyWith(isLoading: true);
      final events = await _repository.fetchAllEvents();
      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Create a new event
  Future<Event> createEvent({
    required String title,
    required String description,
    required String date,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final event = await _repository.createEvent(
        title: title,
        description: description,
        date: date,
      );

      // Update the events list
      state = state.copyWith(
        events: [...state.events, event],
        isLoading: false,
      );

      return event;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.deleteEvent(eventId);
      // Remove event from state
      final updatedEvents = state.events.where((e) => e.id != eventId).toList();
      state = state.copyWith(
        events: updatedEvents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // fetch all polls
  Future<void> fetchAllPolls() async {
    try {
      state = state.copyWith(isLoading: true);
      final polls = await _repository.fetchAllPolls();
      state = state.copyWith(
        polls: polls,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Comments
  Future<void> fetchCommentsForTopic(String topicId) async {
    try {
      state = state.copyWith(isLoadingComments: true, error: null);
      final comments = await _repository.fetchCommentsForTopic(topicId);
      state = state.copyWith(
        comments: comments,
        isLoadingComments: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoadingComments: false,
      );
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.deleteComment(commentId);
      // Remove comment from state
      final updatedComments = state.comments.where((c) => c.id != commentId).toList();
      state = state.copyWith(
        comments: updatedComments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Topic moderation
  Future<void> closeTopic(String topicId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.closeTopic(topicId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> deleteTopic(String topicId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _repository.deleteTopic(topicId);
      // Remove topic from state
      final updatedTopics = state.topics.where((t) => t.id != topicId).toList();
      state = state.copyWith(
        topics: updatedTopics,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }
}

final forumAdminNotifierProvider =
    StateNotifierProvider<ForumAdminNotifier, ForumAdminState>((ref) {
  final apiService = ref.watch(baseApiServiceProvider);
  final repo = ForumRepository(apiService);
  return ForumAdminNotifier(repo, ref);
});
