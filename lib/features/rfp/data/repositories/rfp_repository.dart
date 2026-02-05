import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/features/rfp/domain/rfp_model.dart';

final rfpRepositoryProvider = Provider<RfpRepository>((ref) {
  final api = ref.watch(baseApiServiceProvider);
  return RfpRepository(api);
});

class RfpRepository {
  final BaseApiService _api;

  RfpRepository(this._api);

  static const String _basePath = '/RFP';

  Future<List<RfpModel>> fetchRfps() async {
    try {
      final response = await _api.get(_basePath, requireAuth: true);
      final data = response.data;
      final raw = (data is Map) ? data['data'] : null;

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => RfpModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      return const <RfpModel>[];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <RfpModel>[];
      }
      throw Exception('Failed to fetch RFPs: ${e.message}');
    }
  }

  Future<RfpModel?> fetchRfpById(String id) async {
    try {
      final response = await _api.get('$_basePath/$id', requireAuth: true);
      final data = response.data;
      final raw = (data is Map) ? data['data'] : null;

      if (raw is Map) {
        return RfpModel.fromJson(Map<String, dynamic>.from(raw));
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Failed to fetch RFP: ${e.message}');
    }
  }
}
