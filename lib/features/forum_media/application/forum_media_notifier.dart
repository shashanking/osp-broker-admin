import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../domain/forum_media_model.dart';
import 'forum_media_state.dart';

final forumMediaNotifierProvider =
    StateNotifierProvider<ForumMediaNotifier, ForumMediaState>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return ForumMediaNotifier(api);
});

class ForumMediaNotifier extends StateNotifier<ForumMediaState> {
  final BaseApiService _api;

  ForumMediaNotifier(this._api) : super(const ForumMediaState());

  Future<void> fetchMedia() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get(
        '/forum/media',
        queryParameters: {'all': 'true'},
        requireAuth: true,
      );
      final rawMedia = (response.data['data']?['media'] as List?) ?? const [];
      final media = rawMedia
          .whereType<Map>()
          .map((e) => ForumMediaModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      state = state.copyWith(items: media, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createMedia({
    required String title,
    String subtitle = '',
    String image = '',
    String link = '',
    int order = 0,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/forum/media',
        requireAuth: true,
        data: {
          'title': title,
          'subtitle': subtitle,
          'image': image,
          'link': link,
          'order': order,
          'isActive': isActive,
        },
      );
      await fetchMedia();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateMedia({
    required String id,
    required String title,
    String subtitle = '',
    String image = '',
    String link = '',
    int order = 0,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.put(
        '/forum/media/$id',
        requireAuth: true,
        data: {
          'title': title,
          'subtitle': subtitle,
          'image': image,
          'link': link,
          'order': order,
          'isActive': isActive,
        },
      );
      await fetchMedia();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> softDeleteMedia(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post(
        '/forum/media/softDelete/$id',
        requireAuth: true,
      );
      await fetchMedia();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteMedia(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.delete(
        '/forum/media/$id',
        requireAuth: true,
      );
      await fetchMedia();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
