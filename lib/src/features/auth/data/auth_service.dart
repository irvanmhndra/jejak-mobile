import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/auth_models.dart';

class AuthService {
  const AuthService(this._dio);
  final Dio _dio;

  Future<AuthResult> login({required String email, required String password}) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _post('/auth/register', {'name': name, 'email': email, 'password': password});

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return AuthResult.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>('/auth/logout');
    } on DioException {
      // best-effort; local session is cleared regardless
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(dioProvider)));
