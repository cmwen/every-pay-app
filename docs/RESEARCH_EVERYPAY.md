---
title: Every-Pay — Technology Research Report
version: 1.0.0
created: 2026-02-24
owner: Researcher
status: Final
references:
  - docs/REQUIREMENTS_EVERYPAY.md
  - docs/REQUIREMENTS_DATA_MODEL.md
  - docs/REQUIREMENTS_SYNC.md
---

# Every-Pay — Technology Research Report

## 1. Executive Summary

This document evaluates and recommends the Flutter packages and technical approaches for Every-Pay's MVP through V1.0. The stack prioritises **stability**, **type-safety**, **privacy**, and **offline-first** design.

### Recommended Stack

| Concern | Package | Version | Rationale |
|---------|---------|---------|-----------|
| Database | `drift` + `drift_flutter` | ^2.x | Type-safe, reactive, code-gen, migration support |
| State management | `flutter_riverpod` + `riverpod_annotation` | ^3.x | Compile-safe, testable, async-native |
| Charts | `fl_chart` | ^0.70.x | Most flexible, actively maintained, all chart types needed |
| Routing | `go_router` | ^14.x | Declarative, deep-linking ready, Flutter team maintained |
| DI / Service locator | Built-in via Riverpod | — | No additional package needed |
| UUID generation | `uuid` | ^4.x | RFC 4122 compliant UUID v4 |
| Date/time | `intl` | ^0.19.x | Formatting, locale-aware currency/date display |
| QR code display | `qr_flutter` | ^4.x | QR generation for pairing |
| QR code scanning | `mobile_scanner` | ^6.x | Camera-based QR scanning, actively maintained |
| Encryption | `pointycastle` + `cryptography` | latest | AES-256-GCM, ECDH Curve25519 |
| mDNS discovery | `nsd` (Network Service Discovery) | ^2.x | Android mDNS/Bonjour, well maintained |
| Biometric auth | `local_auth` | ^2.x | Fingerprint / face unlock, Flutter team |
| JSON serialization | `json_annotation` + `json_serializable` | latest | Code-gen for model serialization |
| Code generation | `build_runner` | latest | Required by drift, riverpod, json_serializable |
| Testing | `mocktail` + `flutter_test` | latest | Mocking without codegen, built-in widget tests |

---

## 2. Database: Drift vs. Alternatives

### Options Evaluated

| Package | Type Safety | Reactive Streams | Migrations | Code Gen | Maturity |
|---------|-------------|-----------------|------------|----------|----------|
| **drift** | ✅ Full | ✅ Built-in | ✅ Versioned | ✅ Yes | High (5+ years) |
| sqflite | ❌ Raw SQL | ❌ Manual | ❌ Manual | ❌ No | High |
| floor | ✅ Annotations | ✅ Streams | ✅ Versioned | ✅ Yes | Medium |
| isar | ✅ Schema | ✅ Watchers | ✅ Auto | ✅ Yes | Medium (uncertain future) |
| objectbox | ✅ Schema | ✅ Streams | ✅ Auto | ✅ Yes | High (but native dep) |

### Recommendation: **drift**

**Why:**
- Type-safe Dart API — catches schema errors at compile time
- Reactive queries via `Stream<List<T>>` — perfect for Riverpod integration
- DAOs for clean separation of data access logic
- Schema migrations with version tracking — critical for sync-enabled app
- Works with standard SQLite — can integrate SQLCipher for encryption
- Excellent documentation, 989 code snippets in docs
- Code generation reduces boilerplate

**Integration with Riverpod:**
```dart
// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Expense list provider (reactive stream)
final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllExpenses();
});
```

**Encryption approach:**
- Use `drift` with `sqlite3_flutter_libs` + SQLCipher build
- OR use `sqflite_sqlcipher` as the backend (drop-in SQLCipher support)
- Key stored in Android Keystore via `flutter_secure_storage`

---

## 3. State Management: Riverpod vs. Alternatives

### Options Evaluated

| Package | Compile Safety | Testability | Async Support | Learning Curve | Maturity |
|---------|---------------|-------------|---------------|---------------|----------|
| **Riverpod 3** | ✅ Full | ✅ Excellent | ✅ Native | Medium | High |
| Provider | ⚠️ Runtime | ✅ Good | ⚠️ Manual | Low | High (legacy) |
| Bloc/Cubit | ✅ Good | ✅ Excellent | ✅ Good | High | High |
| GetX | ❌ Loose | ⚠️ Fair | ✅ Good | Low | Medium |

### Recommendation: **Riverpod 3.x with code generation**

**Why:**
- `AsyncNotifierProvider` maps perfectly to our CRUD + sync operations
- `StreamProvider` integrates naturally with drift's reactive queries
- No `BuildContext` dependency — usable in services/repositories
- `ref.watch` / `ref.read` pattern is simple and consistent
- Code generation with `@riverpod` reduces boilerplate
- Excellent testability — providers can be overridden in tests

**Provider architecture for Every-Pay:**
```
Providers (UI-facing)
  ├── expensesProvider          → StreamProvider<List<Expense>>
  ├── categoriesProvider        → StreamProvider<List<Category>>
  ├── expenseFormProvider       → NotifierProvider (form state)
  ├── statsProvider             → FutureProvider (computed stats)
  ├── syncStatusProvider        → StateProvider<SyncStatus>
  ├── settingsProvider          → NotifierProvider (preferences)
  └── filterProvider            → NotifierProvider (list filters)
```

---

## 4. Charts: fl_chart vs. Alternatives

### Options Evaluated

| Package | Pie | Bar | Line | Customisation | Pub Likes | Maintained |
|---------|-----|-----|------|--------------|-----------|-----------|
| **fl_chart** | ✅ | ✅ | ✅ | Excellent | 7.5k+ | Active |
| syncfusion_flutter_charts | ✅ | ✅ | ✅ | Excellent | 2k+ | Active (paid tier) |
| charts_flutter | ✅ | ✅ | ✅ | Good | 3k+ | Deprecated (Google) |
| graphic | ✅ | ✅ | ✅ | Good | 500+ | Active |

### Recommendation: **fl_chart**

**Why:**
- Supports all 3 chart types needed: Pie (categories), Bar (monthly), Line (trends)
- Highly customisable — animations, touch interactions, tooltips
- No license restrictions (MIT)
- 1500+ code snippets in documentation
- Active maintenance, 6k+ GitHub stars
- Touch callbacks for drill-down (tap pie slice → category detail)

**Charts needed for Every-Pay:**

| Screen | Chart Type | fl_chart Widget |
|--------|-----------|-----------------|
| Monthly summary | Donut/Pie | `PieChart` |
| Yearly overview | Bar chart (12 months) | `BarChart` |
| Spending trend | Line chart | `LineChart` |
| Category breakdown | Horizontal bar | `BarChart` (rotated) |

---

## 5. Routing: go_router

### Recommendation: **go_router**

No serious alternatives needed — `go_router` is the Flutter team's official routing solution.

**Route structure for Every-Pay:**
```dart
/                           → Home (expense list + summary)
/expense/add                → Add expense form
/expense/add/library        → Service library picker
/expense/:id                → Expense detail
/expense/:id/edit           → Edit expense
/stats                      → Statistics dashboard
/stats/monthly              → Monthly detail
/stats/yearly               → Yearly detail
/stats/upcoming             → Upcoming payments
/settings                   → Settings
/settings/categories        → Category management
/settings/devices           → Paired devices
/settings/devices/pair      → QR pairing flow
/settings/export            → Data export
/settings/security          → App lock settings
```

---

## 6. P2P Sync Technology Stack

### Network Discovery: `nsd` package

- Wraps Android's `NsdManager` (Network Service Discovery)
- Supports registering and discovering `_everypay._tcp` services
- Alternative: `multicast_dns` (Dart-native, but less reliable on Android)

### TCP Communication

- Use Dart's built-in `dart:io` `ServerSocket` / `Socket`
- No additional package needed for TCP
- Message framing: 4-byte length prefix + JSON payload

### Encryption

| Operation | Package | Algorithm |
|-----------|---------|-----------|
| Key exchange | `cryptography` | ECDH X25519 |
| Payload encryption | `pointycastle` or `cryptography` | AES-256-GCM |
| HMAC verification | `cryptography` | HMAC-SHA256 |
| Key storage | `flutter_secure_storage` | Android Keystore backend |
| QR payload | `qr_flutter` + `mobile_scanner` | Base64-encoded JSON |

### Alternative considered: `nearby_connections` (Google)
- Pros: handles discovery + transport
- Cons: Google Play dependency, less control over encryption, uses Bluetooth (not needed)
- **Rejected** — too opaque for our security requirements

---

## 7. Database Encryption

### Option A: SQLCipher via `sqflite_sqlcipher`
- Drop-in replacement for `sqflite`
- Not directly compatible with drift's `NativeDatabase`
- Requires custom drift backend adapter

### Option B: drift + encrypted SQLite (Recommended)
- Use `sqlite3_flutter_libs` compiled with SQLCipher support
- Pass encryption key to `NativeDatabase` via PRAGMA
- Key from `flutter_secure_storage` (Android Keystore-backed)

```dart
NativeDatabase.createInBackground(
  file,
  setup: (db) {
    db.execute("PRAGMA key = '$encryptionKey'");
  },
);
```

### Key Management
- `flutter_secure_storage` stores the DB encryption key
- On first launch: generate random 256-bit key, store in Keystore
- On subsequent launches: retrieve from Keystore
- If Keystore cleared: data unrecoverable (acceptable trade-off for privacy)

---

## 8. Biometric Authentication

### Package: `local_auth`

- Flutter team maintained
- Supports: fingerprint, face, iris, device credential fallback
- Simple API: `localAuth.authenticate(localizedReason: 'Unlock Every-Pay')`
- Handles Android BiometricPrompt API correctly

---

## 9. Build & Code Generation

### Code generation pipeline

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Generates:**
- `*.g.dart` — drift database classes, JSON serialization
- `*.drift.dart` — drift compiled SQL (if using .drift files)

### Recommended dev workflow
```bash
# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

---

## 10. Full `pubspec.yaml` Dependencies (Recommended)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Database
  drift: ^2.24.0
  drift_flutter: ^0.2.4
  sqlite3_flutter_libs: ^0.5.28

  # State management
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

  # Charts
  fl_chart: ^0.70.2

  # Routing
  go_router: ^14.8.0

  # Utilities
  uuid: ^4.5.1
  intl: ^0.19.0
  collection: ^1.19.1

  # QR code (V1.0 sync)
  qr_flutter: ^4.1.0
  mobile_scanner: ^6.0.0

  # Encryption & security (V1.0 sync)
  cryptography: ^2.7.0
  flutter_secure_storage: ^9.2.4
  local_auth: ^2.3.0

  # Network discovery (V1.0 sync)
  nsd: ^2.1.0

  # JSON serialization
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.14
  drift_dev: ^2.24.0
  riverpod_generator: ^3.0.0
  json_serializable: ^6.9.4
  mocktail: ^1.0.4
  custom_lint: ^0.7.5
  riverpod_lint: ^3.0.0
```

**Note:** For MVP (V0.1), only the Database, State Management, Utilities, and JSON sections are needed. Charts added in V0.5, sync/encryption in V1.0.

---

## 11. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| drift code-gen slow on large schemas | Low | Schema is small (~8 tables); watch mode helps |
| SQLCipher adds APK size (~3MB) | Low | Acceptable for privacy benefit |
| fl_chart rendering on low-end devices | Low | Limit data points; use `RepaintBoundary` |
| mDNS blocked on some corporate Wi-Fi | Medium | Provide manual IP fallback in V1.1 |
| Riverpod 3 learning curve for team | Medium | Well-documented; code-gen reduces mistakes |
| `nsd` package maintenance risk | Medium | Fallback to `multicast_dns` if needed |

---

## 12. Related Documents

- `docs/REQUIREMENTS_EVERYPAY.md` — Product requirements
- `docs/REQUIREMENTS_DATA_MODEL.md` — Data model specification
- `docs/REQUIREMENTS_SYNC.md` — Sync protocol specification
- `docs/UX_DESIGN_EVERYPAY.md` — UX design specification
- `docs/ARCHITECTURE_EVERYPAY.md` — Architecture specification
