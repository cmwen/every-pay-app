---
title: "Research — Biometric App Lock for EveryPay"
created: 2025-07-16
scope: Flutter Android biometric authentication (fingerprint / face unlock)
status: Complete
app_package: org.cmwen.everypay
flutter_version: "3.38.7 (Dart 3.10.7)"
existing_dependency: "local_auth: ^3.0.0 (installed v3.0.0)"
references:
  - https://pub.dev/packages/local_auth
  - https://pub.dev/packages/flutter_secure_storage
  - https://developer.android.com/training/sign-in/biometric-auth
  - Android BiometricPrompt API documentation
  - docs/ARCHITECTURE_EVERYPAY.md
---

# Research — Biometric App Lock for EveryPay

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Package Comparison](#2-package-comparison)
3. [Current Implementation Audit](#3-current-implementation-audit)
4. [Android-Specific Configuration](#4-android-specific-configuration)
5. [Recommended Architecture](#5-recommended-architecture)
6. [Concrete Implementation Plan](#6-concrete-implementation-plan)
7. [Edge Cases & Error Handling](#7-edge-cases--error-handling)
8. [Security Best Practices](#8-security-best-practices)
9. [Testing Strategy](#9-testing-strategy)
10. [Appendix: Alternative Approaches Considered](#10-appendix-alternative-approaches-considered)

---

## 1. Executive Summary

### Goal
Lock the EveryPay app behind biometric authentication (fingerprint/face) with device-credential fallback (PIN/pattern/password), activating on app background and requiring unlock on resume.

### Key Findings

| Finding | Severity | Status |
|---|---|---|
| **`local_auth: ^3.0.0` is the correct package** — already in `pubspec.yaml` | ✅ Good | Already added |
| **`MainActivity` extends `FlutterActivity` — MUST be `FlutterFragmentActivity`** | 🔴 Critical Bug | Needs fix |
| **Biometric-enabled flag stored in `SharedPreferences` — not tamper-resistant** | 🟡 Medium Risk | Recommend `flutter_secure_storage` |
| **Existing `AppLockWrapper` + provider architecture is sound** | ✅ Good | Minor improvements needed |
| **No grace period after backgrounding — UX issue** | 🟡 UX Polish | Recommend 5s grace period |
| **No tests exist for biometric features** | 🟡 Gap | Needs unit + widget tests |

### Recommendation
The existing implementation is ~80% of the way there. Fix the critical `FlutterFragmentActivity` bug, harden the preference storage, add a grace period, improve edge-case handling, and add tests. **No package changes needed** — `local_auth 3.0.0` is the right choice.

---

## 2. Package Comparison

### 2.1 `local_auth` (v3.0.0) — ✅ RECOMMENDED (Already Installed)

| Attribute | Detail |
|---|---|
| Publisher | `flutter.dev` (first-party, Flutter team) |
| Pub.dev Score | 140 (max) |
| Likes / Popularity | 3,000+ likes; one of the most popular auth packages |
| Platform Support | Android, iOS, macOS, Windows |
| API Level | Android API 23+ for biometric; API 21+ for device credentials |
| Biometric Types | Fingerprint, face, iris (hardware-dependent) |
| Device Credential Fallback | Yes — `biometricOnly: false` falls back to PIN/pattern/password |
| Maintained by | Flutter team (flutter/packages monorepo) |
| Last Updated | Actively maintained |

**Pros:**
- First-party package maintained in the Flutter monorepo
- Clean, simple API: `canCheckBiometrics`, `isDeviceSupported()`, `authenticate()`, `getAvailableBiometrics()`
- Wraps Android `BiometricPrompt` API correctly (Class 3 / strong biometrics)
- Built-in `persistAcrossBackgrounding` for sticky auth across app lifecycle
- Federated plugin architecture (separate platform packages)
- `biometricOnly: false` automatically enables device-credential fallback (PIN/pattern)

**Cons:**
- Does not store secrets — only performs authentication challenge
- No built-in "lock on idle" timer — must be implemented in app code
- Requires `FlutterFragmentActivity` on Android (not `FlutterActivity`)

### 2.2 `flutter_biometric_storage` (v5.x) — ❌ Not Recommended

| Attribute | Detail |
|---|---|
| Purpose | Biometric-protected encrypted key-value storage |
| Use Case | Storing secrets (tokens, keys) behind biometric prompt |
| Maintained | Community; less active than local_auth |

**Why not:** EveryPay doesn't need to store secrets behind biometrics. The use case is a UI lock gate, not encrypted credential storage. `local_auth` is simpler, better maintained, and purpose-built for authentication prompts.

### 2.3 `flutter_secure_storage` (v9.x) — ✅ RECOMMENDED (Complementary)

| Attribute | Detail |
|---|---|
| Purpose | AES-encrypted key-value storage backed by Android KeyStore |
| Use Case | Storing the "biometric enabled" boolean securely |
| Score | 160 pub points |

**Why recommended as complementary:** The "biometric_lock_enabled" preference is currently in `SharedPreferences` (plaintext XML). An attacker with root/ADB access could flip this to `false` and bypass the lock. Moving it to `flutter_secure_storage` (which uses `EncryptedSharedPreferences` on Android, backed by KeyStore) makes it tamper-resistant.

### 2.4 `app_lock` / `flutter_app_lock` — ❌ Not Recommended

These are convenience wrappers around `local_auth` that provide a lock-screen widget. EveryPay already has `AppLockWrapper` with custom UI — using these would add unnecessary dependency and reduce control.

### Decision Matrix

| Criterion | local_auth | flutter_biometric_storage | app_lock |
|---|---|---|---|
| First-party | ✅ | ❌ | ❌ |
| Simple auth prompt | ✅ | ❌ (storage-oriented) | ✅ |
| Device credential fallback | ✅ | ❌ | ✅ |
| Custom lock UI | ✅ (we build it) | N/A | ❌ (forced UI) |
| Already in project | ✅ | ❌ | ❌ |
| **Verdict** | **USE THIS** | Skip | Skip |

---

## 3. Current Implementation Audit

### 3.1 File Map

| File | Role | Status |
|---|---|---|
| `lib/core/services/biometric_service.dart` | Wraps `LocalAuthentication` | ✅ Good, minor improvements |
| `lib/features/settings/providers/security_provider.dart` | `biometricEnabledProvider`, `appLockedProvider` | 🟡 Needs secure storage |
| `lib/features/settings/screens/security_screen.dart` | Toggle UI for biometric lock | ✅ Good |
| `lib/shared/widgets/app_lock_wrapper.dart` | Lifecycle observer + lock overlay | ✅ Good, needs grace period |
| `lib/app.dart` | Uses `AppLockWrapper` in `builder:` | ✅ Correct placement |
| `android/.../MainActivity.kt` | `FlutterActivity` (WRONG) | 🔴 Must be `FlutterFragmentActivity` |
| `android/.../AndroidManifest.xml` | Has `USE_BIOMETRIC` + `USE_FINGERPRINT` | ✅ Good |

### 3.2 Critical Bug: `FlutterActivity` vs `FlutterFragmentActivity`

**File:** `android/app/src/main/kotlin/org/cmwen/everypay/MainActivity.kt`

**Current (BROKEN):**
```kotlin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

**Required (FIXED):**
```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**Why this matters:** The `local_auth_android` plugin (v2.0.4) checks:
```java
// LocalAuthPlugin.java line 112
if (!(activity instanceof FragmentActivity)) {
    result.success(
        new AuthResult.Builder()
            .setCode(AuthResultCode.NOT_FRAGMENT_ACTIVITY)
            .build());
    return;
}
```

With `FlutterActivity`, **every `authenticate()` call silently returns `false`** (or throws). `FlutterFragmentActivity` extends `FragmentActivity` which is required by Android's `BiometricPrompt` API. This is the single most important fix.

### 3.3 Existing Provider Architecture (Good Foundation)

```
security_provider.dart
├── biometricServiceProvider  → Provider<BiometricService>
├── biometricEnabledProvider  → AsyncNotifierProvider<..., bool>
│   └── Reads/writes SharedPreferences (key: "biometric_lock_enabled")
└── appLockedProvider         → NotifierProvider<..., bool>
    └── In-memory boolean (starts false)
```

This is architecturally sound. The separation of "is biometric enabled" (persistent setting) from "is app currently locked" (runtime state) is correct.

### 3.4 Existing BiometricService (Good, Minor Issues)

```dart
// Current: lib/core/services/biometric_service.dart
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Authenticate to unlock EveryPay',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,           // ✅ Correct: allows PIN/pattern fallback
        persistAcrossBackgrounding: true, // ✅ Correct: retries after bg/fg
      );
    } catch (_) {
      return false;
    }
  }
}
```

**Assessment:** Functionally correct. The `biometricOnly: false` allows device credential fallback, and `persistAcrossBackgrounding: true` handles the case where the system dismisses the biometric prompt on backgrounding.

**Improvements needed:**
1. Expose `getAvailableBiometrics()` for UI display
2. Add specific error handling instead of swallowing all exceptions
3. Accept `sensitiveTransaction` parameter (defaults to `true`, shows confirmation after face unlock)

---

## 4. Android-Specific Configuration

### 4.1 Permissions (✅ Already Configured)

```xml
<!-- AndroidManifest.xml — already present -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

- `USE_BIOMETRIC`: Required for API 28+ (Android 9+). Used by `BiometricPrompt`.
- `USE_FINGERPRINT`: Deprecated but needed for backward compatibility with API 23-27.

**Note:** These are **normal permissions** (not dangerous), so no runtime permission request is needed. They are granted at install time.

### 4.2 Minimum API Level

| API Level | Biometric Support |
|---|---|
| **API 23 (Android 6.0)** | `FingerprintManager` (deprecated) — fingerprint only |
| **API 28 (Android 9.0)** | `BiometricPrompt` — fingerprint, face, iris |
| **API 29 (Android 10)** | `BiometricManager` — check enrollment status |
| **API 30 (Android 11)** | `BIOMETRIC_STRONG` / `BIOMETRIC_WEAK` classification |

**EveryPay's current `minSdkVersion`:** `24` (Flutter 3.38.7 default, set via `flutter.minSdkVersion`).

This is fine. `local_auth` handles API-level differences internally:
- On API 23-27: Uses `FingerprintManagerCompat` via AndroidX
- On API 28+: Uses `BiometricPrompt` via AndroidX Biometric library

### 4.3 MainActivity Change (🔴 REQUIRED)

```kotlin
// android/app/src/main/kotlin/org/cmwen/everypay/MainActivity.kt
package org.cmwen.everypay

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**`FlutterFragmentActivity`** is a drop-in replacement for `FlutterActivity`. It extends `FragmentActivity` (required by `BiometricPrompt`) and has no behavioral differences for normal Flutter apps. All existing Flutter plugins work identically with either.

### 4.4 Gradle Configuration (✅ No Changes Needed)

The project already uses:
- `compileSdk = flutter.compileSdkVersion` (36)
- `minSdk = flutter.minSdkVersion` (24)
- `targetSdk = flutter.targetSdkVersion` (36)

`local_auth_android 2.0.4` requires `minSdk >= 16` (met), and `compileSdk >= 34` (met).

### 4.5 ProGuard Rules (✅ No Changes Needed)

`local_auth_android` includes its own ProGuard consumer rules. No additional ProGuard configuration is needed in the app.

---

## 5. Recommended Architecture

### 5.1 Overall Design

```
┌─────────────────────────────────────────────────────────────┐
│                    MaterialApp.router                        │
│  builder: AppLockWrapper (wraps entire app)                  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ AppLockWrapper (ConsumerStatefulWidget)                  │ │
│  │  ├── WidgetsBindingObserver (lifecycle)                  │ │
│  │  ├── Watches: appLockStateProvider                       │ │
│  │  ├── On paused/hidden → lock (with grace period)        │ │
│  │  ├── On resumed → authenticate if locked                │ │
│  │  └── Renders: LockScreen overlay OR child               │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ GoRouter (all app routes — no redirect needed)          │ │
│  │  └── Routes are protected by wrapper, not by redirect   │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Why `builder:` Overlay, Not `go_router` Redirect

The current approach of using `MaterialApp.router(builder:)` to wrap the entire app is **correct and superior** to a go_router redirect for this use case. Here's why:

| Approach | Wrapper Overlay (current) | go_router Redirect |
|---|---|---|
| **Covers all routes** | ✅ Automatically | ❌ Must guard every route |
| **Preserves navigation state** | ✅ Routes stay in stack | ❌ Redirect destroys stack |
| **Deep link protection** | ✅ Lock screen over any content | 🟡 Redirect loses deep link |
| **Back button bypass** | ✅ Cannot escape overlay | 🟡 User could navigate back |
| **Animation** | ✅ Smooth fade in/out | ❌ Full page transition |
| **StatefulShellRoute compat** | ✅ Works naturally | 🟡 Complex with shell routes |

**Verdict:** Keep the `AppLockWrapper` in `builder:`. Do NOT use go_router redirect for biometric lock. The redirect pattern is designed for login/logout flows where the user's authentication state changes routes — biometric lock is a UI overlay that should preserve underlying state.

### 5.3 Riverpod Provider Design

#### Recommended provider structure (improvement over current):

```dart
// ── lib/features/settings/providers/security_provider.dart ──

/// Service that wraps local_auth. Stateless, so Provider is correct.
final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);

/// Persistent setting: "has the user enabled biometric lock?"
/// Uses flutter_secure_storage for tamper resistance.
final biometricEnabledProvider =
    AsyncNotifierProvider<BiometricEnabledNotifier, bool>(
  BiometricEnabledNotifier.new,
);

/// Runtime lock state + grace period logic.
/// Encapsulates: is the app locked? when was it last backgrounded?
final appLockStateProvider =
    NotifierProvider<AppLockStateNotifier, AppLockState>(
  AppLockStateNotifier.new,
);
```

#### Lock state model (recommended improvement):

```dart
/// Immutable state for the app lock.
class AppLockState {
  final bool isLocked;
  final DateTime? lastBackgrounded;

  const AppLockState({
    this.isLocked = false,
    this.lastBackgrounded,
  });

  AppLockState copyWith({bool? isLocked, DateTime? lastBackgrounded}) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      lastBackgrounded: lastBackgrounded ?? this.lastBackgrounded,
    );
  }
}
```

This enables a grace period: if the user switches away for < N seconds, don't re-lock.

### 5.4 Grace Period Logic

```dart
class AppLockStateNotifier extends Notifier<AppLockState> {
  /// Grace period before locking (e.g., 5 seconds).
  static const _gracePeriod = Duration(seconds: 5);

  @override
  AppLockState build() => const AppLockState();

  /// Called when app is paused/hidden.
  void onBackground() {
    state = state.copyWith(lastBackgrounded: DateTime.now());
  }

  /// Called when app is resumed. Returns true if lock should be applied.
  bool shouldLock() {
    final lastBg = state.lastBackgrounded;
    if (lastBg == null) return false;
    return DateTime.now().difference(lastBg) > _gracePeriod;
  }

  void lock() => state = state.copyWith(isLocked: true);

  void unlock() => state = state.copyWith(
        isLocked: false,
        lastBackgrounded: null,
      );
}
```

---

## 6. Concrete Implementation Plan

### 6.1 Step-by-Step Changes

#### Step 1: Fix MainActivity (🔴 Critical)

```kotlin
// android/app/src/main/kotlin/org/cmwen/everypay/MainActivity.kt
package org.cmwen.everypay

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

#### Step 2: Add `flutter_secure_storage` to `pubspec.yaml`

```yaml
dependencies:
  flutter_secure_storage: ^9.2.4
```

#### Step 3: Improve `BiometricService`

```dart
// lib/core/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  final LocalAuthentication _auth;

  /// Accept [LocalAuthentication] for testability.
  BiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  /// Returns true if the device has biometric hardware AND enrolled biometrics,
  /// OR supports device credentials (PIN/pattern/password).
  Future<bool> canAuthenticate() async {
    try {
      final canBiometric = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canBiometric || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Triggers the system authentication prompt.
  ///
  /// With [biometricOnly] false (default), the system will fall back to
  /// device credentials (PIN/pattern/password) if biometrics fail or are
  /// not enrolled.
  ///
  /// [persistAcrossBackgrounding] true means if the auth dialog is dismissed
  /// by backgrounding, the plugin will automatically retry on foregrounding.
  Future<bool> authenticate({
    String reason = 'Authenticate to unlock EveryPay',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
        authMessages: const [
          AndroidAuthMessages(
            biometricHint: '',
            signInTitle: 'EveryPay Authentication',
            cancelButton: 'Cancel',
          ),
        ],
      );
    } on Exception catch (_) {
      // PlatformException covers: NotAvailable, NotEnrolled,
      // OtherOperatingSystem, PasscodeNotSet, etc.
      return false;
    }
  }

  /// Cancel an in-progress authentication (e.g., if user navigates away).
  Future<void> cancelAuthentication() async {
    await _auth.stopAuthentication();
  }
}
```

#### Step 4: Improve Security Provider with Secure Storage

```dart
// lib/features/settings/providers/security_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:everypay/core/services/biometric_service.dart';

const _kBiometricEnabled = 'biometric_lock_enabled';

final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);

/// Secure storage instance (uses EncryptedSharedPreferences on Android).
final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final biometricEnabledProvider =
    AsyncNotifierProvider<BiometricEnabledNotifier, bool>(
  BiometricEnabledNotifier.new,
);

class BiometricEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = ref.read(_secureStorageProvider);
    final value = await storage.read(key: _kBiometricEnabled);
    return value == 'true';
  }

  Future<void> setEnabled(bool value) async {
    state = const AsyncLoading();
    final storage = ref.read(_secureStorageProvider);
    await storage.write(key: _kBiometricEnabled, value: value.toString());
    state = AsyncData(value);
  }
}

/// Tracks app lock state with grace period support.
final appLockStateProvider =
    NotifierProvider<AppLockStateNotifier, AppLockState>(
  AppLockStateNotifier.new,
);

class AppLockState {
  final bool isLocked;
  final DateTime? lastBackgrounded;

  const AppLockState({this.isLocked = false, this.lastBackgrounded});

  AppLockState copyWith({bool? isLocked, DateTime? lastBackgrounded}) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      lastBackgrounded: lastBackgrounded ?? this.lastBackgrounded,
    );
  }
}

class AppLockStateNotifier extends Notifier<AppLockState> {
  static const gracePeriod = Duration(seconds: 5);

  @override
  AppLockState build() => const AppLockState();

  void recordBackground() {
    state = state.copyWith(lastBackgrounded: DateTime.now());
  }

  bool shouldLockOnResume() {
    final lastBg = state.lastBackgrounded;
    if (lastBg == null) return true; // First launch
    return DateTime.now().difference(lastBg) > gracePeriod;
  }

  void lock() => state = state.copyWith(isLocked: true);

  void unlock() => state = const AppLockState(isLocked: false);
}

// ── Backward-compatible alias for existing code ──
// (Remove after migrating all call sites)
final appLockedProvider = Provider<bool>((ref) {
  return ref.watch(appLockStateProvider).isLocked;
});
```

#### Step 5: Improve `AppLockWrapper` with Grace Period

```dart
// lib/shared/widgets/app_lock_wrapper.dart
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // On first launch, lock if biometric is enabled.
    WidgetsBinding.instance.addPostFrameCallback((_) => _lockIfEnabled());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onBackground();
      case AppLifecycleState.resumed:
        _onResume();
      default:
        break;
    }
  }

  bool get _isBiometricEnabled {
    final biometric = ref.read(biometricEnabledProvider);
    return switch (biometric) {
      AsyncData(:final value) => value,
      _ => false,
    };
  }

  void _onBackground() {
    if (_isBiometricEnabled) {
      ref.read(appLockStateProvider.notifier).recordBackground();
    }
  }

  void _onResume() {
    if (!_isBiometricEnabled) return;
    final notifier = ref.read(appLockStateProvider.notifier);
    if (notifier.shouldLockOnResume()) {
      notifier.lock();
      _authenticateIfLocked();
    }
  }

  Future<void> _lockIfEnabled() async {
    if (_isBiometricEnabled) {
      ref.read(appLockStateProvider.notifier).lock();
      await _authenticateIfLocked();
    }
  }

  Future<void> _authenticateIfLocked() async {
    if (!mounted) return;
    final lockState = ref.read(appLockStateProvider);
    if (!lockState.isLocked || _authenticating) return;

    _authenticating = true;
    final service = ref.read(biometricServiceProvider);
    final success = await service.authenticate();
    _authenticating = false;

    if (success && mounted) {
      ref.read(appLockStateProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockStateProvider);
    if (lockState.isLocked) {
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
            Icon(Icons.lock_outline, size: 72, color: theme.colorScheme.primary),
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
```

### 6.2 `app.dart` — No Changes Needed

```dart
// lib/app.dart — already correct
builder: (context, child) => AppLockWrapper(child: child!),
```

This placement is ideal: the lock screen sits above the router, covering all routes.

### 6.3 Integration with go_router

**No changes to `router.dart` are needed.** The lock wrapper approach doesn't interact with routing at all. This is intentional:

- Lock state is **orthogonal** to navigation state
- The wrapper renders over the entire `GoRouter` tree
- All routes remain in the navigation stack while locked
- No risk of losing deep links or tab state

If in the future you want certain routes (e.g., a "locked" route) to appear in the URL bar, you could add a redirect like this — but it's **not recommended**:

```dart
// ❌ NOT RECOMMENDED for biometric lock — shown for reference only
final router = GoRouter(
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final locked = container.read(appLockStateProvider).isLocked;
    if (locked && state.uri.path != '/locked') return '/locked';
    if (!locked && state.uri.path == '/locked') return '/';
    return null;
  },
  refreshListenable: /* would need a ChangeNotifier wrapper */,
  routes: [...],
);
```

---

## 7. Edge Cases & Error Handling

### 7.1 Device Does Not Support Biometrics

```dart
// In SecurityScreen._onToggle:
final canAuth = await service.canAuthenticate();
if (!canAuth) {
  // Show snackbar: "No biometric hardware available"
  return; // Don't enable the toggle
}
```

`canAuthenticate()` checks both `canCheckBiometrics` (hardware present + enrolled) and `isDeviceSupported()` (device credentials available). If both are false, the device has neither biometrics nor a screen lock — rare but possible on dev devices.

### 7.2 No Biometrics Enrolled (But Device Has Hardware)

When `biometricOnly: false`:
- `authenticate()` will fall back to device credentials (PIN/pattern/password)
- This is the correct behavior — the user can still unlock

When `biometricOnly: true`:
- `authenticate()` will throw `NotEnrolled` exception
- The app should catch this and show a helpful message

**Recommendation:** Keep `biometricOnly: false` (current behavior is correct).

### 7.3 User Cancels Authentication

When the user taps "Cancel" on the biometric prompt:
- `authenticate()` returns `false` (not an exception)
- The lock screen remains displayed
- The user can tap "Unlock" to retry
- This is already handled correctly in the current implementation

### 7.4 Multiple Rapid Background/Foreground Cycles

The `_authenticating` flag prevents concurrent auth dialogs. The `persistAcrossBackgrounding: true` flag tells the plugin to retry automatically after backgrounding.

**Remaining concern:** If the user rapidly switches apps, the grace period prevents unnecessary re-authentication.

### 7.5 First Launch After Enabling Biometric

**Current behavior:** `AppLockWrapper.initState` → `_lockIfEnabled()` → locks and prompts.

**Correct:** After the user toggles biometric on in SecurityScreen, the `appLockedProvider` is explicitly set to unlocked (`setLocked(false)`), so the lock doesn't activate until the next app background/resume cycle.

### 7.6 App Killed While Locked

When the app is killed (swiped from recents) and reopened:
- `AppLockWrapper.initState` runs → checks `biometricEnabledProvider` → locks if enabled
- The runtime `appLockStateProvider` starts as `isLocked: false`, but `_lockIfEnabled()` in `initState` sets it to true
- Authentication prompt appears on cold start ✅

### 7.7 Authentication Timeout

Android's `BiometricPrompt` has built-in timeout handling:
- After 5 failed fingerprint attempts: 30-second cooldown
- After additional failures: longer cooldowns
- This is handled by the OS — no app-side logic needed

The "Cancel" button always remains accessible, and with `biometricOnly: false`, the user can tap "Use PIN" to fall back to device credentials.

### 7.8 Screen Lock Not Set

If the device has no screen lock at all (no PIN/pattern/password/biometric):
- `isDeviceSupported()` returns `false`
- `canCheckBiometrics` returns `false`
- `canAuthenticate()` returns `false`
- The toggle in SecurityScreen is disabled with "Unavailable on this device"

---

## 8. Security Best Practices

### 8.1 Threat Model for App Lock

| Threat | Mitigation |
|---|---|
| **Shoulder surfing** | Biometric prompt (no visible PIN entry) |
| **Lost/stolen device (locked)** | OS-level encryption + biometric gate |
| **Lost/stolen device (unlocked)** | App-level lock activates on background |
| **Root/ADB access** | `flutter_secure_storage` makes preference tamper-resistant |
| **Biometric spoof** | Android Class 3 biometrics (`BiometricPrompt`) have spoof resistance |
| **Memory dump** | Lock state is a simple boolean; no secrets in memory |
| **Bypass via app data clear** | Acceptable: clearing app data also clears all user data |

### 8.2 What `local_auth` Does and Does NOT Do

**DOES:**
- Verifies the user is the device owner via OS biometric/credential challenge
- Uses Android `BiometricPrompt` (hardware-backed, Class 3 strong biometrics)
- Handles all biometric UI (system dialog)

**DOES NOT:**
- Store any secrets or tokens
- Provide encryption
- Protect against a rooted device reading app memory
- Guarantee the biometric data's quality (that's the OS's job)

### 8.3 Storing the "Enabled" Flag Securely

**Current (SharedPreferences):**
```
/data/data/org.cmwen.everypay/shared_prefs/FlutterSharedPreferences.xml
<boolean name="flutter.biometric_lock_enabled" value="true" />
```

An attacker with root access can edit this XML to `false` and bypass the lock.

**Recommended (flutter_secure_storage):**
```
/data/data/org.cmwen.everypay/shared_prefs/FlutterSecureStorage.xml
<string name="biometric_lock_enabled" value="AES-encrypted-blob" />
```

Uses `EncryptedSharedPreferences` with a key stored in Android KeyStore. Not easily tamperable even with root access.

### 8.4 Don't Store Biometric Data

This is handled automatically by `local_auth` — the plugin never touches raw biometric data. All biometric matching happens in the Trusted Execution Environment (TEE) on the device. The app only receives a boolean result.

### 8.5 Prevent Screenshot While Locked

Consider adding `FLAG_SECURE` to prevent screenshots of the lock screen (and the app content behind it):

```kotlin
// In MainActivity.kt (optional, for high-security apps)
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots and screen recording in task switcher
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
```

**Trade-off:** This prevents ALL screenshots, not just on the lock screen. For a payment app, this may be acceptable. It can also be toggled dynamically via a method channel if needed.

### 8.6 Obfuscation in Task Switcher

When the app is backgrounded, Android shows a snapshot in the recent apps list. The `AppLockWrapper` already handles this by design: when `paused` or `hidden` is received, the lock state is set before the snapshot is taken. However, there's a race condition — the snapshot may be taken before the lock screen renders.

**Additional protection:** Use `FLAG_SECURE` (above) or add a platform channel to set `FLAG_SECURE` dynamically only while the app is in the background.

---

## 9. Testing Strategy

### 9.1 Unit Tests

```dart
// test/core/services/biometric_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';
import 'package:everypay/core/services/biometric_service.dart';

class MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late MockLocalAuth mockAuth;
  late BiometricService service;

  setUp(() {
    mockAuth = MockLocalAuth();
    service = BiometricService(mockAuth);
  });

  group('canAuthenticate', () {
    test('returns true when biometrics available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);
      expect(await service.canAuthenticate(), isTrue);
    });

    test('returns true when device credentials available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      expect(await service.canAuthenticate(), isTrue);
    });

    test('returns false when nothing available', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);
      expect(await service.canAuthenticate(), isFalse);
    });

    test('returns false on exception', () async {
      when(() => mockAuth.canCheckBiometrics).thenThrow(Exception());
      expect(await service.canAuthenticate(), isFalse);
    });
  });

  group('authenticate', () {
    test('returns true on successful auth', () async {
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding:
                any(named: 'persistAcrossBackgrounding'),
            authMessages: any(named: 'authMessages'),
          )).thenAnswer((_) async => true);
      expect(await service.authenticate(), isTrue);
    });

    test('returns false on user cancel', () async {
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding:
                any(named: 'persistAcrossBackgrounding'),
            authMessages: any(named: 'authMessages'),
          )).thenAnswer((_) async => false);
      expect(await service.authenticate(), isFalse);
    });

    test('returns false on PlatformException', () async {
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            sensitiveTransaction: any(named: 'sensitiveTransaction'),
            persistAcrossBackgrounding:
                any(named: 'persistAcrossBackgrounding'),
            authMessages: any(named: 'authMessages'),
          )).thenThrow(Exception('NotAvailable'));
      expect(await service.authenticate(), isFalse);
    });
  });
}
```

### 9.2 Provider Tests

```dart
// test/features/settings/providers/security_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/features/settings/providers/security_provider.dart';

void main() {
  group('AppLockStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state is unlocked', () {
      final state = container.read(appLockStateProvider);
      expect(state.isLocked, isFalse);
      expect(state.lastBackgrounded, isNull);
    });

    test('lock() sets isLocked to true', () {
      container.read(appLockStateProvider.notifier).lock();
      expect(container.read(appLockStateProvider).isLocked, isTrue);
    });

    test('unlock() resets state', () {
      container.read(appLockStateProvider.notifier).lock();
      container.read(appLockStateProvider.notifier).unlock();
      final state = container.read(appLockStateProvider);
      expect(state.isLocked, isFalse);
      expect(state.lastBackgrounded, isNull);
    });

    test('shouldLockOnResume returns false within grace period', () {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.recordBackground();
      // Immediately check — should be within grace period
      expect(notifier.shouldLockOnResume(), isFalse);
    });

    test('shouldLockOnResume returns true after grace period', () async {
      final notifier = container.read(appLockStateProvider.notifier);
      // Simulate backgrounding 10 seconds ago
      container.read(appLockStateProvider.notifier).recordBackground();
      // We can't easily test time-based logic without a clock abstraction,
      // but the logic is: DateTime.now().difference(lastBg) > gracePeriod
      // For real testing, inject a Clock object.
    });
  });
}
```

### 9.3 Widget Tests

```dart
// test/shared/widgets/app_lock_wrapper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/shared/widgets/app_lock_wrapper.dart';
import 'package:everypay/features/settings/providers/security_provider.dart';

void main() {
  testWidgets('shows child when not locked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricEnabledProvider.overrideWith(() =>
              _FakeBiometricEnabledNotifier(false)),
          appLockStateProvider.overrideWith(
              () => _FakeAppLockNotifier(false)),
        ],
        child: const MaterialApp(
          home: AppLockWrapper(child: Text('App Content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('App Content'), findsOneWidget);
    expect(find.text('EveryPay is locked'), findsNothing);
  });

  testWidgets('shows lock screen when locked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricEnabledProvider.overrideWith(() =>
              _FakeBiometricEnabledNotifier(true)),
          appLockStateProvider.overrideWith(
              () => _FakeAppLockNotifier(true)),
        ],
        child: const MaterialApp(
          home: AppLockWrapper(child: Text('App Content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EveryPay is locked'), findsOneWidget);
    expect(find.text('App Content'), findsNothing);
  });
}
```

---

## 10. Appendix: Alternative Approaches Considered

### 10.1 go_router Redirect (Rejected)

A redirect-based approach would add a `/locked` route and redirect all navigation there when locked:

```dart
redirect: (context, state) {
  if (isLocked && state.uri.path != '/locked') return '/locked';
  return null;
},
```

**Rejected because:**
- Destroys the navigation stack (user loses their place)
- Complex interaction with `StatefulShellRoute.indexedStack`
- The redirect fires on every navigation event, adding overhead
- Redirect requires a `refreshListenable` to react to lock state changes
- Lock screen is a security overlay, not a navigation destination

### 10.2 Separate Lock Route With Shell Route (Rejected)

Adding a lock route as a sibling to the `StatefulShellRoute`:

```dart
routes: [
  GoRoute(path: '/locked', builder: ...),
  StatefulShellRoute.indexedStack(...),
],
```

**Rejected because:**
- Same navigation stack issues as redirect
- Doesn't protect against deep links landing directly on content routes
- More complex to maintain

### 10.3 Custom Navigator Observer (Rejected)

Using a `NavigatorObserver` to intercept navigation:

**Rejected because:**
- `NavigatorObserver` can't block navigation
- Would need complex workarounds to prevent rendering protected content
- Less reliable than the wrapper approach

### 10.4 `flutter_biometric_storage` for Settings (Rejected)

Using `flutter_biometric_storage` to store the "enabled" flag behind biometric:

**Rejected because:**
- Circular dependency: need to authenticate to read whether authentication is enabled
- `flutter_secure_storage` provides sufficient tamper resistance without requiring biometric prompt

---

## Summary of Required Changes

### Priority 1 — Critical (Must Fix Before Biometric Works)

| # | File | Change |
|---|---|---|
| 1 | `android/.../MainActivity.kt` | `FlutterActivity` → `FlutterFragmentActivity` |

### Priority 2 — Security Hardening

| # | File | Change |
|---|---|---|
| 2 | `pubspec.yaml` | Add `flutter_secure_storage: ^9.2.4` |
| 3 | `security_provider.dart` | Migrate `SharedPreferences` → `FlutterSecureStorage` |

### Priority 3 — UX & Robustness

| # | File | Change |
|---|---|---|
| 4 | `security_provider.dart` | Add `AppLockState` model with grace period |
| 5 | `app_lock_wrapper.dart` | Implement grace period logic |
| 6 | `biometric_service.dart` | Add constructor injection, `getAvailableBiometrics()`, custom `AuthMessages` |

### Priority 4 — Quality

| # | File | Change |
|---|---|---|
| 7 | `test/` | Add unit tests for `BiometricService` |
| 8 | `test/` | Add provider tests for lock state |
| 9 | `test/` | Add widget tests for `AppLockWrapper` |

### No Changes Needed

| File | Reason |
|---|---|
| `AndroidManifest.xml` | Permissions already present |
| `build.gradle.kts` | SDK versions are correct |
| `router.dart` | Wrapper approach doesn't need route changes |
| `app.dart` | `builder:` placement is already correct |
