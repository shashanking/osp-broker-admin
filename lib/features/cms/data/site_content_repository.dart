import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

final siteContentRepositoryProvider = Provider<SiteContentRepository>((ref) {
  return SiteContentRepository(ref.watch(baseApiServiceProvider));
});

class SiteContentRepository {
  final BaseApiService _api;

  SiteContentRepository(this._api);

  /// Loads the English source value for [type] (raw, no localization).
  /// Returns an empty map when the section hasn't been created yet.
  Future<Map<String, dynamic>> fetchSource(String type) async {
    try {
      final res = await _api.get(
        '/site-content/$type',
        queryParameters: {'raw': 'true'},
      );
      final content = res.data?['data']?['content'];
      if (content is Map && content['value'] is Map) {
        return Map<String, dynamic>.from(content['value'] as Map);
      }
      return {};
    } on DioException catch (e) {
      // 404 simply means the section hasn't been authored yet.
      if (e.response?.statusCode == 404) return {};
      throw Exception('Failed to load content: ${e.message}');
    }
  }

  /// Saves the English source for [type]; the backend auto-translates into all
  /// supported locales at save time.
  Future<void> save(String type, Map<String, dynamic> value) async {
    try {
      await _api.put('/site-content/$type', data: {'value': value});
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      throw Exception('Failed to save content: $msg');
    }
  }
}
