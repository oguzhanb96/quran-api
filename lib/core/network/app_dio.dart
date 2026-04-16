import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppPreferences.getVpsBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['x-app-platform'] = 'flutter';
        options.headers['x-app-version'] = '1.0.1';
        final token = AppPreferences.getAuthToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final retryCount = (request.extra['retry_count'] as int?) ?? 0;
        final canRetry =
            retryCount < 2 &&
            (request.method == 'GET' || request.method == 'POST') &&
            (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.connectionError);
        if (!canRetry) {
          handler.next(error);
          return;
        }

        request.extra['retry_count'] = retryCount + 1;
        await Future<void>.delayed(
          Duration(milliseconds: 350 * (retryCount + 1)),
        );
        try {
          final response = await dio.fetch(request);
          handler.resolve(response);
        } catch (_) {
          handler.next(error);
        }
      },
    ),
  );
  return dio;
});
