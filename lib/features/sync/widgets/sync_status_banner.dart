import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everypay/features/sync/providers/sync_providers.dart';

/// A compact banner that shows the current sync status.
///
/// Displays a coloured strip with a small spinner and descriptive text while a
/// sync operation is connecting or actively syncing. Collapses to [SizedBox.shrink]
/// in all other phases (idle, complete, error) because those are handled via
/// [SnackBar] in the parent screen.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);

    return switch (status.phase) {
      SyncPhase.idle => const SizedBox.shrink(),
      SyncPhase.connecting => _buildBanner(
        context,
        'Connecting to ${status.deviceName ?? "device"}…',
        showProgress: true,
      ),
      SyncPhase.syncing => _buildBanner(
        context,
        'Syncing with ${status.deviceName ?? "device"}…',
        showProgress: true,
      ),
      // Complete & error are surfaced as SnackBars by the parent.
      SyncPhase.complete => const SizedBox.shrink(),
      SyncPhase.error => const SizedBox.shrink(),
    };
  }

  Widget _buildBanner(
    BuildContext context,
    String text, {
    bool showProgress = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          if (showProgress) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
