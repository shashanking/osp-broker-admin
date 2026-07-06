import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/reports/domain/flagged_content_report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final baseApiService = ref.watch(baseApiServiceProvider);
  return ReportsRepository(baseApiService);
});

class ReportsRepository {
  final BaseApiService _apiService;

  ReportsRepository(this._apiService);

  Future<List<FlaggedContentReport>> fetchReports() async {
    try {
      final response = await _apiService.get('/flag', requireAuth: true);
      final data = response.data;
      final raw = (data is Map) ? data['data'] : null;

      if (raw is List) {
        return raw
            .map(
              (e) => FlaggedContentReport.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }

      if (raw is Map) {
        return [FlaggedContentReport.fromJson(Map<String, dynamic>.from(raw))];
      }

      return const <FlaggedContentReport>[];
    } on DioException catch (e) {
      throw Exception('Failed to fetch reports: ${e.message}');
    }
  }

  // Removed fetchCommentReports() - use fetchReports() instead which fetches all flagged content

  Future<List<FlaggedContentReport>> fetchCommentReportsForTopic(
    String topicId,
  ) async {
    try {
      final response = await _apiService.get(
        '/flag/topic/$topicId/comments',
        requireAuth: true,
      );
      final data = response.data;
      final raw = (data is Map) ? data['data'] : null;

      if (raw is List) {
        return raw
            .map(
              (e) => FlaggedContentReport.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }

      if (raw is Map) {
        return [FlaggedContentReport.fromJson(Map<String, dynamic>.from(raw))];
      }

      return const <FlaggedContentReport>[];
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch comment reports for topic: ${e.message}',
      );
    }
  }

  Future<FlaggedContentReport> fetchReportById(String id) async {
    try {
      final response = await _apiService.get('/flag/$id', requireAuth: true);
      final data = response.data;
      final raw = (data is Map) ? data['data'] : null;

      if (raw is Map) {
        return FlaggedContentReport.fromJson(Map<String, dynamic>.from(raw));
      }

      throw Exception('Invalid report response');
    } on DioException catch (e) {
      throw Exception('Failed to fetch report: ${e.message}');
    }
  }
}
