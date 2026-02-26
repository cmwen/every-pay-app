import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/features/demo/providers/demo_mode_provider.dart';

/// Persistent banner shown at the top of the app during demo mode.
/// Lets the user know they're viewing demo data and provides an exit button.
class DemoBanner extends ConsumerWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoModeProvider);
    if (!demoState.isActive) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.science,
                size: 18,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You're exploring demo data",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onTertiaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () => _confirmExit(context, ref),
                child: const Text('Exit Demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Demo Mode?'),
        content: const Text(
          'This will return you to your real data. Demo data will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(demoModeProvider.notifier).deactivate();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
