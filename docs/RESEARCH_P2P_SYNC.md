# Research: P2P Database Sync Between Devices

> **Project**: EveryPay (org.cmwen.everypay)  
> **Date**: 2026-02-25  
> **Status**: Research Complete

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Analysis](#2-current-state-analysis)
3. [P2P Transport Options](#3-p2p-transport-options)
4. [Sync Strategies](#4-sync-strategies)
5. [Data Format for Sync](#5-data-format-for-sync)
6. [Conflict Resolution](#6-conflict-resolution)
7. [Security During P2P Transfer](#7-security-during-p2p-transfer)
8. [Architecture Design](#8-architecture-design)
9. [Package Comparison Matrix](#9-package-comparison-matrix)
10. [Implementation Roadmap](#10-implementation-roadmap)
11. [Practical Considerations](#11-practical-considerations)
12. [Testing Strategy](#12-testing-strategy)

---

## 1. Executive Summary

### Recommendation

**Use `nearby_service` (or `flutter_nearby_connections`) for transport + custom delta-sync engine with last-write-wins (LWW) conflict resolution.**

**Why not full CRDT?** EveryPay's data model (expenses, categories, payment methods) consists of simple records with non-collaborative editing. A CRDT system like `sql_crdt` / `sqlite_crdt` would require a **complete database rewrite** — replacing all sqflite queries with CRDT-aware wrappers. The existing `ConflictResolver` + `device_id` + `updated_at` timestamps already provide LWW semantics with deterministic tiebreaking. This is sufficient for personal expense sync between your own devices.

**Why not raw TCP/mDNS?** The project already has abstract `SyncService` with mDNS discovery stubs, but Google's Nearby Connections API (wrapped by Flutter plugins) handles discovery, connection negotiation, encryption, and multi-transport (BLE + Wi-Fi Direct + Wi-Fi hotspot) automatically. This saves 2-3 months of low-level networking work.

### Estimated Implementation Effort

| Phase | Effort |
|-------|--------|
| Transport layer (discovery + connection) | 1-2 weeks |
| Sync engine (delta sync + conflict resolution) | 1-2 weeks |
| Pairing UX (verification, device management) | 1 week |
| Security (encryption, key exchange) | 1 week |
| Testing & edge cases | 1-2 weeks |
| **Total** | **5-8 weeks** |

---

## 2. Current State Analysis

### What Already Exists ✅

EveryPay has **excellent sync foundations** already in place:

```
Database Tables:
├── sync_state          — tracks per-device sync timestamps
├── paired_devices      — stores device metadata + public keys
├── expenses           — has device_id, is_deleted, updated_at
├── categories         — has device_id, is_deleted, updated_at
└── payment_methods    — has is_deleted, updated_at
```

**Key infrastructure:**
- `ConflictResolver` service with edit-beats-delete, LWW, device_id tiebreaker
- `PairedDevice` domain entity with `publicKey` field
- `DevicesScreen` UI placeholder
- Soft-delete pattern (`is_deleted` flag) on all entities
- `device_id` field on all records for origin tracking

### What's Missing ❌

- **Transport layer**: No actual P2P networking implementation
- **Concrete SyncService**: Interface exists but no implementation
- **PairedDevicesRepository**: No CRUD for paired_devices table
- **Delta sync engine**: No logic to identify/serialize changes since last sync
- **Pairing flow**: No device verification or key exchange

---

## 3. P2P Transport Options

### Option A: Google Nearby Connections API (Recommended ⭐)

**How it works:** Google's SDK that automatically negotiates the best transport — starts with BLE for discovery, upgrades to Wi-Fi Direct or Wi-Fi hotspot for data transfer. Handles all the low-level radio management.

**Flutter Packages:**

| Package | Stars/Likes | Downloads | Platform | Maintained | Notes |
|---------|-------------|-----------|----------|------------|-------|
| `nearby_service` 0.2.1 | 112 likes | 606/month | Android + iOS | ✅ Active | Best overall. Clean API, supports text + files |
| `flutter_nearby_connections` 1.1.2 | 281 likes | 443/month | Android + iOS | ⚠️ Stale | Most popular but not updated recently |
| `flutter_nearby_connections_plus` 1.2.2 | 1 like | 114/month | Android + iOS | ✅ Fork | Maintained fork with bug fixes |

**Pros:**
- Handles discovery + connection automatically
- Encrypted by default (TLS-like)
- Works without Wi-Fi network or internet
- Supports BLE → Wi-Fi upgrade for fast transfers
- Battery-efficient discovery

**Cons:**
- Requires Google Play Services (not available on de-Googled phones)
- Android requires NEARBY_WIFI_DEVICES, BLUETOOTH, ACCESS_FINE_LOCATION permissions
- Black-box — limited control over transport behavior

**Android permissions required:**
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

### Option B: Wi-Fi Direct (`flutter_p2p_connection`)

**How it works:** Uses Android's Wi-Fi P2P APIs directly. Creates an ad-hoc Wi-Fi network between two devices.

| Package | Likes | Downloads | Notes |
|---------|-------|-----------|-------|
| `flutter_p2p_connection` 3.0.3 | 37 | 631/month | Android only, active maintenance |

**Pros:**
- No Google Play Services required
- High bandwidth (Wi-Fi speeds)
- Android-native, reliable

**Cons:**
- Android only (no iOS)
- Requires location permission on
- More complex connection flow
- No automatic BLE fallback

### Option C: Raw TCP/mDNS (Current Abstract Design)

**How it works:** Use `multicast_dns` for discovery on same LAN, then establish TCP/TLS sockets for data transfer.

**Pros:**
- Full control
- Works on any platform
- No third-party dependencies

**Cons:**
- Requires same Wi-Fi network (no offline P2P)
- Must implement discovery, handshake, encryption manually
- 2-3 months additional development
- Must handle NAT traversal, firewalls, etc.

### Option D: Mesh/BLE (`bridgefy`)

**How it works:** SDK for Bluetooth mesh networking, works fully offline.

**Pros:** Works without any Wi-Fi, mesh relay through other devices

**Cons:** Proprietary SDK (requires license), very slow for large data, SDK costs

### ⭐ Recommendation: `nearby_service` (Option A)

Best balance of ease-of-implementation, reliability, and features. Falls back gracefully across transports. If Google Play Services is a concern, add Wi-Fi Direct as secondary option.

---

## 4. Sync Strategies

### Strategy A: Delta Sync with LWW (Recommended ⭐)

**How it works:** Each device tracks when it last synced with each peer. On sync, only records modified since the last sync are exchanged.

```
Device A last synced with Device B at: 2024-03-15T10:00:00Z
Device A queries: SELECT * FROM expenses WHERE updated_at > '2024-03-15T10:00:00Z'
Device A sends those records to Device B
Device B applies them using ConflictResolver
Device B does the same for its changes → sends to Device A
```

**Leverages existing infrastructure:**
- `sync_state.last_expense_sync` / `last_category_sync` timestamps
- `ConflictResolver` with LWW + device_id tiebreaker
- `is_deleted` soft deletes
- `device_id` origin tracking

**Pros:**
- Minimal changes to existing schema
- Uses existing `ConflictResolver`
- Small payload sizes (only changed records)
- Simple to understand and debug

**Cons:**
- Clock skew between devices could cause issues
- No causality tracking (can't detect concurrent edits)
- Conflict resolution is "last write wins" — may lose data

**Mitigation for clock skew:**
```dart
// Use Hybrid Logical Clocks (HLC) instead of wall clocks
// Package: `hlc` or implement manually
class HybridLogicalClock {
  int logicalTime;
  int counter;
  String nodeId;
  
  HybridLogicalClock tick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > logicalTime) {
      logicalTime = now;
      counter = 0;
    } else {
      counter++;
    }
    return this;
  }
  
  HybridLogicalClock merge(HybridLogicalClock remote) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > logicalTime && now > remote.logicalTime) {
      logicalTime = now;
      counter = 0;
    } else if (logicalTime == remote.logicalTime) {
      counter = max(counter, remote.counter) + 1;
    } else if (remote.logicalTime > logicalTime) {
      logicalTime = remote.logicalTime;
      counter = remote.counter + 1;
    } else {
      counter++;
    }
    return this;
  }
}
```

### Strategy B: CRDT-Based Sync

**How it works:** Uses Conflict-free Replicated Data Types — data structures that can be merged without conflicts by design.

**Relevant packages:**
| Package | Downloads | Approach |
|---------|-----------|----------|
| `crdt` 5.1.3 | 1,093/month | Base CRDT types (maps, sets, counters) |
| `sql_crdt` 3.0.3 | 258/month | SQL database with CRDT layer |
| `sqlite_crdt` 3.0.4 | 254/month | sqflite + CRDT (by same author) |
| `crdt_lf` 2.5.0 | 153/month | Local-first CRDT with HLC |

**How `sqlite_crdt` works:**
```dart
// Replaces sqflite with CRDT-aware wrapper
final db = await SqfliteCrdt.open('everypay.db');

// Regular SQL queries work but CRDT metadata is tracked
await db.execute(
  'INSERT INTO expenses (id, name, amount) VALUES (?, ?, ?)',
  ['uuid', 'Netflix', 15.99],
);

// Sync: get all changes since last sync
final changeset = await db.getChangeset(
  modifiedSince: lastSyncHlc,
);

// Apply remote changes
await db.merge(remoteChangeset);
```

**Pros:**
- Mathematically proven conflict-free
- Handles concurrent edits gracefully
- Causal ordering via HLC
- Well-tested library ecosystem

**Cons:**
- **Requires replacing sqflite with sqlite_crdt** — significant migration
- All existing repository code needs updates
- Storage overhead (HLC timestamps per record per node)
- Small ecosystem (254 downloads/month)
- Learning curve for the team

### Strategy C: Full Database Export/Import

**How it works:** One device exports the entire database, the other imports it as a replacement.

**Pros:** Dead simple, no conflict resolution needed

**Cons:** 
- One device's data always wins
- Not viable for bidirectional sync
- Large payloads

### ⭐ Recommendation: Delta Sync with LWW (Strategy A)

The existing schema and `ConflictResolver` are purpose-built for this approach. Adding HLC would improve clock skew handling. CRDT migration (Strategy B) could be a future enhancement if concurrent editing becomes a requirement.

---

## 5. Data Format for Sync

### Recommended: JSON with Compression

```dart
// Sync payload structure
class SyncPayload {
  final String deviceId;
  final String syncTimestamp; // HLC or ISO timestamp
  final int schemaVersion;
  final List<SyncRecord> expenses;
  final List<SyncRecord> categories;
  final List<SyncRecord> paymentMethods;
}

class SyncRecord {
  final String id;
  final Map<String, dynamic> data;
  final String updatedAt;
  final String deviceId;
  final bool isDeleted;
}
```

**Serialization:**
```dart
import 'dart:convert';
import 'dart:io';

// Serialize
final json = jsonEncode(payload.toJson());
final compressed = gzip.encode(utf8.encode(json));

// Deserialize
final decompressed = utf8.decode(gzip.decode(compressed));
final payload = SyncPayload.fromJson(jsonDecode(decompressed));
```

**Size estimates for EveryPay:**
| Data | Records | JSON size | Gzipped |
|------|---------|-----------|---------|
| 100 expenses | 100 | ~50 KB | ~5 KB |
| 20 categories | 20 | ~4 KB | ~500 B |
| 10 payment methods | 10 | ~3 KB | ~400 B |
| **Typical delta** | **5-10 records** | **~3 KB** | **~400 B** |

Nearby Connections can transfer megabytes in seconds, so payload size is not a concern.

### Alternative: Protocol Buffers

Overkill for this use case. JSON with gzip is sufficient for personal expense data.

---

## 6. Conflict Resolution

### Current `ConflictResolver` Analysis

The existing implementation is well-designed for LWW sync:

```dart
// Existing rules (in order of priority):
// 1. Edit beats delete — non-deleted record wins over deleted
// 2. Last-write-wins — newer updatedAt wins
// 3. Device ID tiebreaker — deterministic when timestamps match
```

### Recommended Enhancements

#### 6.1 Add Conflict Logging

```dart
class SyncConflict {
  final String entityType; // 'expense', 'category', etc.
  final String entityId;
  final String winnerDeviceId;
  final String loserDeviceId;
  final DateTime resolvedAt;
  final String resolution; // 'lww', 'edit_beats_delete', 'device_tiebreak'
}

// New table
CREATE TABLE sync_conflicts (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  winner_device_id TEXT NOT NULL,
  loser_device_id TEXT NOT NULL,
  winner_data TEXT, -- JSON snapshot of winning record
  loser_data TEXT,  -- JSON snapshot of losing record
  resolution TEXT NOT NULL,
  resolved_at TEXT NOT NULL
);
```

This enables:
- User can review what changed during sync
- Undo support for undesirable conflict resolutions
- Debugging sync issues

#### 6.2 Financial Data-Specific Rules

For expense tracking, consider:

| Scenario | Resolution |
|----------|-----------|
| Same expense edited on both devices | LWW (existing) |
| Expense deleted on A, edited on B | Edit wins (existing) |
| New expense created on both devices | Both kept (different UUIDs) |
| Category renamed on both devices | LWW (existing) |
| Amount changed on both devices | LWW — but **log the conflict** for user review |

**Important:** For financial data, amount conflicts should be flagged to the user:

```dart
if (local.amount != remote.amount) {
  // Flag for user review even though LWW resolves it
  await logConflict(
    type: ConflictType.amountMismatch,
    local: local,
    remote: remote,
  );
}
```

---

## 7. Security During P2P Transfer

### 7.1 Transport Encryption

**Nearby Connections API:** Encrypted by default (TLS-equivalent). No additional work needed.

**If using raw TCP:** Must add TLS layer:
```dart
// Use dart:io SecureSocket
final socket = await SecureSocket.connect(
  host,
  port,
  context: SecurityContext()
    ..useCertificateChain(certPath)
    ..usePrivateKey(keyPath),
);
```

### 7.2 Device Pairing & Verification

The `paired_devices` table already has a `public_key` field. Recommended flow:

```
Device A                              Device B
   │                                      │
   ├──── Discover via Nearby API ─────────┤
   │                                      │
   ├──── Send pairing request ────────────┤
   │     (device_name, public_key)        │
   │                                      │
   │     Show 6-digit verification code   │
   │     on BOTH screens                  │
   │                                      │
   ├──── User confirms match ─────────────┤
   │                                      │
   ├──── Exchange public keys ────────────┤
   │     (now stored in paired_devices)   │
   │                                      │
   ├──── All future syncs signed ─────────┤
   │     with paired device's key         │
   └──────────────────────────────────────┘
```

**Verification code generation:**
```dart
import 'dart:math';
import 'package:crypto/crypto.dart';

String generateVerificationCode(String publicKeyA, String publicKeyB) {
  final combined = '$publicKeyA:$publicKeyB';
  final hash = sha256.convert(utf8.encode(combined));
  // Take first 6 digits from hash
  final code = hash.bytes
      .take(3)
      .map((b) => b % 10)
      .join()
      .padLeft(6, '0');
  return code;
}
```

### 7.3 Preventing Unauthorized Sync

1. **Paired devices only**: Only sync with devices in `paired_devices` table
2. **Signature verification**: Sign sync payloads with device private key
3. **Replay prevention**: Include monotonic sync counter in each payload
4. **Rate limiting**: Max 1 sync per minute per device pair

---

## 8. Architecture Design

### 8.1 Layer Architecture

```
┌─────────────────────────────────────────────┐
│                    UI Layer                  │
│  DevicesScreen │ SyncStatusWidget │ Dialogs  │
├─────────────────────────────────────────────┤
│               Provider Layer                 │
│  syncProvider │ pairedDevicesProvider │       │
│  discoveryProvider │ syncStatusProvider       │
├─────────────────────────────────────────────┤
│               Service Layer                  │
│  SyncEngine │ DiscoveryService │             │
│  PairingService │ ConflictResolver           │
├─────────────────────────────────────────────┤
│              Repository Layer                │
│  PairedDevicesRepository │ SyncStateRepo │   │
│  ExpenseRepository │ CategoryRepository      │
├─────────────────────────────────────────────┤
│              Transport Layer                 │
│  NearbyConnectionsTransport │               │
│  (abstractions for testability)              │
├─────────────────────────────────────────────┤
│              Database Layer                  │
│  sqflite (existing) + sync tables           │
└─────────────────────────────────────────────┘
```

### 8.2 New Files to Create

```
lib/
├── features/sync/
│   ├── providers/
│   │   ├── sync_provider.dart          # Main sync orchestration
│   │   ├── discovery_provider.dart     # Device discovery state
│   │   ├── paired_devices_provider.dart # Paired devices list
│   │   └── sync_status_provider.dart   # Current sync progress
│   ├── screens/
│   │   ├── devices_screen.dart         # UPDATE existing
│   │   ├── pairing_screen.dart         # New: verification flow
│   │   └── sync_history_screen.dart    # New: conflict log
│   ├── widgets/
│   │   ├── device_card.dart            # Paired device display
│   │   ├── sync_progress_indicator.dart
│   │   ├── verification_code_dialog.dart
│   │   └── conflict_review_card.dart
│   └── services/
│       ├── sync_engine.dart            # Core sync orchestration
│       ├── delta_calculator.dart       # Compute changesets
│       └── payload_serializer.dart     # JSON + gzip
├── data/
│   ├── repositories/
│   │   ├── paired_devices_repository.dart  # New
│   │   └── sync_state_repository.dart      # New
│   └── transport/
│       ├── p2p_transport.dart          # Abstract interface
│       ├── nearby_transport.dart       # nearby_service impl
│       └── mock_transport.dart         # For testing
├── domain/
│   ├── entities/
│   │   ├── sync_payload.dart           # New
│   │   └── sync_conflict.dart          # New
│   └── repositories/
│       ├── paired_devices_repository.dart  # Interface
│       └── sync_state_repository.dart      # Interface
└── services/
    └── device_identity_service.dart    # Device ID + key management
```

### 8.3 Riverpod Provider Design

```dart
// Discovery state
@riverpod
class DiscoveryNotifier extends _$DiscoveryNotifier {
  @override
  DiscoveryState build() => DiscoveryState.idle();

  Future<void> startDiscovery() async { ... }
  Future<void> stopDiscovery() async { ... }
}

// Paired devices (from DB)
@riverpod
Stream<List<PairedDevice>> pairedDevices(ref) {
  return ref.watch(pairedDevicesRepositoryProvider).watchAll();
}

// Sync status
@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  SyncStatus build() => SyncStatus.idle();

  Future<void> syncWithDevice(PairedDevice device) async {
    state = SyncStatus.connecting(device);
    // 1. Connect via transport
    // 2. Exchange sync timestamps
    // 3. Compute deltas
    // 4. Send/receive payloads
    // 5. Apply with ConflictResolver
    // 6. Update sync_state
    state = SyncStatus.complete(stats);
  }
}

// Sync status model
sealed class SyncStatus {
  const SyncStatus();
  factory SyncStatus.idle() = SyncIdle;
  factory SyncStatus.connecting(PairedDevice device) = SyncConnecting;
  factory SyncStatus.syncing(double progress, String phase) = SyncInProgress;
  factory SyncStatus.complete(SyncStats stats) = SyncComplete;
  factory SyncStatus.error(String message) = SyncError;
}
```

### 8.4 Sync Engine Flow

```dart
class SyncEngine {
  final P2PTransport transport;
  final ExpenseRepository expenseRepo;
  final CategoryRepository categoryRepo;
  final PaymentMethodRepository paymentMethodRepo;
  final SyncStateRepository syncStateRepo;
  final ConflictResolver conflictResolver;
  final PayloadSerializer serializer;

  Future<SyncStats> syncWithDevice(PairedDevice device) async {
    // 1. Get last sync time for this device
    final lastSync = await syncStateRepo.getLastSync(device.deviceId);

    // 2. Compute local changes since last sync
    final localChanges = SyncPayload(
      deviceId: currentDeviceId,
      syncTimestamp: DateTime.now().toIso8601String(),
      expenses: await expenseRepo.getChangedSince(lastSync.lastExpenseSync),
      categories: await categoryRepo.getChangedSince(lastSync.lastCategorySync),
      paymentMethods: await paymentMethodRepo.getChangedSince(lastSync.lastSync),
    );

    // 3. Send local changes, receive remote changes
    final localBytes = serializer.serialize(localChanges);
    final remoteBytes = await transport.exchange(device, localBytes);
    final remoteChanges = serializer.deserialize(remoteBytes);

    // 4. Apply remote changes with conflict resolution
    var conflicts = 0;
    for (final remoteExpense in remoteChanges.expenses) {
      final local = await expenseRepo.getById(remoteExpense.id);
      if (local != null) {
        final resolved = conflictResolver.resolve(local, remoteExpense);
        if (resolved != local) {
          await expenseRepo.update(resolved);
          conflicts++;
        }
      } else {
        await expenseRepo.insert(remoteExpense);
      }
    }
    // ... repeat for categories, payment methods

    // 5. Update sync state
    await syncStateRepo.updateLastSync(
      device.deviceId,
      remoteChanges.syncTimestamp,
    );

    return SyncStats(
      sent: localChanges.totalRecords,
      received: remoteChanges.totalRecords,
      conflicts: conflicts,
    );
  }
}
```

### 8.5 Transport Abstraction

```dart
/// Abstract P2P transport — enables testing and swapping implementations
abstract class P2PTransport {
  /// Discover nearby devices
  Stream<DiscoveredDevice> discover();
  
  /// Stop discovery
  Future<void> stopDiscovery();
  
  /// Connect to a discovered device
  Future<P2PConnection> connect(DiscoveredDevice device);
  
  /// Accept incoming connections
  Stream<P2PConnection> acceptConnections();
  
  /// Disconnect
  Future<void> disconnect(P2PConnection connection);
}

abstract class P2PConnection {
  String get remoteDeviceId;
  
  /// Exchange data: send local payload, receive remote payload
  Future<Uint8List> exchange(Uint8List localPayload);
  
  /// Send raw bytes
  Future<void> send(Uint8List data);
  
  /// Receive raw bytes
  Stream<Uint8List> receive();
}
```

---

## 9. Package Comparison Matrix

### Transport Packages

| Criteria | `nearby_service` | `flutter_nearby_connections` | `flutter_p2p_connection` | Raw TCP/mDNS |
|----------|-----------------|---------------------------|------------------------|--------------|
| **Platform** | Android + iOS | Android + iOS | Android only | Any |
| **Discovery** | Automatic | Automatic | Wi-Fi Direct | Manual (mDNS) |
| **Encryption** | Built-in | Built-in | None (must add) | Must add TLS |
| **Offline P2P** | ✅ | ✅ | ✅ | ❌ (needs LAN) |
| **Google Play** | Required | Required | Not required | Not required |
| **Maintenance** | ✅ Active | ⚠️ Stale | ✅ Active | N/A |
| **Likes** | 112 | 281 | 37 | N/A |
| **Downloads** | 606/month | 443/month | 631/month | N/A |
| **File transfer** | ✅ | ✅ | ✅ | Must build |
| **Effort** | Low | Low | Medium | Very High |

### Sync Strategy Packages

| Criteria | Delta + LWW (Custom) | `sqlite_crdt` | `crdt_lf` | Full export |
|----------|----------------------|---------------|-----------|-------------|
| **Migration effort** | Minimal | High (rewrite DB) | High | None |
| **Conflict resolution** | LWW + tiebreaker | Automatic CRDT | Automatic CRDT | Winner-take-all |
| **Concurrent edits** | Last write wins | Both preserved | Both preserved | One lost |
| **Existing code reuse** | ✅ High | ❌ Low | ❌ Low | ✅ High |
| **Storage overhead** | Minimal | High (HLC/node) | High | None |
| **Complexity** | Low-Medium | Medium-High | Medium-High | Very Low |
| **Package maturity** | N/A (custom) | 254/month | 153/month | N/A |

---

## 10. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)

**Goal:** Transport layer + pairing flow

1. Add `nearby_service` dependency
2. Implement `NearbyTransport` (implements `P2PTransport`)
3. Implement `PairedDevicesRepository` 
4. Implement `SyncStateRepository`
5. Build pairing screen with verification code
6. Add required Android permissions to manifest

### Phase 2: Sync Engine (Week 3-4)

**Goal:** Bidirectional delta sync

1. Implement `DeltaCalculator` — query changes since last sync
2. Implement `PayloadSerializer` — JSON + gzip
3. Implement `SyncEngine` — orchestrates full sync flow
4. Wire up `ConflictResolver` for incoming records
5. Add `sync_conflicts` table for conflict logging

### Phase 3: UX Polish (Week 5)

**Goal:** User-facing sync experience

1. Update `DevicesScreen` with real device list
2. Add sync progress indicator
3. Add sync history / conflict review screen
4. Add notification for incoming sync requests
5. Settings: auto-sync toggle, sync frequency

### Phase 4: Security Hardening (Week 6)

**Goal:** Secure the sync pipeline

1. Generate device keypair on first launch
2. Implement signed payloads
3. Add replay attack prevention
4. Integrate with DB encryption (see RESEARCH_DB_ENCRYPTION.md)

### Phase 5: Testing & Edge Cases (Week 7-8)

**Goal:** Reliable sync under all conditions

1. Unit tests for SyncEngine, DeltaCalculator, ConflictResolver
2. Integration tests with MockTransport
3. Physical device testing (2+ devices)
4. Edge cases: mid-sync disconnect, large datasets, clock skew

---

## 11. Practical Considerations

### 11.1 Battery & Bandwidth

| Operation | Impact |
|-----------|--------|
| BLE discovery | Low (~5% battery/hour if continuous) |
| Wi-Fi Direct transfer | Medium during active sync |
| Typical sync (5-10 records) | Negligible (<1 second) |
| Full initial sync (1000 records) | ~2-3 seconds over Wi-Fi Direct |

**Recommendation:** Don't keep discovery running permanently. Discovery should be:
- Triggered manually by user ("Sync Now" button)
- Or on app foreground with a cooldown (max once per 15 minutes)

### 11.2 Handling Large Databases

For databases with >10,000 records:
1. **Chunked sync**: Send records in batches of 100
2. **Progress reporting**: Update UI with progress percentage
3. **Resumable sync**: Track which chunks were sent, resume on reconnect

For EveryPay's expected data size (<1000 records typical), this is not a concern.

### 11.3 Partial Sync & Recovery

```dart
class SyncCheckpoint {
  final String deviceId;
  final String entityType;    // 'expenses', 'categories', etc.
  final int recordsSynced;
  final int totalRecords;
  final String lastRecordId;  // Resume point
}

// If sync is interrupted, resume from checkpoint
Future<void> resumeSync(SyncCheckpoint checkpoint) async {
  final remaining = await getChangedSince(
    checkpoint.lastSyncTimestamp,
    afterId: checkpoint.lastRecordId,
  );
  // Continue from where we left off
}
```

### 11.4 Offline-First Design

EveryPay is already offline-first (all data in local sqflite). P2P sync enhances this:

1. **All operations are local first** — sync is eventual, not required
2. **Sync is additive** — never destructive to local data
3. **No internet dependency** — P2P works device-to-device
4. **Conflict resolution is deterministic** — same result regardless of sync order

### 11.5 Multi-Device Topology

```
Phone A ←──── P2P ────→ Phone B
  │                        │
  └──── P2P ──→ Tablet C ←┘

Each device pair maintains independent sync_state.
Transitive sync: A→B, B→C means A's data reaches C.
```

---

## 12. Testing Strategy

### 12.1 Unit Tests

```dart
// Test DeltaCalculator
test('computes delta since last sync', () async {
  // Given: 3 expenses, last sync was before #3 was created
  // When: compute delta
  // Then: only expense #3 is in the changeset
});

// Test ConflictResolver (already exists, extend)
test('logs amount conflicts for user review', () async {
  // Given: same expense with different amounts
  // When: resolve conflict
  // Then: winner selected by LWW AND conflict logged
});

// Test PayloadSerializer
test('round-trips payload through serialize/deserialize', () {
  // Given: a SyncPayload with mixed entities
  // When: serialize then deserialize
  // Then: data is identical
});
```

### 12.2 Integration Tests with Mock Transport

```dart
// Mock transport for testing without physical devices
class MockP2PTransport implements P2PTransport {
  final Map<String, List<Uint8List>> _inbox = {};
  
  @override
  Future<P2PConnection> connect(DiscoveredDevice device) {
    return Future.value(MockConnection(_inbox, device.id));
  }
}

test('full sync flow between two in-memory databases', () async {
  final dbA = await createTestDatabase(expenses: [expense1, expense2]);
  final dbB = await createTestDatabase(expenses: [expense1, expense3]);
  
  final transport = MockP2PTransport();
  final engineA = SyncEngine(dbA, transport);
  final engineB = SyncEngine(dbB, transport);
  
  await engineA.syncWith(deviceB);
  
  // Both databases should have expense1, expense2, expense3
  expect(await dbA.getAllExpenses(), hasLength(3));
  expect(await dbB.getAllExpenses(), hasLength(3));
});
```

### 12.3 Physical Device Testing

**Required:** At least 2 physical Android devices. Emulators do NOT support Nearby Connections or Wi-Fi Direct.

Test scenarios:
1. ✅ First-time pairing + initial sync
2. ✅ Incremental sync (few records changed)
3. ✅ Bidirectional changes (edits on both devices)
4. ✅ Delete on one, edit on other (edit-beats-delete)
5. ✅ Mid-sync disconnect + resume
6. ✅ Large sync (100+ records)
7. ✅ Sync with no changes (no-op)
8. ✅ Unpair device + re-pair

---

## Appendix A: Dependencies to Add

```yaml
# pubspec.yaml additions
dependencies:
  nearby_service: ^0.2.1     # P2P transport (Nearby Connections)
  crypto: ^3.0.3             # SHA256 for verification codes
  # flutter_secure_storage already planned for biometric + DB encryption

dev_dependencies:
  # No additional dev deps needed — mocktail can mock P2PTransport
```

## Appendix B: Android Manifest Changes

```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<!-- Required for Nearby Connections -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

## Appendix C: Related Research Documents

- [RESEARCH_BIOMETRIC_LOCK.md](./RESEARCH_BIOMETRIC_LOCK.md) — Biometric app lock implementation
- [RESEARCH_DB_ENCRYPTION.md](./RESEARCH_DB_ENCRYPTION.md) — Database encryption with SQLCipher

### Integration Points Between Features

```
Biometric Lock ──→ Unlocks app ──→ DB Encryption key released
                                        │
                                        ▼
                               Database accessible
                                        │
                                        ▼
                               P2P Sync can operate
                                        │
                                  ┌─────┴─────┐
                                  │  Encrypt   │
                                  │  payload   │
                                  │  in transit │
                                  └────────────┘
```

All three features form a security stack:
1. **Biometric** → gates app access
2. **DB encryption** → protects data at rest
3. **P2P sync encryption** → protects data in transit
