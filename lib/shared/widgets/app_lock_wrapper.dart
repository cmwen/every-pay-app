import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/features/settings/providers/security_provider.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  /// Grace period: don't re-lock if app was backgrounded for less than this.
  static const _gracePeriod = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock and immediately attempt auth on first launch if biometric is enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _lockIfEnabled();
      _authenticateIfLocked();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  Future<void> _onResumed() async {
    final bg = _backgroundedAt;
    _backgroundedAt = null;
    if (bg != null && DateTime.now().difference(bg) < _gracePeriod) {
      // Quick app switch — skip re-lock
      return;
    }
    await _lockIfEnabled();
    _authenticateIfLocked();
  }

  Future<void> _lockIfEnabled() async {
    try {
      // Await SharedPreferences load — provider may still be AsyncLoading
      final enabled = await ref.read(biometricEnabledProvider.future);
      if (enabled && mounted) {
        ref.read(appLockedProvider.notifier).setLocked(true);
      }
    } catch (_) {
      // Provider failed to load — leave unlocked
    }
  }

  Future<void> _authenticateIfLocked() async {
    if (!mounted) return;
    final locked = ref.read(appLockedProvider);
    if (!locked || _authenticating) return;
    _authenticating = true;
    final service = ref.read(biometricServiceProvider);
    final success = await service.authenticate();
    _authenticating = false;
    if (success && mounted) {
      ref.read(appLockedProvider.notifier).setLocked(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    if (locked) {
      return _LockScreen(onUnlock: _authenticateIfLocked);
    }
    return widget.child;
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text('EveryPay is locked', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Authenticate to continue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
