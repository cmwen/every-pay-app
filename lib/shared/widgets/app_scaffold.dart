import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/features/demo/providers/demo_mode_provider.dart';
import 'package:everypay/features/demo/widgets/demo_banner.dart';
import 'package:everypay/features/demo/widgets/tour_overlay.dart';
import 'package:everypay/features/demo/widgets/tour_step_config.dart';

class AppScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoModeProvider);
    final registry = TourTargetRegistry.instance;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const DemoBanner(),
              Expanded(child: navigationShell),
            ],
          ),
          if (demoState.isTourActive) const TourOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            key: registry.statsNavKey,
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
