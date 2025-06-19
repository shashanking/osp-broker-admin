import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/utils/go_router_refresh_stream.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';
import 'package:osp_broker_admin/features/auth/domain/auth_state.dart';
import 'package:osp_broker_admin/features/auth/presentation/login_page.dart';
import 'package:osp_broker_admin/core/widgets/layout/dashboard_layout.dart';
import 'package:osp_broker_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:osp_broker_admin/features/forums/presentation/pages/forums_page.dart';
import 'package:osp_broker_admin/features/settings/presentation/settings_page.dart';
import 'package:osp_broker_admin/features/splash/presentation/splash_page.dart';
import 'package:osp_broker_admin/features/users/presentation/users_page.dart';

enum AppRoute {
  splash('/splash'),
  login('/login'),
  dashboard('/dashboard'),
  forums('/forums'),
  users('/users'),
  settings('/settings');

  final String path;
  const AppRoute(this.path);
}

class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String forums = '/forums';
  static const String users = '/users';
  static const String settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Create a stream controller for auth state changes
  final authStreamController = StreamController<AuthState>.broadcast();

  // Listen to auth state changes and add them to our stream
  ref.listen<AuthState>(
    authNotifierProvider,
    (_, next) => authStreamController.add(next),
  );

  final router = GoRouter(
    initialLocation: AppRoute.splash.path,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authStreamController.stream),
    routes: [
      // Public routes
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),

      // Dashboard shell with nested routes
      ShellRoute(
        pageBuilder: (context, state, child) {
          return MaterialPage(
            key: state.pageKey,
            child: DashboardLayout(
              currentRoute: state.uri.path,
              title: state.uri.path,
              onLogout: () async {
                final container = ProviderScope.containerOf(context);
                await container.read(authNotifierProvider.notifier).logout();
              },
              child: child,
            ),
          );
        },
        routes: [
          // Dashboard home
          GoRoute(
            path: AppRoute.dashboard.path,
            name: AppRoute.dashboard.name,
            pageBuilder: (context, state) => NoTransitionPage(
              child: DashboardPage(),
            ),
          ),

          // Forums section
          GoRoute(
            path: AppRoute.forums.path,
            name: AppRoute.forums.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ForumsPage(),
            ),
          ),
          
          // Users section
          GoRoute(
            path: AppRoute.users.path,
            name: AppRoute.users.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersPage(),
            ),
          ),

          // Settings section
          GoRoute(
            path: AppRoute.settings.path,
            name: AppRoute.settings.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final isSplash = state.matchedLocation == AppRoute.splash.path;
      final isLogin = state.matchedLocation == AppRoute.login.path;
      final isAuthenticatedRoute =
          state.matchedLocation.startsWith('/dashboard') ||
              state.matchedLocation.startsWith('/users') ||
              state.matchedLocation.startsWith('/settings');

      debugPrint(
          'Router: Current route: ${state.matchedLocation}, Auth state: $authState');

      return authState.when(
        // If we're on splash and authenticated, go to dashboard
        authenticated: (token, user) {
          if (isSplash || isLogin) {
            return AppRoute.dashboard.path;
          }
          return null;
        },
        // If we're on splash and unauthenticated, go to login
        unauthenticated: () {
          if (isSplash) return AppRoute.login.path;
          if (isAuthenticatedRoute) return AppRoute.login.path;
          return null;
        },
        // For any other state, stay on splash
        initial: () => isSplash ? null : AppRoute.splash.path,
        loading: () => isSplash ? null : AppRoute.splash.path,
        error: (message) => isLogin ? null : AppRoute.login.path,
      );
    },
  );
  // Close the stream when the provider is disposed
  ref.onDispose(() {
    authStreamController.close();
  });

  return router;
});
