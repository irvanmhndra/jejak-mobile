import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/activity_detail_screen.dart';
import '../../features/activity/presentation/heatmap_screen.dart';
import '../../features/activity/presentation/home_screen.dart';
import '../../features/activity/presentation/manual_screen.dart';
import '../../features/activity/presentation/record_screen.dart';
import '../../features/activity/presentation/stats_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';

/// Declarative router with an auth guard. While the session is being restored
/// (AuthUnknown) we hold on the splash so no protected screen mounts early.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, next) => refresh.value = next);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/splash';
      switch (auth) {
        case AuthUnknown():
          return atSplash ? null : '/splash';
        case AuthUnauthenticated():
          return loggingIn ? null : '/login';
        case AuthAuthenticated():
          return (loggingIn || atSplash) ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/record', builder: (context, state) => const RecordScreen()),
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
      GoRoute(path: '/heatmap', builder: (context, state) => const HeatmapScreen()),
      GoRoute(path: '/manual', builder: (context, state) => const ManualScreen()),
      GoRoute(
        path: '/activities/:id',
        builder: (context, state) => ActivityDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
});
