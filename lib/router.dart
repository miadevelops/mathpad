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
        return const ExerciseScreen();
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final result = state.extra as SessionResult?;
        return ResultsScreen(result: result);
      },
    ),
  ],
);
