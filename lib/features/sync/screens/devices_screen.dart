import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:everypay/domain/entities/paired_device.dart';
import 'package:everypay/features/sync/providers/sync_providers.dart';
import 'package:everypay/features/sync/widgets/sync_status_banner.dart';
import 'package:everypay/shared/widgets/empty_state.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairedDevices = ref.watch(pairedDevicesProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    // Listen for sync status changes to show snackbars.
    ref.listen(syncStatusProvider, (prev, next) {
      if (next.phase == SyncPhase.complete) {
        final r = next.result;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${r?.expensesSynced ?? 0} expenses, '
              '${r?.categoriesSynced ?? 0} categories',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(syncStatusProvider.notifier).reset();
      } else if (next.phase == SyncPhase.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Sync failed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(syncStatusProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Paired Devices')),
      body: Column(
        children: [
          // Sync status banner
          const SyncStatusBanner(),
          if (syncStatus.phase == SyncPhase.connecting ||
              syncStatus.phase == SyncPhase.syncing)
            const LinearProgressIndicator(),

          // Paired devices list
          Expanded(
            child: pairedDevices.when(
              data: (devices) => devices.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.devices,
                      title: 'No paired devices',
                      subtitle:
                          'Pair with another device to sync your expense '
                          'data.\nBoth devices must be on the same Wi-Fi '
                          'network.',
                    )
                  : _DeviceList(devices: devices),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading devices: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/settings/devices/pair'),
        icon: const Icon(Icons.add),
        label: const Text('Pair Device'),
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<PairedDevice> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _DeviceCard(device: device);
      },
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device});

  final PairedDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncStatus = ref.watch(syncStatusProvider);
    final isSyncing =
        (syncStatus.phase == SyncPhase.connecting ||
            syncStatus.phase == SyncPhase.syncing) &&
        syncStatus.deviceName == device.deviceName;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.phone_android,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(device.deviceName),
        subtitle: Text(
          'Last synced: ${_formatLastSeen(device.lastSeen)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync Now',
              onPressed: isSyncing
                  ? null
                  : () {
                      ref
                          .read(syncStatusProvider.notifier)
                          .syncWithDevice(device);
                    },
            ),
            PopupMenuButton<_DeviceAction>(
              onSelected: (action) {
                switch (action) {
                  case _DeviceAction.unpair:
                    _showUnpairDialog(context, ref, device);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _DeviceAction.unpair,
                  child: Row(
                    children: [
                      Icon(Icons.link_off, size: 20),
                      SizedBox(width: 8),
                      Text('Unpair'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onLongPress: () => _showUnpairDialog(context, ref, device),
      ),
    );
  }

  void _showUnpairDialog(
    BuildContext context,
    WidgetRef ref,
    PairedDevice device,
  ) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device'),
        content: Text(
          'Are you sure you want to unpair "${device.deviceName}"?\n\n'
          'You will need to pair again to sync with this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(pairedDevicesRepositoryProvider)
                  .deletePairedDevice(device.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.deviceName} unpaired'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
  }
}

enum _DeviceAction { unpair }

String _formatLastSeen(DateTime? lastSeen) {
  if (lastSeen == null) return 'Never';

  final now = DateTime.now();
  final difference = now.difference(lastSeen);

  if (difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hours ago';
  if (difference.inDays < 30) return '${difference.inDays} days ago';
  return '${(difference.inDays / 30).floor()} months ago';
}
