import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final categoriesAsync = ref.watch(
      StreamProvider<List<Category>>(
        (ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // General section
          _SectionHeader(title: 'GENERAL'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                }
              },
            ),
          ),

          // Organisation section
          _SectionHeader(title: 'ORGANISATION'),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Categories'),
            trailing: categoriesAsync.when(
              data: (cats) => Text('${cats.length}'),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            onTap: () => context.go('/settings/categories'),
          ),

          // About section
          _SectionHeader(title: 'ABOUT'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Every-Pay'),
            subtitle: const Text('v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Every-Pay',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '© 2026 Every-Pay\nPrivacy-first expense tracking',
              );
            },
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
