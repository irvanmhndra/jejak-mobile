import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// ViewModel for auth. Restores the session on start and exposes login/logout.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthUnknown();
  }

  Future<void> _restore() async {
    final user = await ref.read(authRepositoryProvider).restoreUser();
    state = user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = AuthAuthenticated(user);
  }

  Future<void> register({required String name, required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .register(name: name, email: email, password: password);
    state = AuthAuthenticated(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthUnauthenticated();
  }

  /// Invoked by the network layer when a token refresh fails.
  void sessionExpired() => state = const AuthUnauthenticated();
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
