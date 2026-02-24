import 'package:flutter/material.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          _SectionHeader(title: 'APP LOCK'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Require fingerprint or face to open app'),
            value: false,
            onChanged: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Biometric lock requires device hardware. '
                    'Full implementation coming soon.',
                  ),
                ),
              );
            },
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
