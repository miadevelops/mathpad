import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'screens/screens.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/config',
      builder: (context, state) => const ConfigScreen(),
    ),
    GoRoute(
      path: '/exercise',
      builder: (context, state) {
        final config = state.extra as SessionConfig?;
        return ExerciseScreen(key: ValueKey(config));
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
  ],
);
