import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/features/home/screens/home_screen.dart';
import 'package:everypay/features/stats/screens/stats_screen.dart';
import 'package:everypay/features/settings/screens/settings_screen.dart';
import 'package:everypay/features/settings/screens/categories_screen.dart';
import 'package:everypay/features/settings/screens/export_screen.dart';
import 'package:everypay/features/settings/screens/security_screen.dart';
import 'package:everypay/features/sync/screens/devices_screen.dart';
import 'package:everypay/features/expense/screens/add_expense_screen.dart';
import 'package:everypay/features/expense/screens/expense_detail_screen.dart';
import 'package:everypay/features/expense/screens/edit_expense_screen.dart';
import 'package:everypay/features/expense/screens/service_library_screen.dart';
import 'package:everypay/shared/widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _statsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'stats');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Home tab
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'expense/add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddExpenseScreen(),
                  routes: [
                    GoRoute(
                      path: 'library',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const ServiceLibraryScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'expense/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      ExpenseDetailScreen(id: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          EditExpenseScreen(id: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Stats tab
        StatefulShellBranch(
          navigatorKey: _statsNavigatorKey,
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        // Settings tab
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'categories',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CategoriesScreen(),
                ),
                GoRoute(
                  path: 'export',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ExportScreen(),
                ),
                GoRoute(
                  path: 'security',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const SecurityScreen(),
                ),
                GoRoute(
                  path: 'devices',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const DevicesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
