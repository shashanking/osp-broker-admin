import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'dio_provider.dart';
import 'hive_provider.dart';
import 'api_urls.dart';

final baseApiServiceProvider = Provider<BaseApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final authBox = ref.watch(authBoxProvider).value;
  return BaseApiService(dio, authBox!);
});

class BaseApiService {
  final Dio _dio;
  final Box _authBox;
  String? _authToken;

  BaseApiService(this._dio, this._authBox) {
    _authToken = _authBox.get('token') as String?;
  }

  // Getters
  String? get authToken {
    final token = _authBox.get('token');
    print('BaseApiService: Getting auth token: ${token != null ? 'Token exists' : 'No token found'}');
    return token;
  }
  bool get isAuthenticated => _authToken != null;

  // Token management
  Future<void> setAuthTokens({
    required String token,
    String? refreshToken,
  }) async {
    print('BaseApiService: Setting auth tokens');
    _authToken = token;
    try {
      await _authBox.put('token', token);
      print('BaseApiService: Auth token saved successfully');
      
      if (refreshToken != null) {
        await _authBox.put('refreshToken', refreshToken);
        print('BaseApiService: Refresh token saved successfully');
      }
    } catch (e) {
      print('BaseApiService: Error saving tokens: $e');
      rethrow;
    }
  }

  Future<void> clearAuthTokens() async {
    print('BaseApiService: Clearing auth tokens');
    _authToken = null;
    await _authBox.delete('token');
    await _authBox.delete('refreshToken');
  }

  // Request options with auth header
  Options _getOptions({Options? options, bool requireAuth = true}) {
    options ??= Options();
    if (requireAuth && _authToken != null) {
      options.headers ??= {};
      options.headers!['Authorization'] = 'Bearer $_authToken';
    }
    return options;
  }

  // HTTP Methods
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = true,
  }) async {
    try {
      final options = _getOptions(requireAuth: requireAuth);
      return await _dio.get(
        '${ApiUrls.baseUrl}$endpoint',
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    bool requireAuth = true,
  }) async {
    try {
      final options = _getOptions(requireAuth: requireAuth);
      return await _dio.post(
        '${ApiUrls.baseUrl}$endpoint',
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Error handling
  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      // Handle token expiration
      clearAuthTokens();
    }
  }
}
