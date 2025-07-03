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

  String? get userId => _authBox.get('userId') as String?;

  // Token management
  Future<void> setAuthTokens({
    required String token,
    String? refreshToken,
    String? userId,
  }) async {
    _authToken = token;
    try {
      await _authBox.put('token', token);
      await _authBox.put('userId', userId);
      
      if (refreshToken != null) {
        await _authBox.put('refreshToken', refreshToken);
      }
    } catch (e) {
      print('BaseApiService: Error saving tokens: $e');
      rethrow;
    }
  }

  Future<void> clearAuthTokens() async {
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

  Future<Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final options = _getOptions(requireAuth: requireAuth);
      return await _dio.delete(
        '${ApiUrls.baseUrl}$endpoint',
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

  Future<Response> put(
    String endpoint, {
    dynamic data,
    bool requireAuth = true,
  }) async {
    try {
      final options = _getOptions(requireAuth: requireAuth);
      return await _dio.put(
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
    final response = e.response;
    final statusCode = response?.statusCode;
    
    if (statusCode == 401) {
      // Handle token expiration
      clearAuthTokens();
    }
    
    // Log detailed error information
    print('''
    === API Error ===
    URL: ${e.requestOptions.uri}
    Method: ${e.requestOptions.method}
    Status Code: $statusCode
    Error: ${e.message}
    Response: ${response?.data}
    Headers: ${e.requestOptions.headers}
    =================
    ''');
    
    // Rethrow with more detailed message
    if (statusCode == 500) {
      throw Exception('Server error (500): ${response?.data?['message'] ?? 'Internal server error occurred'}');
    } else if (response?.data is Map && response?.data['message'] != null) {
      throw Exception(response?.data['message']);
    } else {
      throw Exception('Request failed with status $statusCode: ${e.message}');
    }
  }
}
