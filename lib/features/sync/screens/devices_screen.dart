import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/shared/widgets/empty_state.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paired Devices')),
      body: const EmptyStateView(
        icon: Icons.devices,
        title: 'No paired devices',
        subtitle:
            'Pair with another device to sync your expense data.\n'
            'Both devices must be on the same Wi-Fi network.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pair New Device'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'P2P sync pairing requires both devices on the '
                    'same local network.\n\n'
                    'Steps:\n'
                    '1. Open Every-Pay on both devices\n'
                    '2. Go to Settings → Devices on both\n'
                    '3. One device shows a QR code\n'
                    '4. The other scans it to pair\n\n'
                    'Full P2P sync will be available in a future update.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Pair Device'),
      ),
    );
  }
}
