// Repository for the business-directory scraper. Talks to /scraper/* on the
// osp-broker-api. All endpoints require ADMIN or MODERATOR.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/bd_scraper/domain/scraper_models.dart';

final scraperRepositoryProvider = Provider<ScraperRepository>((ref) {
  return ScraperRepository(ref.watch(baseApiServiceProvider));
});

class ScraperRepository {
  final BaseApiService _api;
  ScraperRepository(this._api);

  Map<String, dynamic> _unwrap(Response res) {
    final body = res.data;
    if (body is Map && body['data'] != null) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  Future<ScrapeJob> createJob({
    required String category,
    String? state,
    String? city,
    int targetCount = 25,
  }) async {
    try {
      final res = await _api.post('/scraper/jobs', data: {
        'category': category,
        if (state != null && state.isNotEmpty) 'locationState': state,
        if (city != null && city.isNotEmpty) 'locationCity': city,
        'targetCount': targetCount,
      });
      return ScrapeJob.fromJson(_unwrap(res));
    } on DioException catch (e) {
      throw Exception('Failed to start scrape: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  Future<PagedList<ScrapeJob>> listJobs({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _api.get('/scraper/jobs', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      final data = _unwrap(res);
      final items = (data['items'] as List? ?? const [])
          .map((e) => ScrapeJob.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return PagedList<ScrapeJob>(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        pageSize: (data['pageSize'] as num?)?.toInt() ?? pageSize,
      );
    } on DioException catch (e) {
      throw Exception('Failed to load jobs: ${e.message}');
    }
  }

  Future<ScrapeJob> getJob(String id) async {
    try {
      final res = await _api.get('/scraper/jobs/$id');
      return ScrapeJob.fromJson(_unwrap(res));
    } on DioException catch (e) {
      throw Exception('Failed to load job: ${e.message}');
    }
  }

  Future<PagedList<ScrapedBusiness>> listPending({
    ScrapedBusinessStatus status = ScrapedBusinessStatus.pending,
    String? jobId,
    String? state,
    String? search,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final res = await _api.get('/scraper/pending', queryParameters: {
        'status': scrapedBusinessStatusToApi(status),
        if (jobId != null) 'jobId': jobId,
        if (state != null && state.isNotEmpty) 'state': state,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'pageSize': pageSize,
      });
      final data = _unwrap(res);
      final items = (data['items'] as List? ?? const [])
          .map((e) => ScrapedBusiness.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return PagedList<ScrapedBusiness>(
        items: items,
        total: (data['total'] as num?)?.toInt() ?? items.length,
        page: (data['page'] as num?)?.toInt() ?? page,
        pageSize: (data['pageSize'] as num?)?.toInt() ?? pageSize,
      );
    } on DioException catch (e) {
      throw Exception('Failed to load pending records: ${e.message}');
    }
  }

  Future<ScrapedBusiness> updatePending(String id, Map<String, dynamic> patch) async {
    try {
      final res = await _api.put('/scraper/pending/$id', data: patch);
      return ScrapedBusiness.fromJson(_unwrap(res));
    } on DioException catch (e) {
      throw Exception('Failed to update record: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> approve(String id, {required String businessCategoryId, Map<String, dynamic>? overrides}) async {
    try {
      final res = await _api.post('/scraper/pending/$id/approve', data: {
        'businessCategoryId': businessCategoryId,
        if (overrides != null) 'overrides': overrides,
      });
      return _unwrap(res);
    } on DioException catch (e) {
      throw Exception('Approve failed: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  Future<List<dynamic>> bulkApprove(List<String> ids, String businessCategoryId) async {
    try {
      final res = await _api.post('/scraper/pending/bulk-approve', data: {
        'ids': ids,
        'businessCategoryId': businessCategoryId,
      });
      // bulk-approve's `data` is an array, not an object — bypass _unwrap.
      final body = res.data;
      if (body is Map && body['data'] is List) return List<dynamic>.from(body['data'] as List);
      if (body is List) return List<dynamic>.from(body);
      return const [];
    } on DioException catch (e) {
      throw Exception('Bulk approve failed: ${e.message}');
    }
  }

  Future<ScrapedBusiness> reject(String id, String reason) async {
    try {
      final res = await _api.post('/scraper/pending/$id/reject', data: {'reason': reason});
      return ScrapedBusiness.fromJson(_unwrap(res));
    } on DioException catch (e) {
      throw Exception('Reject failed: ${e.message}');
    }
  }
}
