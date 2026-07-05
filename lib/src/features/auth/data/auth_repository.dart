import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../domain/auth_models.dart';
import 'auth_service.dart';

class AuthRepository {
  const AuthRepository(this._service, this._storage);
  final AuthService _service;
  final TokenStorage _storage;

  Future<User> login({required String email, required String password}) async {
    final result = await _service.login(email: email, password: password);
    await _persist(result);
    return result.user;
  }

  Future<User> register({required String name, required String email, required String password}) async {
    final result = await _service.register(name: name, email: email, password: password);
    await _persist(result);
    return result.user;
  }

  Future<void> logout() async {
    await _service.logout();
    await _storage.clear();
  }

  /// Restores the persisted user (cached from the last login), or null.
  Future<User?> restoreUser() async {
    final token = await _storage.readAccessToken();
    if (token == null) return null;
    final userJson = await _storage.readUser();
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(AuthResult result) async {
    await _storage.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
    await _storage.saveUser(jsonEncode({
      'id': result.user.id,
      'name': result.user.name,
      'email': result.user.email,
    }));
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authServiceProvider), ref.watch(tokenStorageProvider)),
);
