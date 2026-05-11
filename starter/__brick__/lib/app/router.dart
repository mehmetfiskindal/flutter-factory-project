{{#is_bloc}}{{#include_auth}}import 'dart:async';

{{/include_auth}}
{{/is_bloc}}
import 'package:flutter/material.dart';
{{#is_riverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/is_riverpod}}
import 'package:go_router/go_router.dart';

import '../core/router/app_shell.dart';
import '../core/router/route_paths.dart';
{{#is_riverpod}}{{#include_auth}}
import '../features/auth/presentation/providers/auth_controller.dart';
{{/include_auth}}{{/is_riverpod}}{{#is_bloc}}{{#include_auth}}import '../features/auth/presentation/controllers/auth_bloc.dart';
{{/include_auth}}{{/is_bloc}}
{{#include_auth}}
import '../features/auth/presentation/views/sign_in_view.dart';
{{/include_auth}}
import '../features/home/presentation/views/home_view.dart';
import '../features/settings/presentation/views/settings_view.dart';
// flutter_factory: route-imports-start
// flutter_factory: route-imports-end

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

{{#is_riverpod}}
final appRouterProvider = Provider<GoRouter>((ref) {
  {{#include_auth}}
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  {{/include_auth}}
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.home,
    {{#include_auth}}
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      if (authState.isLoading && !authState.hasValue) {
        return null;
      }

      final isSignedIn = authState.valueOrNull != null;
      final isSigningIn = state.matchedLocation == RoutePaths.signIn;

      if (!isSignedIn && !isSigningIn) {
        return RoutePaths.signIn;
      }

      if (isSignedIn && isSigningIn) {
        return RoutePaths.home;
      }

      return null;
    },
    {{/include_auth}}
    routes: [
      {{#include_auth}}
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInView(),
      ),
      {{/include_auth}}
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            builder: (context, state) => const SettingsView(),
          ),
          // flutter_factory: shell-routes-start
          // flutter_factory: shell-routes-end
        ],
      ),
    ],
  );
});

{{#include_auth}}
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AsyncValue<Object?>>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<Object?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
{{/include_auth}}
{{/is_riverpod}}{{#is_bloc}}
GoRouter createAppRouter({{#include_auth}}AuthBloc authBloc{{/include_auth}}) {
  {{#include_auth}}
  final refreshNotifier = GoRouterBlocRefreshNotifier(authBloc);

  {{/include_auth}}
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.home,
    {{#include_auth}}
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = authBloc.state;

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      final isSignedIn = authState is AuthAuthenticated;
      final isSigningIn = state.matchedLocation == RoutePaths.signIn;

      if (!isSignedIn && !isSigningIn) {
        return RoutePaths.signIn;
      }

      if (isSignedIn && isSigningIn) {
        return RoutePaths.home;
      }

      return null;
    },
    {{/include_auth}}
    routes: [
      {{#include_auth}}
      GoRoute(
        path: RoutePaths.signIn,
        name: RouteNames.signIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInView(),
      ),
      {{/include_auth}}
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            builder: (context, state) => const SettingsView(),
          ),
          // flutter_factory: shell-routes-start
          // flutter_factory: shell-routes-end
        ],
      ),
    ],
  );
}

{{#include_auth}}
class GoRouterBlocRefreshNotifier extends ChangeNotifier {
  GoRouterBlocRefreshNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
{{/include_auth}}
{{/is_bloc}}
