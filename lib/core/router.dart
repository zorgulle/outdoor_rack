import 'package:go_router/go_router.dart';

import '../features/inventory/inventory_screen.dart';
import '../features/packs/packs_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/home_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/inventory',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/packs',
            builder: (context, state) => const PacksScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ]),
      ],
    ),
  ],
);