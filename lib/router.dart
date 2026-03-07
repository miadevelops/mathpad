import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'screens/screens.dart';

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const MenuScreen()),
    ),
    GoRoute(
      path: '/config',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const ConfigScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/exercise',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const ExerciseScreen()),
    ),
    GoRoute(
      path: '/results',
      pageBuilder: (context, state) {
        final result = state.extra as SessionResult?;
        return _fadeTransition(state, ResultsScreen(result: result));
      },
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const HistoryScreen()),
    ),
    GoRoute(
      path: '/achievements',
      pageBuilder: (context, state) =>
          _fadeTransition(state, const AchievementsScreen()),
    ),
  ],
);
