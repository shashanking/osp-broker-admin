import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'api_urls.dart';
import 'dio_provider.dart';
import 'hive_provider.dart';

final baseApiServiceProvider = Provider<BaseApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final authBox = ref.watch(authBoxProvider).value;
  return BaseApiService(dio, authBox!);
});

class BaseApiService {
  final Dio _dio;
  final Box _authBox;
  String? _authToken;
  bool _isRefreshingToken = false;

  BaseApiService(this._dio, this._authBox) {
    _authToken = _authBox.get('token') as String?;
  }

  // Getters
  String? get authToken {
    final token = _authBox.get('token');
    print(
        'BaseApiService: Getting auth token: ${token != null ? 'Token exists' : 'No token found'}');
    return token;
  }

  bool get isAuthenticated => _authToken != null;

  String? get userId => _authBox.get('userId') as String?;

  Map<String, dynamic>? get authUser {
    final user = _authBox.get('user');
    if (user is Map) {
      return user.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

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

  Future<void> setAuthUser(Map<String, dynamic> user) async {
    try {
      await _authBox.put('user', user);
    } catch (e) {
      print('BaseApiService: Error saving user: $e');
      rethrow;
    }
  }

  bool _isJwtExpiredError(DioException e) {
    // Do NOT treat every 401 as an expired JWT.
    // Many endpoints return 401 for authorization failures (e.g. wrong role).

    final data = e.response?.data;
    if (data is Map) {
      final message = data['message']?.toString().toLowerCase();
      if (message != null && message.contains('jwt expired')) return true;

      // Some backends use a generic error field.
      final error = data['error']?.toString().toLowerCase();
      if (error != null && error.contains('jwt expired')) return true;

      final errorSource = data['errorSourse'] ?? data['errorSource'];
      if (errorSource is List) {
        for (final item in errorSource) {
          if (item is Map) {
            final m = item['message']?.toString().toLowerCase();
            if (m != null && m.contains('jwt expired')) return true;
          }
        }
      }
    }

    // Some servers incorrectly return 500 for expired JWT, but message indicates it.
    // If it's a 401/500 without the explicit message above, do not refresh.

    return false;
  }

  Future<void> clearAuthTokens() async {
    _authToken = null;
    await _authBox.delete('token');
    await _authBox.delete('refreshToken');
    await _authBox.delete('user');
    await _authBox.delete('userId');
  }

  // Check if we have a refresh token
  String? get _refreshToken => _authBox.get('refreshToken') as String?;

  // Refresh token using direct API call to avoid circular dependency
  Future<bool> _refreshAccessToken() async {
    if (_isRefreshingToken) return false;

    final refreshToken = _refreshToken;
    if (refreshToken == null) return false;

    _isRefreshingToken = true;
    try {
      // Make direct API call to refresh token endpoint
      final response = await _dio.post(
        '${ApiUrls.baseUrl}${ApiUrls.refreshToken}',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['data']['accessToken'];
        await setAuthTokens(token: newToken);
        return true;
      }
      return false;
    } catch (e) {
      print('BaseApiService: Token refresh failed: $e');
      return false;
    } finally {
      _isRefreshingToken = false;
    }
  }

  // Request options with auth header
  Options _getOptions({Options? options, bool requireAuth = true}) {
    options ??= Options();
    // Always read the latest token from storage to avoid stale in-memory cache.
    final token = _authBox.get('token') as String?;
    _authToken = token;

    if (requireAuth && token != null) {
      options.headers ??= {};
      options.headers!['Authorization'] = 'Bearer $token';
    }
    return options;
  }

  // HTTP Methods with automatic retry on token refresh
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
      return await _handleDioErrorWithRetry(
          e,
          () => get(endpoint,
              queryParameters: queryParameters, requireAuth: requireAuth));
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
      return await _handleDioErrorWithRetry(
          e, () => delete(endpoint, requireAuth: requireAuth));
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
      return await _handleDioErrorWithRetry(
          e, () => post(endpoint, data: data, requireAuth: requireAuth));
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
      return await _handleDioErrorWithRetry(
          e, () => put(endpoint, data: data, requireAuth: requireAuth));
    }
  }

  // Enhanced error handling with token refresh
  Future<Response> _handleDioErrorWithRetry(
      DioException e, Future<Response> Function() retryFunction) async {
    // Token expiry is sometimes returned by the backend as 500 with message `jwt expired`
    if (_isJwtExpiredError(e)) {
      // Check if we have a refresh token and haven't already tried refreshing
      if (_refreshToken != null && !_isRefreshingToken) {
        print('BaseApiService: Token expired (401), attempting to refresh...');

        // Try to refresh the token
        final refreshSuccess = await _refreshAccessToken();

        if (refreshSuccess) {
          print(
              'BaseApiService: Token refreshed successfully, retrying original request...');
          try {
            // Retry the original request with the new token
            return await retryFunction();
          } catch (retryError) {
            print('BaseApiService: Retry after refresh failed: $retryError');
            // If retry fails, fall through to error handling
          }
        } else {
          print('BaseApiService: Token refresh failed');
          // Clear tokens if refresh failed
          await clearAuthTokens();
        }
      } else {
        print(
            'BaseApiService: No refresh token available or already refreshing');
        // Clear tokens if no refresh token or already refreshing
        await clearAuthTokens();
      }
    }

    // Handle other errors normally
    _handleDioError(e);
    throw e; // Throw the original exception instead of rethrow
  }

  // Error handling
  void _handleDioError(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;

    if (statusCode == 401) {
      // Only clear tokens if the request actually attempted authenticated access.
      // When there is no Authorization header, this 401 is typically due to being
      // logged out (or token not yet loaded) and clearing again is unnecessary.
      final headers = e.requestOptions.headers;
      final authHeader = headers['Authorization']?.toString();
      if (authHeader != null && authHeader.isNotEmpty) {
        // Handle token expiration (already handled above, but keeping for consistency)
        clearAuthTokens();
      }
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
      throw Exception(
          'Server error (500): ${response?.data?['message'] ?? 'Internal server error occurred'}');
    } else if (response?.data is Map && response?.data['message'] != null) {
      throw Exception(response?.data['message']);
    } else {
      throw Exception('Request failed with status $statusCode: ${e.message}');
    }
  }
}
