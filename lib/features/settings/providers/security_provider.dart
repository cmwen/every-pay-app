import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:everypay/core/services/biometric_service.dart';

const _kBiometricEnabled = 'biometric_lock_enabled';

final biometricServiceProvider = Provider<BiometricService>((_) => BiometricService());

final biometricEnabledProvider =
    AsyncNotifierProvider<BiometricEnabledNotifier, bool>(
      BiometricEnabledNotifier.new,
    );

class BiometricEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
    state = AsyncData(value);
  }
}

/// Tracks whether the app is currently locked (requires biometric to unlock).
final appLockedProvider = NotifierProvider<AppLockedNotifier, bool>(
  AppLockedNotifier.new,
);

class AppLockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setLocked(bool value) => state = value;
}
