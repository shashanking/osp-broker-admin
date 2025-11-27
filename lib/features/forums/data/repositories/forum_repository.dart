import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import '../../domain/forum_models.dart';
import '../../domain/poll_analytics_model.dart';

class ForumRepository {
  final BaseApiService _apiService;

  ForumRepository(this._apiService);

  Future<List<Forum>> fetchAllForums() async {
    final response = await _apiService.get('/forum');
    final forumsData = response.data['data']['forums'];

    // Handle different response structures
    if (forumsData is List) {
      final forums = forumsData
          .map((json) => Forum.fromJson(json as Map<String, dynamic>))
          .toList();
      return forums;
    } else if (forumsData is Map<String, dynamic>) {
      // If it's a single forum object, wrap it in a list
      final forums = [Forum.fromJson(forumsData)];
      return forums;
    } else {
      throw Exception('Unexpected forums data type: ${forumsData.runtimeType}');
    }
  }

  Future<List<Category>> fetchAllCategories() async {
    final response = await _apiService.get('/forum/categories');
    final categoriesData = response.data['data']['categories'];

    // Handle different response structures
    if (categoriesData is List) {
      final categories = categoriesData
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      return categories;
    } else if (categoriesData is Map<String, dynamic>) {
      // If it's a single category object, wrap it in a list
      final categories = [Category.fromJson(categoriesData)];
      return categories;
    } else {
      throw Exception('Unexpected categories data type: ${categoriesData.runtimeType}');
    }
  }

  Future<List<Topic>> fetchAllTopics({required String forumId}) async {
    final response = await _apiService
        .get('/forum/topics', queryParameters: {'forumId': forumId});
    final topicsData = response.data['data']['topics'];

    // Handle the nested structure: { pinnedTopics: [...], remainingTopics: [...] }
    if (topicsData is Map<String, dynamic>) {
      final pinnedTopics = topicsData['pinnedTopics'] as List<dynamic>? ?? [];
      final remainingTopics = topicsData['remainingTopics'] as List<dynamic>? ?? [];

      // Combine both lists
      final allTopics = [...pinnedTopics, ...remainingTopics];

      final topics = allTopics.map((json) {
        final jsonMap = json as Map<String, dynamic>;
        // Ensure comments is always a list
        if (jsonMap['comments'] != null && jsonMap['comments'] is! List) {
          jsonMap['comments'] = [jsonMap['comments']];
        } else if (jsonMap['comments'] == null) {
          jsonMap['comments'] = [];
        }
        return Topic.fromJson(jsonMap);
      }).toList();
      return topics;
    } else if (topicsData is List) {
      // Fallback for direct list format
      final topics = topicsData.map((json) {
        final jsonMap = json as Map<String, dynamic>;
        // Ensure comments is always a list
        if (jsonMap['comments'] != null && jsonMap['comments'] is! List) {
          jsonMap['comments'] = [jsonMap['comments']];
        } else if (jsonMap['comments'] == null) {
          jsonMap['comments'] = [];
        }
        return Topic.fromJson(jsonMap);
      }).toList();
      return topics;
    } else {
      throw Exception('Unexpected topics data type: ${topicsData.runtimeType}');
    }
  }

  // Announcements
  Future<List<Announcement>> fetchAllAnnouncements() async {
    final response = await _apiService.get('/announcement');
    final announcementsData = response.data['data'];

    // Handle different response structures
    if (announcementsData is List) {
      return announcementsData
          .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (announcementsData is Map<String, dynamic>) {
      // If it's a single announcement object, wrap it in a list
      return [Announcement.fromJson(announcementsData)];
    } else {
      throw Exception('Unexpected announcements data type: ${announcementsData.runtimeType}');
    }
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String description,
  }) async {
    final response = await _apiService.post(
      '/announcement',
      requireAuth: true,
      data: {
        'title': title,
        'description': description,
      },
    );
    return Announcement.fromJson(response.data['data']);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _apiService.delete(
      '/announcement/$id',
      requireAuth: true,
    );
  }

  // Events
  Future<List<Event>> fetchAllEvents() async {
    final response = await _apiService.get('/event');
    final eventsData = response.data['data'];

    // Handle different response structures
    if (eventsData is List) {
      return eventsData
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (eventsData is Map<String, dynamic>) {
      // If it's a single event object, wrap it in a list
      return [Event.fromJson(eventsData)];
    } else {
      throw Exception('Unexpected events data type: ${eventsData.runtimeType}');
    }
  }

  Future<Event> createEvent({
    required String title,
    required String description,
    required String date,
  }) async {
    final response = await _apiService.post(
      '/event',
      requireAuth: true,
      data: {
        'title': title,
        'description': description,
        'date': date,
      },
    );
    return Event.fromJson(response.data['data']['event']);
  }

  Future<void> deleteEvent(String eventId) async {
    await _apiService.delete(
      '/event/$eventId',
      requireAuth: true,
    );
  }

  // Polls
  Future<List<Poll>> fetchAllPolls() async {
    final response = await _apiService.get('/poll');
    final pollsData = response.data['data'];

    // Handle different response structures
    if (pollsData is List) {
      return pollsData
          .map((json) => Poll.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (pollsData is Map<String, dynamic>) {
      // If it's a single poll object, wrap it in a list
      return [Poll.fromJson(pollsData)];
    } else {
      throw Exception('Unexpected polls data type: ${pollsData.runtimeType}');
    }
  }

  // Category CRUD
  Future<Category> createCategory({
    required String name,
    required String description,
    String? moderatorId,
    required String icon,
    required List<String> membershipAccess,
  }) async {
    final response = await _apiService.post(
      '/forum/category',
      requireAuth: true,
      data: {
        'name': name,
        'description': description,
        if (moderatorId != null) 'moderatorId': moderatorId,
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
    if (response.data is Map &&
        response.data['message'] == 'unauthorized access') {
      throw Exception('unauthorized access');
    }
  }

  Future<Poll> createPoll({
    required String question,
    required List<String> options,
  }) async {
    final response = await _apiService.post(
      '/poll',
      requireAuth: true,
      data: {
        'question': question,
        'options': options,
      },
    );
    return Poll.fromJson(response.data['data']['poll']);
  }

  Future<void> deletePoll(String pollId) async {
    await _apiService.delete('/poll/$pollId', requireAuth: true);
  }

  Future<PollAnalytics> fetchPollAnalytics(String pollId) async {
    final response = await _apiService.get(
      '/poll/analytics/$pollId',
      requireAuth: true,
    );
    return PollAnalytics.fromJson(response.data['data']);
  }

  // Comments
  Future<List<Comment>> fetchCommentsForTopic(String topicId) async {
    final response = await _apiService.get('/forum/comments/$topicId');
    final responseData = response.data;

    if (responseData['success'] == true) {
      final commentsData = responseData['data']['comment'] as List;
      return commentsData
          .map((json) => Comment.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch comments: ${responseData['message']}');
    }
  }

  Future<void> deleteComment(String commentId) async {
    await _apiService.delete(
      '/forum/comment/$commentId',
      requireAuth: true,
    );
  }

  // Topic moderation
  Future<void> closeTopic(String topicId) async {
    await _apiService.post(
      '/forum/topic/closeTopic/$topicId',
      requireAuth: true,
    );
  }

  Future<void> deleteTopic(String topicId) async {
    await _apiService.delete(
      '/forum/topic/$topicId',
      requireAuth: true,
    );
  }
}
