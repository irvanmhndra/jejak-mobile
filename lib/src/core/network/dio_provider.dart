import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../../features/auth/presentation/auth_controller.dart';
import 'auth_interceptor.dart';

/// The single configured Dio instance for the app. Any service depends on this
/// provider rather than constructing its own client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      storage: ref.watch(tokenStorageProvider),
      baseUrl: AppConfig.apiBaseUrl,
      onSessionExpired: () => ref.read(authControllerProvider.notifier).sessionExpired(),
    ),
  );

  return dio;
});
