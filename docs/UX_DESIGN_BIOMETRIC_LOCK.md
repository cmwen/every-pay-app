---
title: "UX Design — Biometric App Lock"
version: 1.0.0
created: 2025-07-16
owner: UX Designer
status: Final
platform: Flutter Android (Material Design 3)
references:
  - docs/RESEARCH_BIOMETRIC_LOCK.md
  - docs/UX_DESIGN_EVERYPAY.md
  - docs/PERSONAS_EVERYPAY.md
  - lib/shared/widgets/app_lock_wrapper.dart
  - lib/features/settings/screens/security_screen.dart
  - lib/core/services/biometric_service.dart
---

# UX Design — Biometric App Lock

## 1. Design Goals

| Goal | Rationale |
|------|-----------|
| **Unlock in ≤1 second** | Lock screen must never feel like a wall — fast biometric prompt, auto-trigger on resume |
| **Zero confusion for Barbara & Tom** | Low-tech users must understand what the lock icon means and how to proceed |
| **Graceful degradation** | No hardware → device PIN. No enrollment → guide to settings. Failure → retry. |
| **Never lock out the user** | Device credential fallback (`biometricOnly: false`) ensures PIN/pattern always works |

---

## 2. Lock Screen Design

### 2.1 Layout (Top → Bottom)

```
┌──────────────────────────────────┐
│           SafeArea               │
│                                  │
│        ● EveryPay Logo           │  ← App icon (48×48), centered
│          (app icon)              │
│                                  │
│     ╔══════════════════════╗     │
│     ║   🔒  (72dp icon)   ║     │  ← Icon: lock_outline (unlocked state)
│     ║                      ║     │     or fingerprint (authenticating)
│     ║   "EveryPay is       ║     │  ← titleLarge
│     ║    locked"           ║     │
│     ║                      ║     │
│     ║   "Tap to unlock     ║     │  ← bodyMedium, onSurfaceVariant
│     ║    with biometrics"  ║     │
│     ╚══════════════════════╝     │
│                                  │
│     ┌──────────────────────┐     │
│     │  ◉ Unlock            │     │  ← FilledButton.icon (Icons.fingerprint)
│     └──────────────────────┘     │     Min width: 200dp, height: 48dp
│                                  │
│     [ Status message area ]      │  ← bodySmall, animated fade in/out
│                                  │
│                                  │
└──────────────────────────────────┘
```

### 2.2 Widget Tree

```dart
Scaffold(
  backgroundColor: theme.colorScheme.surface,  // NOT background — M3 surface
  body: SafeArea(
    child: Center(
      child: SingleChildScrollView(  // handles small screens / large text scaling
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. App icon (branding anchor)
            Image.asset('assets/icon/app_icon.png', width: 48, height: 48),
            SizedBox(height: 48),

            // 2. Lock icon — animated swap between states
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Icon(
                _stateIcon,     // lock_outline | fingerprint | error_outline
                key: ValueKey(_state),
                size: 72,
                color: _stateColor,  // primary | error
                semanticLabel: 'App is locked',
              ),
            ),
            SizedBox(height: 24),

            // 3. Title
            Text('EveryPay is locked', style: theme.textTheme.titleLarge),
            SizedBox(height: 8),

            // 4. Subtitle — changes per state
            Text(
              _subtitleForState,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // 5. Unlock button
            FilledButton.icon(
              onPressed: _canRetry ? _authenticate : null,
              icon: Icon(Icons.fingerprint),
              label: Text(_buttonLabel),
              style: FilledButton.styleFrom(
                minimumSize: Size(200, 48),  // 48dp touch target
              ),
            ),
            SizedBox(height: 16),

            // 6. Status message (animated)
            AnimatedOpacity(
              opacity: _statusMessage != null ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Text(
                _statusMessage ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
)
```

### 2.3 Lock Screen States

| State | Icon | Subtitle | Button | Status |
|-------|------|----------|--------|--------|
| **Idle** | `lock_outline` (primary) | "Tap to unlock with biometrics" | "Unlock" (enabled) | — |
| **Authenticating** | `fingerprint` (primary) | "Verifying…" | "Unlock" (disabled) | — |
| **Success** | `lock_open` (primary) | "Welcome back" | — | Fade out, reveal app |
| **Failed** | `error_outline` (error) | "Authentication failed" | "Try Again" (enabled) | "Tap the button to retry" |
| **Failed 3×** | `error_outline` (error) | "Too many attempts" | "Try Again" (disabled 30s) | "Try again in 30 seconds" with countdown |
| **Cancelled** | `lock_outline` (primary) | "Unlock when you're ready" | "Unlock" (enabled) | — |
| **No biometrics enrolled** | `fingerprint_outlined` (onSurfaceVariant) | "No biometrics set up on this device" | "Open Device Settings" | "You can also use your device PIN" |

### 2.4 Behavior

1. **Auto-trigger on resume**: When `AppLifecycleState.resumed` fires and app is locked, automatically call `authenticate()` after a 300ms delay (lets the UI render first).
2. **Manual retry**: If auto-trigger fails or user cancels, the button is always available.
3. **Transition out**: On success, use `AnimatedSwitcher` to crossfade from lock screen to app content (200ms). Do NOT use a route push — the lock screen is an overlay.
4. **Obscure content**: While locked, the child widget stays mounted but is hidden behind the lock screen (`Stack` with lock on top). This preserves navigation state.

### 2.5 Accessibility

| Requirement | Implementation |
|-------------|----------------|
| Screen reader | `Semantics(label: 'EveryPay is locked. Activate the Unlock button to authenticate.')` wrapping the entire lock body |
| Button semantics | `FilledButton.icon` already exposes label. Add `tooltip: 'Authenticate with fingerprint or device PIN'` |
| Focus order | Icon → Title → Subtitle → Button → Status. Use `FocusTraversalOrder` if needed |
| Text scaling | `SingleChildScrollView` ensures content remains visible at 200% text scale |
| Color contrast | Primary on surface passes WCAG AA. Error on surface passes WCAG AA. Verify with `colorScheme.fromSeed` output. |
| Reduced motion | Check `MediaQuery.disableAnimations` — skip `AnimatedSwitcher` crossfade if true |

---

## 3. Edge Cases UX

### 3.1 No Biometric Hardware

**Detection**: `LocalAuthentication.canCheckBiometrics == false && isDeviceSupported() == true`
(Device supports credentials but has no biometric sensor.)

**UX Response**:
- Lock screen shows device PIN icon (`Icons.pin`) instead of fingerprint
- Subtitle: "Unlock with your device PIN or pattern"
- Button label: "Unlock" (calls `authenticate(biometricOnly: false)`)
- Settings toggle subtitle changes to: "Require device PIN or pattern to open app"

**In Settings** (when enabling):
- Show an `InfoBar` (Material 3 Banner) at top of list:
  ```
  ╔═══════════════════════════════════════════╗
  ║ ℹ️  No fingerprint sensor detected.       ║
  ║     Your device PIN will be used instead. ║
  ║                                [DISMISS]  ║
  ╚═══════════════════════════════════════════╝
  ```
- Widget: `MaterialBanner` with `leading: Icon(Icons.info_outline)`, single `TextButton('Dismiss')` action.

### 3.2 Biometrics Not Enrolled

**Detection**: `canCheckBiometrics == true` but `getAvailableBiometrics()` returns empty list.

**UX Response on Lock Screen**:
```
┌─────────────────────────────────┐
│                                 │
│        🔒 (lock icon)          │
│                                 │
│   "Biometrics not set up"       │  ← titleLarge
│                                 │
│   "Add a fingerprint or face    │  ← bodyMedium, onSurfaceVariant
│    in your device settings to   │
│    unlock with biometrics."     │
│                                 │
│   ┌───────────────────────┐     │
│   │  Open Device Settings │     │  ← OutlinedButton — opens Android Security settings
│   └───────────────────────┘     │
│                                 │
│   ┌───────────────────────┐     │
│   │  ◉ Unlock with PIN    │     │  ← FilledButton — device credential fallback
│   └───────────────────────┘     │
│                                 │
└─────────────────────────────────┘
```

- **"Open Device Settings"**: Uses `OutlinedButton` (secondary action). Launches `android.settings.SECURITY_SETTINGS` intent via `url_launcher` or platform channel.
- **"Unlock with PIN"**: Uses `FilledButton` (primary action). Calls `authenticate(biometricOnly: false)`.

**In Settings** (when user tries to enable):
- Show `AlertDialog`:
  - Title: "Set up biometrics first"
  - Content: "Add a fingerprint or face unlock in your device settings, then come back to enable this."
  - Actions: `TextButton('Cancel')`, `FilledButton('Open Settings')`
- Toggle stays off until biometrics are enrolled.

### 3.3 Authentication Failure

**Retry strategy with escalating cooldown**:

| Attempt | Behavior |
|---------|----------|
| 1st failure | Show "Authentication failed" for 2s → return to Idle state |
| 2nd failure | Show "Authentication failed. Try again." → return to Idle state |
| 3rd failure | Disable button for 30s with countdown: "Try again in 28s…" |
| After cooldown | Reset attempt counter, return to Idle |

**Implementation notes**:
- Track `_failCount` in `_LockScreenState` (not in provider — resets on app restart, which is fine since the OS handles actual lockout).
- Use `Timer.periodic` for countdown display. Cancel in `dispose()`.
- The OS `BiometricPrompt` has its own lockout after 5 failed fingerprint attempts (30s coolout, then permanent lockout requiring device PIN). Our app-level cooldown is a softer UX layer on top of that.

**Widget for cooldown state**:
```dart
// Disabled button with countdown
FilledButton.icon(
  onPressed: null,  // disabled
  icon: Icon(Icons.timer),
  label: Text('Try again in ${_countdown}s'),
)
```

### 3.4 User Cancels Prompt

**Detection**: `authenticate()` returns `false` without throwing (user pressed "Cancel" or "Use password" on the system dialog).

**UX Response**:
- Do NOT show an error — this is intentional.
- Transition to **Cancelled** state: subtitle changes to "Unlock when you're ready"
- Keep button enabled with "Unlock" label.
- Do NOT auto-re-trigger the biometric prompt (annoying if user is choosing to wait).

### 3.5 Lock Screen Shown During First Launch

**Detection**: `biometricEnabled == true` on cold start (`AppLockWrapper.initState`).

**Behavior**:
- Show lock screen immediately (current behavior is correct).
- Auto-trigger `authenticate()` after a 500ms delay on first launch (longer than resume's 300ms — gives splash/theme time to settle).
- If the app was just installed and biometric was never enabled, `biometricEnabled` defaults to `false` → no lock screen shown.

---

## 4. Settings Screen Design

### 4.1 Updated Security Screen Layout

```
┌──────────────────────────────────┐
│ ← Security                      │  ← AppBar, no center title
├──────────────────────────────────┤
│                                  │
│  APP LOCK                        │  ← Section header (labelSmall, primary)
│                                  │
│  ┌────────────────────────────┐  │
│  │ 👆  Biometric Lock    [🔘]│  │  ← SwitchListTile
│  │     Require fingerprint    │  │     secondary: Icon(Icons.fingerprint)
│  │     or face to open app    │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ ⏱  Lock Delay         >  │  │  ← ListTile → opens BottomSheet
│  │     After 5 seconds        │  │     trailing: Icon(Icons.chevron_right)
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────────┐
│  │ ℹ️  When enabled, you'll need  │  ← Card (surfaceContainerLow)
│  │     to authenticate every time │     bodySmall, onSurfaceVariant
│  │     you return to the app      │
│  │     after the lock delay.      │
│  └────────────────────────────────┘
│                                  │
│  DATA PROTECTION                 │  ← Section header
│  ...existing items...            │
└──────────────────────────────────┘
```

### 4.2 Toggle Confirmation Flow

**When enabling (toggle OFF → ON)**:

```
User taps toggle
       │
       ▼
  ┌─ canAuthenticate()? ──┐
  │                       │
  ▼ YES                   ▼ NO (no hardware or no enrollment)
  │                       │
  │                  Show AlertDialog:
  │                  ┌──────────────────────────┐
  │                  │ "Set up biometrics"       │
  │                  │                           │
  │                  │ Add a fingerprint in your │
  │                  │ device settings first.    │
  │                  │                           │
  │                  │ [Cancel]  [Open Settings] │
  │                  └──────────────────────────┘
  │                  Toggle stays OFF.
  │
  ▼
System BiometricPrompt appears:
"Confirm your identity to enable Biometric Lock"
       │
  ┌────┴────┐
  │         │
  ▼ OK      ▼ CANCEL/FAIL
  │         │
  │         Toggle stays OFF.
  │         No snackbar (silent).
  │
  ▼
Toggle turns ON.
Show SnackBar:
  "Biometric lock enabled ✓"
  (with SnackBarBehavior.floating, 3s duration)
```

**When disabling (toggle ON → OFF)**:

```
User taps toggle
       │
       ▼
Show confirmation dialog:
┌─────────────────────────────────┐
│ "Disable Biometric Lock?"       │  ← AlertDialog
│                                 │
│ The app will no longer require  │
│ authentication when opened.     │
│                                 │
│      [Cancel]    [Disable]      │  ← TextButton, FilledButton (error color)
└─────────────────────────────────┘
       │
  ┌────┴────┐
  │         │
  ▼ Disable ▼ Cancel
  │         │
  │         Toggle stays ON.
  │
  ▼
Toggle turns OFF.
appLockedProvider → false (ensure app doesn't re-lock).
SnackBar: "Biometric lock disabled"
```

### 4.3 Lock Delay Bottom Sheet

Triggered by tapping the "Lock Delay" `ListTile`. Only visible when biometric lock is enabled.

```
┌──────────────────────────────────┐
│ ─── (drag handle)                │  ← showModalBottomSheet, M3 style
│                                  │
│  Lock Delay                      │  ← titleMedium
│                                  │
│  How long to wait after leaving  │  ← bodySmall, onSurfaceVariant
│  the app before locking.         │
│                                  │
│  ○  Immediately                  │  ← RadioListTile group
│  ●  After 5 seconds             │     (selected = current value)
│  ○  After 15 seconds            │
│  ○  After 1 minute              │
│  ○  After 5 minutes             │
│                                  │
└──────────────────────────────────┘
```

**Widget**: `showModalBottomSheet` → `Column` of `RadioListTile<Duration>`.
**Storage**: New key in preferences: `lock_delay_seconds` (int). Default: `5`.
**Provider**: `lockDelayProvider` → `StateNotifierProvider<LockDelayNotifier, Duration>`.

### 4.4 Conditional Visibility

```dart
// Lock Delay tile only shown when biometric lock is on
if (enabled) ...[
  ListTile(
    leading: const Icon(Icons.timer_outlined),
    title: const Text('Lock Delay'),
    subtitle: Text(_formatDelay(delay)),  // "After 5 seconds"
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _showDelaySheet(context),
  ),
  _InfoCard(
    text: 'When enabled, you\'ll need to authenticate every time '
          'you return to the app after the lock delay.',
  ),
],
```

---

## 5. Grace Period (Lock Delay)

### 5.1 Behavior

| User action | Lock delay = 5s | Lock delay = 0 (Immediately) |
|-------------|-----------------|------------------------------|
| Background → resume in 2s | **No lock** (within grace) | **Locked** |
| Background → resume in 6s | **Locked** | **Locked** |
| Background → resume in 30s | **Locked** | **Locked** |
| Switch to another app and back quickly | **No lock** | **Locked** |
| Screen off → screen on in 3s | **No lock** | **Locked** |

### 5.2 Implementation in `AppLockWrapper`

```dart
class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  bool _authenticating = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Record when we went to background — don't lock yet
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkAndLock();
    }
  }

  void _checkAndLock() {
    final biometricEnabled = ref.read(biometricEnabledProvider).valueOrNull ?? false;
    if (!biometricEnabled) return;

    final lockDelay = ref.read(lockDelayProvider);  // Duration
    final backgroundedAt = _backgroundedAt;

    if (backgroundedAt == null) return;  // first launch handled separately

    final elapsed = DateTime.now().difference(backgroundedAt);

    if (elapsed >= lockDelay) {
      ref.read(appLockedProvider.notifier).setLocked(true);
      _authenticateIfLocked();
    }
    // else: within grace period — do nothing
    _backgroundedAt = null;
  }
}
```

### 5.3 Key Invariant

**Lock on `resumed`, not on `paused`.** The current implementation locks on `paused`, which means even a 0.1s background trip triggers the lock. By recording the timestamp on `paused` and checking elapsed time on `resumed`, we enable the grace period naturally.

---

## 6. First-Time Setup Flow

### 6.1 Flow Diagram

```
User navigates to Settings → Security
       │
       ▼
Sees "Biometric Lock" toggle (OFF)
       │
       ▼
Taps toggle ON
       │
       ▼
  ┌─ canAuthenticate()? ─────────────────────┐
  │                                           │
  ▼ YES                                       ▼ NO
  │                                           │
  System BiometricPrompt:                AlertDialog:
  "Confirm your identity to              "Set up biometrics"
   enable Biometric Lock"               [Cancel] [Open Settings]
       │                                      │
  ┌────┴────┐                            User goes to Android
  │         │                            Security settings,
  ▼ OK      ▼ CANCEL                    enrolls fingerprint,
  │         │                            returns to app.
  │       Toggle stays OFF               │
  │       (no error shown)               User retries toggle.
  │
  ▼
Toggle turns ON.
       │
       ▼
Show SnackBar: "Biometric lock enabled ✓"
       │
       ▼
"Lock Delay" tile appears below toggle.
Info card appears: "When enabled, you'll need
 to authenticate every time you return to the
 app after the lock delay."
       │
       ▼
Done. Next time user backgrounds + resumes
past the lock delay, lock screen appears.
```

### 6.2 No Onboarding Sheet Needed

Rationale: The settings screen itself provides enough context:
- The `SwitchListTile` subtitle explains what it does.
- The info `Card` explains when it activates.
- The confirmation biometric prompt proves it works.

Adding a multi-step onboarding wizard would violate the app's "clarity over cleverness" design principle and over-complicate what is a single toggle.

---

## 7. Widget & Provider Summary

### 7.1 New/Modified Widgets

| Widget | File | Change |
|--------|------|--------|
| `_LockScreen` | `app_lock_wrapper.dart` | **Rewrite**: Add states (idle/authenticating/failed/cancelled/no-enrollment), AnimatedSwitcher for icon, status message area, retry countdown, app icon branding |
| `AppLockWrapper` | `app_lock_wrapper.dart` | **Modify**: Replace `paused` → lock with timestamp-based grace period. Use `Stack` to keep child mounted. |
| `SecurityScreen` | `security_screen.dart` | **Modify**: Add disable confirmation dialog, Lock Delay tile (conditional), info Card |
| `_LockDelaySheet` | `security_screen.dart` | **New**: Modal bottom sheet with RadioListTile for delay options |
| `_InfoCard` | `security_screen.dart` | **New**: Small helper for the info card below toggle |

### 7.2 New/Modified Providers

| Provider | File | Change |
|----------|------|--------|
| `lockDelayProvider` | `security_provider.dart` | **New**: `AsyncNotifierProvider<LockDelayNotifier, Duration>`, persisted to SharedPreferences (key: `lock_delay_seconds`, default: `5`) |
| `biometricCapabilityProvider` | `security_provider.dart` | **New**: `FutureProvider<BiometricCapability>` returning an enum `{available, noHardware, notEnrolled}`. Used by both lock screen and settings to branch UX. |

### 7.3 BiometricService Additions

```dart
enum BiometricCapability {
  available,       // Hardware present + biometrics enrolled
  noHardware,      // No sensor, but device credentials available
  notEnrolled,     // Sensor present but no fingerprint/face enrolled
  unsupported,     // No authentication method at all (very rare)
}

class BiometricService {
  // Existing
  Future<bool> canAuthenticate();
  Future<bool> authenticate({String reason});

  // New
  Future<BiometricCapability> checkCapability();
  Future<void> openSecuritySettings();  // platform channel or url_launcher
}
```

---

## 8. Material 3 Component Checklist

| UI Element | M3 Component | Notes |
|------------|-------------|-------|
| Lock screen unlock button | `FilledButton.icon` | Primary action, 48dp min height |
| "Open Device Settings" button | `OutlinedButton` | Secondary action on lock screen |
| Settings biometric toggle | `SwitchListTile` | Standard M3 switch, uses `colorScheme.primary` |
| Lock Delay list tile | `ListTile` with `trailing: Icon(Icons.chevron_right)` | Opens bottom sheet |
| Lock Delay selector | `showModalBottomSheet` → `RadioListTile` | M3 bottom sheet with drag handle |
| Info card | `Card(color: colorScheme.surfaceContainerLow)` | elevation: 0, rounded 12dp |
| No-hardware banner | `MaterialBanner` | With `leading: Icon(Icons.info_outline)` |
| Enable success | `SnackBar` with `SnackBarBehavior.floating` | 3s duration |
| Disable confirmation | `AlertDialog` | Two actions: TextButton("Cancel"), FilledButton("Disable") |
| Setup needed dialog | `AlertDialog` | Two actions: TextButton("Cancel"), FilledButton("Open Settings") |
| Countdown text | `Text` in `bodySmall` | `colorScheme.onSurfaceVariant` |

---

## 9. Persona Validation

| Persona | Scenario | UX handles it? |
|---------|----------|----------------|
| **Maya** (moderate tech) | Enables biometric lock so kids can't open the finance app. Quick-switches between EveryPay and banking app. | ✅ Grace period (5s default) prevents re-lock on quick app switch. Toggle is self-explanatory. |
| **Kenji** (privacy-first) | Wants maximum security. Sets lock delay to "Immediately". | ✅ "Immediately" option available. Lock triggers on every resume. |
| **Barbara & Tom** (low tech) | Barbara accidentally cancels the biometric prompt. Doesn't know what to do. | ✅ Cancelled state shows "Unlock when you're ready" with persistent button. No jargon. |
| **Barbara & Tom** | Tom's phone has no fingerprint sensor. | ✅ Gracefully falls back to device PIN. Settings show informational banner. Lock screen says "Unlock with your device PIN or pattern". |
| **Priya** (high tech) | Enabled biometrics, app auto-locks during a client meeting. Opens app 2 minutes later. | ✅ Lock screen auto-triggers biometric prompt on resume. One fingerprint tap → unlocked. |

---

## 10. Implementation Priority

| Priority | Task | Effort |
|----------|------|--------|
| **P0** | Fix `FlutterFragmentActivity` (without this, nothing works) | 5 min |
| **P1** | Rewrite `_LockScreen` with states, icon animation, retry logic | 2–3 hr |
| **P1** | Add grace period (timestamp-based locking in `AppLockWrapper`) | 1 hr |
| **P2** | Add `BiometricCapability` enum + `checkCapability()` to service | 30 min |
| **P2** | Add `lockDelayProvider` + Lock Delay bottom sheet | 1 hr |
| **P2** | Add disable confirmation dialog + enable SnackBar in settings | 30 min |
| **P3** | Add info card + MaterialBanner for no-hardware case | 30 min |
| **P3** | Accessibility pass: Semantics, focus order, reduced motion | 1 hr |
| **P3** | Migrate `biometric_lock_enabled` to `flutter_secure_storage` | 1 hr |
