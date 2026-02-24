import 'package:flutter/material.dart';
import 'package:everypay/shared/widgets/empty_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: const EmptyStateView(
        icon: Icons.bar_chart,
        title: 'Statistics coming soon',
        subtitle:
            'Add some expenses first to see your spending stats.\nFull statistics will be available in V0.5.',
      ),
    );
  }
}
