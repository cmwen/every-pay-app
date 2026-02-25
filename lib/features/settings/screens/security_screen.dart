import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/features/settings/providers/security_provider.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAsync = ref.watch(biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          _SectionHeader(title: 'APP LOCK'),
          biometricAsync.when(
            data: (enabled) => SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Lock'),
              subtitle: const Text('Require fingerprint or face to open app'),
              value: enabled,
              onChanged: (value) => _onToggle(context, ref, value),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.fingerprint),
              title: Text('Biometric Lock'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    error: (_, _) => ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Lock'),
              subtitle: const Text('Unavailable on this device'),
              enabled: false,
            ),
          ),
          _SectionHeader(title: 'DATA PROTECTION'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Database Encryption'),
            subtitle: const Text('SQLCipher encryption (planned)'),
            trailing: Chip(
              label: Text(
                'Planned',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('End-to-End Encryption'),
            subtitle: const Text('AES-256-GCM for sync data (planned)'),
            trailing: Chip(
              label: Text(
                'Planned',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      // Verify biometric works before enabling.
      final service = ref.read(biometricServiceProvider);
      final canAuth = await service.canAuthenticate();
      if (!canAuth) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No biometric hardware available on this device.'),
            ),
          );
        }
        return;
      }
      final authenticated = await service.authenticate(
        reason: 'Confirm your identity to enable Biometric Lock',
      );
      if (!authenticated) return;
    }
    await ref.read(biometricEnabledProvider.notifier).setEnabled(enable);
    // Ensure app stays unlocked after toggling.
    ref.read(appLockedProvider.notifier).setLocked(false);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

