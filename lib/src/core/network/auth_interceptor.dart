import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the bearer token to every request and, on a 401, transparently
/// refreshes it once and retries the original request. If refresh fails, it
/// clears the session and notifies via [onSessionExpired].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.baseUrl,
    required this.onSessionExpired,
  });

  final TokenStorage storage;
  final String baseUrl;
  final void Function() onSessionExpired;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');

    if (isUnauthorized && !isRefreshCall) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        try {
          final response = await _retry(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (_) {
          // fall through to session-expired handling
        }
      }
      await storage.clear();
      onSessionExpired();
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final res = await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      final data = res.data['data'] as Map<String, dynamic>;
      await storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await storage.readAccessToken();
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
      ),
    );
  }
}
