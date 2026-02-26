---
title: Every-Pay — UX Design: P2P Database Sync
version: 1.0.0
created: 2026-02-26
owner: UX Designer
status: Draft
references:
  - docs/REQUIREMENTS_SYNC.md
  - docs/RESEARCH_P2P_SYNC.md
  - docs/PERSONAS_EVERYPAY.md
  - docs/UX_DESIGN_EVERYPAY.md
  - lib/features/sync/screens/devices_screen.dart
  - lib/features/settings/screens/settings_screen.dart
  - lib/domain/entities/paired_device.dart
  - lib/domain/entities/sync_state.dart
  - lib/data/database/database_helper.dart
  - lib/router.dart
---

# Every-Pay — UX Design: P2P Database Sync

---

## Table of Contents

1. [Design Context](#1-design-context)
2. [Screen Inventory & Navigation](#2-screen-inventory--navigation)
3. [Flow 1 — Android Permissions](#3-flow-1--android-permissions)
4. [Flow 2 — Device Discovery & Pairing](#4-flow-2--device-discovery--pairing)
5. [Flow 3 — Paired Devices Management](#5-flow-3--paired-devices-management)
6. [Flow 4 — Sync Progress UI](#6-flow-4--sync-progress-ui)
7. [Flow 5 — Conflict Notification & Review](#7-flow-5--conflict-notification--review)
8. [Flow 6 — Settings Integration](#8-flow-6--settings-integration)
9. [State Diagrams](#9-state-diagrams)
10. [Accessibility Notes](#10-accessibility-notes)
11. [Component Inventory](#11-component-inventory)

---

## 1. Design Context

### Who Uses Sync

| Persona | Scenario | Tech Level |
|---------|----------|------------|
| Maya (34) | Syncs household expenses with partner's phone | Moderate |
| Barbara & Tom (68/71) | Tom sets up, Barbara views on her device | Low |
| Priya (42) | Syncs phone ↔ office tablet | High |

**Design implications:**
- Barbara & Tom need an extremely clear pairing flow with large text and no jargon
- Maya needs quick "just sync" — minimal taps after initial setup
- Priya needs trust signals (encrypted, local-only) since she handles business data

### Constraints from Research

- **Transport**: Nearby Connections API (BLE + Wi-Fi Direct) via `nearby_service`
- **Sync strategy**: Delta sync with LWW conflict resolution
- **Max paired devices**: 5
- **Permissions**: BLE, Wi-Fi, Fine Location (Android)
- **No internet required** — fully local P2P

### Design Principles (inherited from UX_DESIGN_EVERYPAY)

1. **Clarity over cleverness** — sync status must be unambiguous
2. **3-tap rule** — "Sync Now" reachable in ≤ 3 taps from Home
3. **Forgiving** — cancelled pairing can be retried immediately
4. **Inclusive** — WCAG AA, 48dp targets, screen reader labels

---

## 2. Screen Inventory & Navigation

### New & Modified Screens

| Screen | Route | Type | Purpose |
|--------|-------|------|---------|
| Devices Screen | `/settings/devices` | **Modify** (existing placeholder) | Paired device list + sync controls |
| Pair Device Sheet | — (modal bottom sheet) | **New** | Discovery → verification → paired |
| Sync Progress | — (overlay banner) | **New** | Inline sync status indicator |
| Conflict Review | `/settings/devices/conflicts` | **New** | Side-by-side conflict comparison |

### Route Changes to `router.dart`

```
/settings/devices                ← existing, enhance
/settings/devices/conflicts      ← new
```

### Navigation Map

```
Settings
└── Paired Devices (/settings/devices)
    ├── [FAB] Pair Device → showModalBottomSheet (PairDeviceSheet)
    │   ├── Permission gate
    │   ├── Discovery list
    │   ├── Verification code dialog
    │   └── Success / failure result
    ├── [Tile action] Sync Now → overlay SyncProgressBanner
    ├── [Swipe] Unpair → ConfirmDialog
    └── Conflict Review (/settings/devices/conflicts)
        └── Per-conflict cards with Keep This / Keep That
```

---

## 3. Flow 1 — Android Permissions

### Required Permissions (Nearby Connections API)

| Permission | Why | Android Level |
|------------|-----|---------------|
| `BLUETOOTH_SCAN` | Discover nearby devices | 12+ (API 31) |
| `BLUETOOTH_ADVERTISE` | Make this device visible | 12+ (API 31) |
| `BLUETOOTH_CONNECT` | Establish connection | 12+ (API 31) |
| `ACCESS_FINE_LOCATION` | Required for BLE scanning | All |
| `NEARBY_WIFI_DEVICES` | Wi-Fi Direct data transfer | 13+ (API 33) |

### Permission Request Flow

```
User taps "Pair Device" FAB
        │
        ▼
┌──────────────────────────┐
│  Check permissions        │
│  (permission_handler)     │
└──────────┬───────────────┘
           │
     ┌─────┴──────┐
     │ All granted │──── Yes ──→ Proceed to Discovery
     └─────┬──────┘
           │ No
           ▼
┌──────────────────────────┐
│  Rationale Bottom Sheet   │
│                           │
│  ┌─────────────────────┐  │
│  │  📍🔵📶             │  │
│  │                     │  │
│  │  Permissions Needed │  │
│  │                     │  │
│  │  To find nearby     │  │
│  │  devices, Every-Pay │  │
│  │  needs access to:   │  │
│  │                     │  │
│  │  • Bluetooth        │  │
│  │    Find & connect   │  │
│  │    to your devices  │  │
│  │                     │  │
│  │  • Location         │  │
│  │    Required by      │  │
│  │    Android for      │  │
│  │    Bluetooth scans  │  │
│  │                     │  │
│  │  • Wi-Fi            │  │
│  │    Transfer data    │  │
│  │    at high speed    │  │
│  │                     │  │
│  │  🔒 No data leaves  │  │
│  │  your local network │  │
│  │                     │  │
│  │  [Continue]         │  │
│  │  [Not Now]          │  │
│  └─────────────────────┘  │
└──────────────────────────┘
           │
     ┌─────┴──────┐
     │ User taps   │
     │ "Continue"  │
     └─────┬──────┘
           │
           ▼
     System permission dialogs (sequential)
           │
     ┌─────┴──────────┐
     │ All granted?    │
     └──┬──────────┬──┘
        │ Yes      │ No (denied/permanent)
        ▼          ▼
   Discovery    Permission Denied State
```

### Permission Denied State

Shown inline in the PairDeviceSheet instead of the discovery list:

```
┌─────────────────────────────────────┐
│                                     │
│         🚫                          │
│                                     │
│   Permissions Required              │
│                                     │
│   Every-Pay needs Bluetooth and     │
│   Location permissions to find      │
│   nearby devices.                   │
│                                     │
│   [Open Settings]                   │
│                                     │
│   Tap "Open Settings" to grant      │
│   permissions manually.             │
│                                     │
└─────────────────────────────────────┘
```

### Widget Structure

```dart
// Permission rationale — M3 bottom sheet
showModalBottomSheet(
  child: _PermissionRationaleSheet(
    // 3 icon+label rows explaining each permission
    // privacy reassurance text
    // FilledButton("Continue") → request permissions
    // TextButton("Not Now") → dismiss
  ),
);

// Permission denied — EmptyStateView variant
EmptyStateView(
  icon: Icons.nearby_error,       // or Icons.bluetooth_disabled
  title: 'Permissions Required',
  subtitle: '...',
  action: FilledButton(
    onPressed: () => openAppSettings(),
    child: Text('Open Settings'),
  ),
);
```

### Semantic Labels

- Rationale sheet: `Semantics(label: 'Permission explanation dialog')`
- Each permission row: `Semantics(label: 'Bluetooth permission: needed to find and connect to your devices')`
- "Open Settings" button: `Semantics(label: 'Open system settings to grant permissions')`

---

## 4. Flow 2 — Device Discovery & Pairing

### Overview

Pairing uses Nearby Connections API for discovery + a 6-digit verification code
for mutual confirmation (replaces QR code from REQUIREMENTS_SYNC for simplicity —
both users can initiate from the same "Pair Device" button; no camera needed).

### User Journey (Happy Path)

```
Device A (Maya's phone)                  Device B (Partner's phone)
─────────────────────────                ──────────────────────────
1. Tap "Pair Device" FAB                 1. Tap "Pair Device" FAB
2. Sheet opens, scanning...              2. Sheet opens, scanning...
3. Sees "Partner's Pixel"                3. Sees "Maya's Galaxy"
4. Taps "Partner's Pixel"                4. (Connection request received)
5. Code dialog: "847 293"                5. Code dialog: "847 293"
6. Taps "Codes Match" ✓                  6. Taps "Codes Match" ✓
7. "Paired!" success                     7. "Paired!" success
8. Sheet dismisses                       8. Sheet dismisses
9. Device appears in list                9. Device appears in list
```

### PairDeviceSheet — Modal Bottom Sheet

Full-height modal bottom sheet with drag handle. Uses `DraggableScrollableSheet`
wrapping the content so the sheet can expand as the device list grows.

#### State 1: Scanning (initial)

```
┌─────────────────────────────────────────┐
│  ─────                                  │  ← Drag handle
│                                         │
│  Pair New Device                        │  ← titleLarge
│                                         │
│  Make sure both devices have Every-Pay  │  ← bodyMedium, onSurfaceVariant
│  open and are tapping "Pair Device"     │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  ◠  Searching for nearby       │    │  ← LinearProgressIndicator
│  │     devices...                  │    │     (indeterminate)
│  └─────────────────────────────────┘    │
│                                         │
│  (empty — no devices found yet)         │
│                                         │
│            [Cancel]                     │  ← TextButton
└─────────────────────────────────────────┘
```

#### State 2: Devices Found

```
┌─────────────────────────────────────────┐
│  ─────                                  │
│                                         │
│  Pair New Device                        │
│                                         │
│  Tap a device to pair                   │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  📱 Partner's Pixel 8          →│    │  ← ListTile, onTap → connect
│  ├─────────────────────────────────┤    │
│  │  📱 Tom's Galaxy A54           →│    │  ← Another discovered device
│  └─────────────────────────────────┘    │
│                                         │
│  ◠  Still searching...                  │  ← Subtle indicator
│                                         │
│            [Cancel]                     │
└─────────────────────────────────────────┘
```

Device list items use:
- `ListTile` with `leading: Icon(Icons.smartphone)`
- `title: Text(deviceName)` — from Nearby Connections endpoint info
- `trailing: Icon(Icons.chevron_right)`
- Ripple feedback on tap
- Animated entry: `SlideTransition` + `FadeTransition` as devices appear

#### State 3: Connecting (after user taps a device)

```
┌─────────────────────────────────────────┐
│  ─────                                  │
│                                         │
│  Connecting...                          │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │        ◠                        │    │  ← CircularProgressIndicator
│  │                                 │    │
│  │  Connecting to                  │    │
│  │  Partner's Pixel 8              │    │
│  └─────────────────────────────────┘    │
│                                         │
│            [Cancel]                     │
└─────────────────────────────────────────┘
```

#### State 4: Verification Code

Both devices show the same 6-digit code (derived from connection token).
The code is split into two 3-digit groups for readability.

```
┌─────────────────────────────────────────┐
│  ─────                                  │
│                                         │
│  Verify Connection                      │
│                                         │
│  Confirm this code matches the          │
│  code shown on the other device:        │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │        847  293                 │    │  ← displayLarge, monospace
│  │                                 │    │     letterSpacing: 4
│  │  Pairing with: Partner's Pixel  │    │  ← bodyMedium
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │       ✓  Codes Match            │    │  ← FilledButton.icon
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │       ✗  Doesn't Match          │    │  ← OutlinedButton.icon
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

Buttons are full-width, stacked, 48dp+ height, clear visual distinction.

#### State 5: Pairing Success

```
┌─────────────────────────────────────────┐
│  ─────                                  │
│                                         │
│        ✅                               │  ← 64dp icon, primary color
│                                         │
│    Device Paired!                       │  ← titleLarge
│                                         │
│    Partner's Pixel 8 is now             │  ← bodyMedium
│    paired with this device.             │
│    Expenses will sync automatically.    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │         Done                    │    │  ← FilledButton → pop sheet
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

Auto-dismisses after 3 seconds if user doesn't tap "Done".

### Error States

#### No Devices Found (after 15-second timeout)

```
┌─────────────────────────────────────────┐
│  ─────                                  │
│                                         │
│  Pair New Device                        │
│                                         │
│        📱❓                              │
│                                         │
│  No devices found                       │  ← titleMedium
│                                         │
│  Make sure the other device has         │  ← bodyMedium, onSurfaceVariant
│  Every-Pay open and is also tapping     │
│  "Pair Device" at the same time.        │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │       🔄  Try Again             │    │  ← FilledButton.icon → restart scan
│  └─────────────────────────────────┘    │
│            [Cancel]                     │
│                                         │
└─────────────────────────────────────────┘
```

#### Pairing Failed (connection error or code mismatch)

```
┌─────────────────────────────────────────┐
│  ─────                                  │
│                                         │
│        ⚠️                               │  ← 64dp, error color
│                                         │
│    Pairing Failed                       │  ← titleLarge
│                                         │
│    Could not establish a secure         │  ← bodyMedium
│    connection with Partner's Pixel 8.   │
│                                         │
│    This can happen if:                  │
│    • The other device cancelled         │
│    • Devices moved too far apart        │
│    • Bluetooth is turned off            │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │       🔄  Try Again             │    │
│  └─────────────────────────────────┘    │
│            [Cancel]                     │
│                                         │
└─────────────────────────────────────────┘
```

#### Codes Don't Match (user taps "Doesn't Match")

Immediately rejects the connection. Shows:

```
Connection cancelled for your security.
The other device has been notified.

[Try Again]   [Cancel]
```

### Widget Structure

```dart
// Entry point: called from DevicesScreen FAB
void _startPairing(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const PairDeviceSheet(),
  );
}

// PairDeviceSheet is a ConsumerStatefulWidget
// Internal state managed by a Riverpod provider:

enum PairingPhase {
  checkingPermissions,
  permissionDenied,
  scanning,
  devicesFound,
  connecting,
  verifyingCode,
  success,
  error,
  noDevicesFound,
}

// Provider
@riverpod
class PairingController extends _$PairingController {
  // Manages: phase, discoveredDevices, verificationCode, error
}
```

### Timing

| Phase | Timeout | On timeout |
|-------|---------|------------|
| Scanning | 15 seconds | → `noDevicesFound` state |
| Connecting | 10 seconds | → `error` state with retry |
| Verification (waiting for other device) | 30 seconds | → `error` state |
| Post-success auto-dismiss | 3 seconds | → pop sheet |

---

## 5. Flow 3 — Paired Devices Management

### DevicesScreen — Enhanced

Replaces the current placeholder. Three visual states: empty, has devices,
and a loading shimmer while fetching from DB.

#### State 1: Empty (No Paired Devices)

```
┌─────────────────────────────────────────┐
│  ←  Paired Devices                      │  ← AppBar
├─────────────────────────────────────────┤
│                                         │
│                                         │
│         📱                              │  ← EmptyStateView
│                                         │
│    No paired devices                    │
│                                         │
│    Pair with another device to          │
│    sync your expense data across        │
│    your devices.                        │
│                                         │
│    Both devices must have Every-Pay     │
│    installed and be nearby.             │
│                                         │
│                                         │
│                                         │
│                              [+ Pair]   │  ← FAB.extended
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

Uses existing `EmptyStateView` widget with `icon: Icons.devices`.

#### State 2: Devices Listed

```
┌─────────────────────────────────────────┐
│  ←  Paired Devices                      │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📱  Partner's Pixel 8           │    │
│  │     Last synced: 2 min ago      │    │  ← subtitle: relative time
│  │     🟢 Online                   │    │  ← status indicator
│  │                        [Sync ↻] │    │  ← IconButton
│  ├─────────────────────────────────┤    │
│  │ 📱  Office Tablet               │    │
│  │     Last synced: 3 days ago     │    │
│  │     ⚫ Offline                  │    │  ← grey dot
│  │                        [Sync ↻] │    │  ← disabled when offline
│  └─────────────────────────────────┘    │
│                                         │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│  2 of 5 device slots used              │  ← labelSmall, onSurfaceVariant
│                                         │
│                              [+ Pair]   │  ← FAB.extended
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

### Device List Item — Widget Structure

```dart
// Each device is a Card with a ListTile
Card(
  child: ListTile(
    leading: Icon(Icons.smartphone),
    title: Text(device.deviceName),                    // titleMedium
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last synced: ${relativeTime}'),          // bodySmall
        Row(children: [
          _OnlineIndicator(isOnline: device.isOnline), // 8dp colored dot
          SizedBox(width: 4),
          Text(device.isOnline ? 'Online' : 'Offline'),// labelSmall
        ]),
      ],
    ),
    trailing: IconButton(
      icon: Icon(Icons.sync),
      onPressed: device.isOnline ? () => syncNow(device) : null,
      tooltip: 'Sync now',
    ),
    isThreeLine: true,
  ),
);
```

### Online/Offline Status

- **Online indicator**: 8dp filled circle
  - `Colors.green` (online) — device discovered on current scan
  - `Theme.colorScheme.outline` (offline) — not discovered
- Discovery runs in background every 30s when DevicesScreen is visible
- `isOnline` is a transient UI state (not persisted), set by discovery callbacks

### Swipe to Unpair

```dart
Dismissible(
  key: Key(device.id),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Theme.of(context).colorScheme.error,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 24),
    child: Icon(Icons.link_off, color: Colors.white),
  ),
  confirmDismiss: (_) => showConfirmDialog(
    context,
    title: 'Unpair Device?',
    content: 'This will remove "${device.deviceName}" from your '
             'paired devices. You can pair again later.\n\n'
             'Synced data will remain on both devices.',
    confirmText: 'Unpair',
    isDestructive: true,
  ),
  onDismissed: (_) => ref.read(pairedDevicesProvider.notifier).unpair(device.id),
);
```

Confirmation uses existing `showConfirmDialog` from `shared/widgets/confirm_dialog.dart`.

### Long-Press Context Menu (alternative to swipe for accessibility)

```dart
// PopupMenuButton in trailing, or long-press on tile:
PopupMenuButton<String>(
  itemBuilder: (_) => [
    PopupMenuItem(value: 'sync', child: Text('Sync Now')),
    PopupMenuItem(value: 'rename', child: Text('Rename')),
    PopupMenuItem(
      value: 'unpair',
      child: Text('Unpair', style: TextStyle(color: colorScheme.error)),
    ),
  ],
);
```

### Max Devices Reached (5/5)

FAB becomes disabled. Tooltip: "Maximum 5 devices. Unpair one to add another."

```dart
FloatingActionButton.extended(
  onPressed: canPairMore ? _startPairing : null,
  icon: Icon(Icons.add),
  label: Text('Pair Device'),
  // M3 handles disabled FAB styling automatically
);
```

---

## 6. Flow 4 — Sync Progress UI

### Design Decision: In-Screen Banner (not bottom sheet, not overlay)

**Why a banner and not a modal/bottom sheet?**
- Sync can take 1–15 seconds — a modal blocks the UI unnecessarily
- Users should be able to navigate away while sync continues
- A persistent, dismissible banner is non-blocking and informative

**Location**: Appears at the top of the DevicesScreen body, below AppBar.
When triggered from Settings quick-action, shows as a `SnackBar` with progress.

### Sync Progress Banner — In DevicesScreen

```
┌─────────────────────────────────────────┐
│  ←  Paired Devices                      │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ ↻ Syncing with Partner's Pixel  │    │  ← SyncProgressBanner
│  │ ▓▓▓▓▓▓▓▓▓▓▓░░░░░ 68%          │    │     LinearProgressIndicator
│  │ 8 of 12 expenses sent...       │    │     (determinate)
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📱  Partner's Pixel 8           │    │
│  │     Syncing... ↻                │    │  ← status changes during sync
│  │     🟢 Online                   │    │
│  ...                                    │
```

### Sync Phases

```
┌──────────┐    ┌─────────┐    ┌──────────┐    ┌──────────────┐
│Connecting│───→│Syncing  │───→│Finishing │───→│  Complete /  │
│          │    │ (0-100%)│    │          │    │    Error     │
└──────────┘    └─────────┘    └──────────┘    └──────────────┘
```

#### Phase: Connecting

```
┌──────────────────────────────────────┐
│  ◠  Connecting to Partner's Pixel... │  ← indeterminate progress
└──────────────────────────────────────┘
```

#### Phase: Syncing (with progress)

```
┌──────────────────────────────────────┐
│  ↻ Syncing with Partner's Pixel      │
│  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░ 68%           │  ← determinate LinearProgressIndicator
│  Sending expenses...                 │
└──────────────────────────────────────┘
```

Progress is calculated as: `(records sent + records received) / total records`.

#### Phase: Complete (auto-dismisses after 4 seconds)

```
┌──────────────────────────────────────┐
│  ✓ Sync complete                     │  ← primary color, check icon
│  12 expenses · 3 categories synced   │
│  0 conflicts                    [✕]  │  ← close button
└──────────────────────────────────────┘
```

#### Phase: Complete with Conflicts

```
┌──────────────────────────────────────┐
│  ✓ Sync complete                     │
│  12 expenses synced                  │
│  ⚠ 2 conflicts · 1 needs review     │  ← warning color
│                        [Review]  [✕] │  ← TextButton → conflict screen
└──────────────────────────────────────┘
```

#### Phase: Error

```
┌──────────────────────────────────────┐
│  ✗ Sync failed                       │  ← error color
│  Connection lost during transfer     │
│                        [Retry]   [✕] │
└──────────────────────────────────────┘
```

### Widget Structure

```dart
class SyncProgressBanner extends ConsumerWidget {
  // Listens to syncProgressProvider
  // Returns AnimatedSwitcher wrapping the current phase widget
  // Each phase is a Material Card with:
  //   - Leading icon (animated sync icon / check / error)
  //   - Title + subtitle text
  //   - Optional LinearProgressIndicator
  //   - Optional action buttons
}

// Riverpod state
@freezed
class SyncProgress with _$SyncProgress {
  const factory SyncProgress.idle() = _Idle;
  const factory SyncProgress.connecting(String deviceName) = _Connecting;
  const factory SyncProgress.syncing({
    required String deviceName,
    required double progress,     // 0.0 - 1.0
    required String statusText,   // "Sending expenses..."
  }) = _Syncing;
  const factory SyncProgress.complete({
    required SyncResult result,
  }) = _Complete;
  const factory SyncProgress.error({
    required String deviceName,
    required String message,
  }) = _Error;
}

@freezed
class SyncResult with _$SyncResult {
  const factory SyncResult({
    required int expensesSynced,
    required int categoriesSynced,
    required int conflictsAutoResolved,
    required int conflictsNeedingReview,
  }) = _SyncResult;
}
```

### Global Sync Indicator (when navigating away)

When a sync is in progress and the user navigates away from DevicesScreen,
show a subtle indicator in the Settings screen's "Paired Devices" tile:

```
┌─────────────────────────────────────┐
│  📱  Paired Devices                 │
│       Syncing... ↻                  │  ← animated sync icon
│                                  →  │
└─────────────────────────────────────┘
```

This is achieved by watching `syncProgressProvider` in SettingsScreen.

---

## 7. Flow 5 — Conflict Notification & Review

### Conflict Resolution Strategy

From REQUIREMENTS_SYNC.md:
- **Default**: Last-write-wins (LWW) by `updated_at`
- **Tiebreaker**: Higher `device_id` (lexicographic)
- **Delete vs Edit**: Edit wins (resurrection rule)

### UX Enhancement: User Review for Amount Conflicts

While LWW is applied automatically for most fields, **amount differences**
represent financial data where silent resolution could cause real confusion.

| Conflict Type | Resolution | User Notification |
|---------------|------------|-------------------|
| Name, notes, category changes | LWW auto-resolve | Subtle SnackBar |
| Amount differs | Flag for user review | Banner + review screen |
| Delete vs edit | Edit wins auto-resolve | Subtle SnackBar |
| New record (no conflict) | Merge | None |

### Auto-Resolved Conflicts — SnackBar

For conflicts resolved automatically (non-amount):

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('3 changes synced, 1 conflict auto-resolved'),
    action: SnackBarAction(
      label: 'Details',
      onPressed: () => context.go('/settings/devices/conflicts'),
    ),
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 4),
  ),
);
```

### Amount Conflicts — Conflict Review Screen

Route: `/settings/devices/conflicts`

```
┌─────────────────────────────────────────┐
│  ←  Review Conflicts                    │
├─────────────────────────────────────────┤
│                                         │
│  2 expenses need your attention         │  ← bodyMedium
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Netflix                        │    │  ← Conflict card
│  │                                 │    │
│  │  ┌────────────┬────────────┐    │    │
│  │  │ This Device│Other Device│    │    │
│  │  ├────────────┼────────────┤    │    │
│  │  │ $15.49     │ $17.99    │    │    │  ← amount highlighted
│  │  │ Monthly    │ Monthly    │    │    │
│  │  │ Changed    │ Changed    │    │    │
│  │  │ Feb 25     │ Feb 26     │    │    │  ← timestamps
│  │  └────────────┴────────────┘    │    │
│  │                                 │    │
│  │  [Keep $15.49]  [Keep $17.99]   │    │  ← Two OutlinedButtons
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Spotify                        │    │
│  │                                 │    │
│  │  ┌────────────┬────────────┐    │    │
│  │  │ This Device│Other Device│    │    │
│  │  ├────────────┼────────────┤    │    │
│  │  │ $9.99      │ $14.99    │    │    │
│  │  │ Monthly    │ Yearly     │    │    │  ← cycle diff also shown
│  │  │ Changed    │ Changed    │    │    │
│  │  │ Feb 24     │ Feb 25     │    │    │
│  │  └────────────┴────────────┘    │    │
│  │                                 │    │
│  │  [Keep $9.99]  [Keep $14.99]    │    │  ← Two OutlinedButtons
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Keep all from this device      │    │  ← TextButton for batch action
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  Keep all from other device     │    │  ← TextButton for batch action
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Conflict Card Widget

```dart
class ConflictCard extends StatelessWidget {
  final String expenseName;
  final ConflictSide localSide;    // amount, cycle, updatedAt
  final ConflictSide remoteSide;
  final VoidCallback onKeepLocal;
  final VoidCallback onKeepRemote;

  // Card with:
  //   - Expense name as title
  //   - DataTable or Row with two columns (This Device / Other Device)
  //   - Differing values highlighted with colorScheme.errorContainer background
  //   - Two action buttons at bottom
}
```

### Side-by-Side Comparison — Highlighting Differences

Fields that differ between the two versions get a highlight background:

```dart
Container(
  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  child: Text(
    '\$17.99',
    style: theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onErrorContainer,
      fontWeight: FontWeight.bold,
    ),
  ),
);
```

### After All Conflicts Resolved

```
┌─────────────────────────────────────────┐
│  ←  Review Conflicts                    │
├─────────────────────────────────────────┤
│                                         │
│         ✅                              │
│                                         │
│    All conflicts resolved               │
│                                         │
│    Your expense data is now             │
│    consistent across devices.           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │           Done                  │    │  ← FilledButton → pop
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Pending Conflicts Badge

If conflicts remain unresolved, show a badge on the Settings > Paired Devices tile:

```
┌─────────────────────────────────────────┐
│  📱  Paired Devices               2 ⚠  │  ← Badge with conflict count
│       P2P sync with nearby devices   →  │
└─────────────────────────────────────────┘
```

Widget: `Badge(label: Text('2'), child: Icon(Icons.devices))`

---

## 8. Flow 6 — Settings Integration

### Enhanced SYNC Section in SettingsScreen

```
┌─────────────────────────────────────────┐
│  SYNC                                   │  ← _SectionHeader
├─────────────────────────────────────────┤
│  📱  Paired Devices               2  →  │  ← existing tile, add device count
│       P2P sync with nearby devices      │
├─────────────────────────────────────────┤
│  ↻   Auto-Sync                   [🔵]  │  ← SwitchListTile (new)
│      Sync when paired device nearby     │
├─────────────────────────────────────────┤
│  ⏱   Sync Frequency                 →  │  ← ListTile (new)
│      Every 15 minutes                   │     visible only when auto-sync on
├─────────────────────────────────────────┤
│  ↻   Sync Now                        →  │  ← ListTile (new)
│      Last synced: 2 min ago             │     triggers sync with all online
└─────────────────────────────────────────┘
```

### Auto-Sync Toggle

```dart
SwitchListTile(
  secondary: Icon(Icons.sync),
  title: Text('Auto-Sync'),
  subtitle: Text('Sync when a paired device is nearby'),
  value: autoSyncEnabled,
  onChanged: (val) => ref.read(syncSettingsProvider.notifier).setAutoSync(val),
);
```

When enabled:
- Background discovery runs via `nearby_service` when app is in foreground
- When a paired device is discovered → auto-trigger delta sync
- Frequency setting controls how often auto-sync happens

### Sync Frequency Options

Shown as a dialog when tapping the tile (only visible when auto-sync is on):

```dart
showDialog(
  builder: (_) => SimpleDialog(
    title: Text('Sync Frequency'),
    children: [
      RadioListTile(title: Text('Every 5 minutes'), ...),
      RadioListTile(title: Text('Every 15 minutes'), ...),   // default
      RadioListTile(title: Text('Every 30 minutes'), ...),
      RadioListTile(title: Text('Every hour'), ...),
    ],
  ),
);
```

### "Sync Now" Quick Action

```dart
ListTile(
  leading: Icon(Icons.sync),
  title: Text('Sync Now'),
  subtitle: Text(_lastSyncText(syncState)),  // "Last synced: 2 min ago" or "Never"
  trailing: _isSyncing
      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
      : Icon(Icons.chevron_right),
  onTap: _isSyncing ? null : () => _triggerSyncAll(ref),
  enabled: hasPairedDevices && !_isSyncing,
);
```

Behavior:
- Triggers delta sync with **all online paired devices**
- Shows `CircularProgressIndicator` in trailing while syncing
- On complete: updates subtitle to "Just now"
- On error: shows SnackBar with error message and retry action
- Disabled (greyed out) if no devices are paired

### Settings Provider Structure

```dart
@riverpod
class SyncSettings extends _$SyncSettings {
  // Persisted to SharedPreferences
  bool autoSyncEnabled = false;
  Duration syncFrequency = Duration(minutes: 15);
}
```

---

## 9. State Diagrams

### 9.1 Pairing Flow State Machine

```
                    ┌─────────────┐
                    │   IDLE      │
                    └──────┬──────┘
                           │ User taps "Pair Device"
                           ▼
                ┌──────────────────────┐
                │ CHECKING_PERMISSIONS │
                └──────────┬───────────┘
                     ┌─────┴─────┐
                     │           │
              Granted ▼     Denied ▼
         ┌────────────┐   ┌──────────────────┐
         │  SCANNING   │   │ PERMISSION_DENIED│
         └──────┬──────┘   └──────────────────┘
                │                    │
         ┌──────┴──────┐      Opens settings
         │             │      then retries
    Found ▼      Timeout ▼
┌──────────────┐  ┌──────────────────┐
│DEVICES_FOUND │  │ NO_DEVICES_FOUND │
└──────┬───────┘  └────────┬─────────┘
       │ User taps          │ Retry
       │ a device           └──→ SCANNING
       ▼
┌──────────────┐
│ CONNECTING   │
└──────┬───────┘
       │
  ┌────┴────┐
  │         │
OK ▼    Fail ▼
┌────────────────┐  ┌───────────┐
│VERIFYING_CODE  │  │  ERROR    │──→ Retry → SCANNING
└──────┬─────────┘  └───────────┘
       │
  ┌────┴──────┐
  │           │
Match ▼  No match ▼
┌──────────┐  ┌───────────┐
│ SUCCESS  │  │  ERROR    │──→ Retry → SCANNING
└──────────┘  └───────────┘
       │
       │ Auto-dismiss / "Done"
       ▼
    ┌──────┐
    │ IDLE │
    └──────┘
```

### 9.2 Sync Progress State Machine

```
┌──────┐
│ IDLE │
└──┬───┘
   │ "Sync Now" tapped / auto-sync triggered
   ▼
┌────────────┐
│ CONNECTING │──── timeout (10s) ──→ ERROR
└────┬───────┘
     │ connected
     ▼
┌──────────┐
│ SYNCING  │──── connection lost ──→ ERROR
│ (0-100%) │
└────┬─────┘
     │ transfer complete
     ▼
┌────────────┐
│ FINISHING  │  ← applying changes, resolving conflicts
└────┬───────┘
     │
     ├── no conflicts needing review ──→ COMPLETE
     │
     └── has amount conflicts ──→ COMPLETE_WITH_CONFLICTS
                                      │
                                      │ user reviews
                                      ▼
                                  CONFLICTS_RESOLVED ──→ IDLE

ERROR ──→ Retry ──→ CONNECTING
ERROR ──→ Dismiss ──→ IDLE
COMPLETE ──→ auto-dismiss (4s) ──→ IDLE
```

### 9.3 Device Online Status State Machine

```
                   ┌─────────┐
          ┌───────→│ OFFLINE │◄──────────┐
          │        └────┬────┘           │
          │             │ discovered     │ lost / 60s no heartbeat
          │             ▼                │
          │        ┌─────────┐           │
          │        │ ONLINE  │───────────┘
          │        └────┬────┘
          │             │ user taps Sync
          │             ▼
          │        ┌─────────┐
          └────────│ SYNCING │
           done    └─────────┘
```

---

## 10. Accessibility Notes

### Screen Reader Support

| Element | Semantics Label |
|---------|----------------|
| Online indicator (green dot) | `"Online — last synced 2 minutes ago"` |
| Offline indicator (grey dot) | `"Offline — last synced 3 days ago"` |
| Sync button (enabled) | `"Sync now with Partner's Pixel 8"` |
| Sync button (disabled) | `"Sync unavailable — Partner's Pixel 8 is offline"` |
| Verification code | `"Verification code: 8 4 7 2 9 3"` (digits read individually) |
| Sync progress banner | `"Syncing with Partner's Pixel 8, 68 percent complete"` |
| Conflict card | `"Netflix conflict: this device 15 dollars 49, other device 17 dollars 99"` |
| FAB (pair) | `"Pair a new device"` |
| FAB (disabled) | `"Maximum devices reached, unpair a device first"` |
| Swipe to unpair | `"Swipe left to unpair Partner's Pixel 8"` |

### Keyboard Navigation

- All interactive elements reachable via Tab key
- Conflict card buttons have clear focus indicators
- Verification code buttons have large focus rectangles (48dp+)

### Touch Targets

- All buttons: minimum 48×48dp
- Verification code buttons: full-width, 56dp height
- Device list items: 72dp+ height (three-line ListTile)
- Swipe dismiss zone: full tile width

### Color Contrast

- Online status uses icon + text label (not color alone)
- Conflict highlights use errorContainer + bold text (not just color)
- Progress bar has percentage text alongside the visual bar

### Text Scaling

- All text uses Material `textTheme` tokens (scales with system font size)
- Verification code: `displayLarge` at minimum — remains readable at 200% scale
- Layout uses `Flexible`/`Expanded` to handle text overflow at large scales

---

## 11. Component Inventory

### New Widgets to Build

| Widget | Location | Type | Reuses |
|--------|----------|------|--------|
| `PairDeviceSheet` | `lib/features/sync/widgets/pair_device_sheet.dart` | Modal bottom sheet | — |
| `PermissionRationaleSheet` | `lib/features/sync/widgets/permission_rationale_sheet.dart` | Modal bottom sheet | — |
| `DeviceListTile` | `lib/features/sync/widgets/device_list_tile.dart` | Stateless widget | `ListTile` |
| `OnlineIndicator` | `lib/features/sync/widgets/online_indicator.dart` | Stateless widget | — |
| `VerificationCodeDisplay` | `lib/features/sync/widgets/verification_code_display.dart` | Stateless widget | — |
| `SyncProgressBanner` | `lib/features/sync/widgets/sync_progress_banner.dart` | Consumer widget | `LinearProgressIndicator` |
| `ConflictCard` | `lib/features/sync/widgets/conflict_card.dart` | Stateless widget | `Card` |
| `ConflictReviewScreen` | `lib/features/sync/screens/conflict_review_screen.dart` | Consumer widget | `EmptyStateView` |

### Existing Widgets Reused

| Widget | From | Used In |
|--------|------|---------|
| `EmptyStateView` | `shared/widgets/empty_state.dart` | DevicesScreen (empty), ConflictReviewScreen (resolved) |
| `showConfirmDialog` | `shared/widgets/confirm_dialog.dart` | Unpair confirmation |
| `_SectionHeader` | `settings_screen.dart` | SYNC section (already exists) |

### New Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `pairedDevicesProvider` | `AsyncNotifier<List<PairedDevice>>` | CRUD for paired devices list |
| `pairingControllerProvider` | `Notifier<PairingState>` | Manages pairing flow state machine |
| `syncProgressProvider` | `Notifier<SyncProgress>` | Tracks sync progress per device |
| `syncSettingsProvider` | `Notifier<SyncSettings>` | Auto-sync toggle + frequency |
| `deviceOnlineStatusProvider` | `StreamProvider<Map<String,bool>>` | Discovery heartbeat stream |
| `pendingConflictsProvider` | `AsyncNotifier<List<Conflict>>` | Unresolved conflicts list |

### New Routes

```dart
// Add to router.dart under /settings/devices
GoRoute(
  path: 'devices',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const DevicesScreen(),
  routes: [
    GoRoute(
      path: 'conflicts',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ConflictReviewScreen(),
    ),
  ],
),
```

### File Structure Summary

```
lib/features/sync/
├── screens/
│   ├── devices_screen.dart          ← enhance (existing)
│   └── conflict_review_screen.dart  ← new
├── widgets/
│   ├── pair_device_sheet.dart       ← new
│   ├── permission_rationale_sheet.dart ← new
│   ├── device_list_tile.dart        ← new
│   ├── online_indicator.dart        ← new
│   ├── verification_code_display.dart ← new
│   ├── sync_progress_banner.dart    ← new
│   └── conflict_card.dart           ← new
├── providers/
│   ├── paired_devices_provider.dart ← new
│   ├── pairing_controller.dart      ← new
│   ├── sync_progress_provider.dart  ← new
│   ├── sync_settings_provider.dart  ← new
│   └── pending_conflicts_provider.dart ← new
└── services/                        ← existing (empty)
    └── (transport layer implementation — separate task)
```
