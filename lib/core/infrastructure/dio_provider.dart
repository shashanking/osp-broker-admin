import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://osp-broker.vercel.app/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  );

  // Add request interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // Add request logging
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      print(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      return handler.next(response);
    },
    onError: (e, handler) async {
      // Handle 401 Unauthorized
      if (e.response?.statusCode == 401) {
        // TODO: Handle token refresh if needed
      }
      return handler.next(e);
    },
  ));

  return dio;
});
