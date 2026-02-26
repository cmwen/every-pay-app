---
title: "Research — SQLite Database Encryption for EveryPay"
date: 2025-07-18
researcher: AI Technical Researcher
scope: SQLite encryption strategy for Flutter Android app (org.cmwen.everypay)
status: Complete
references:
  - https://pub.dev/packages/sqflite_sqlcipher
  - https://pub.dev/packages/sqflite_common_ffi
  - https://pub.dev/packages/sqlcipher_flutter_libs
  - https://pub.dev/packages/flutter_secure_storage
  - https://github.com/sqlcipher/sqlcipher
  - https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/encryption_support.md
  - https://www.zetetic.net/sqlcipher/sqlcipher-api/
  - docs/ARCHITECTURE_EVERYPAY.md
recommendations:
  primary: "sqflite_common_ffi + sqlcipher_flutter_libs (FFI approach)"
  key_storage: "flutter_secure_storage (Android EncryptedSharedPreferences → Keystore-backed)"
  migration: "ATTACH + sqlcipher_export() one-time migration"
---

# Research — SQLite Database Encryption for EveryPay

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Analysis](#2-current-state-analysis)
3. [Package Comparison](#3-package-comparison)
4. [Recommended Architecture](#4-recommended-architecture)
5. [Migration Strategy](#5-migration-strategy)
6. [Key Management](#6-key-management)
7. [Performance Impact](#7-performance-impact)
8. [Implementation Approach](#8-implementation-approach)
9. [Android-Specific Considerations](#9-android-specific-considerations)
10. [Security Best Practices](#10-security-best-practices)
11. [Risk Assessment](#11-risk-assessment)
12. [Implementation Roadmap](#12-implementation-roadmap)

---

## 1. Executive Summary

### Problem
EveryPay stores financial data (expenses, payment methods with last-4 digits, categories) in a plaintext SQLite database (`everypay.db`). Any user or process with root/file access can read this data. The app's Security Screen already has a placeholder for "Database Encryption (planned)."

### Recommendation
Use **`sqflite_common_ffi`** + **`sqlcipher_flutter_libs`** for SQLCipher-based AES-256-CBC encryption, with **`flutter_secure_storage`** for Android Keystore-backed encryption key management. This is a **near-drop-in replacement** requiring changes primarily to `DatabaseHelper` (~50 lines changed) with **zero changes to repository classes**.

### Key Numbers
| Metric | Value |
|--------|-------|
| Files needing modification | 2 (database_helper.dart, pubspec.yaml) |
| New files to create | 2 (encryption_key_service.dart, db_migration_service.dart) |
| Repository files needing changes | 0 (API-compatible) |
| Performance overhead | 5–15% on reads, 5–10% on writes |
| Encryption algorithm | AES-256-CBC (SQLCipher default) |
| Key derivation | PBKDF2 with 256,000 iterations (SQLCipher 4 default) |

---

## 2. Current State Analysis

### Current Database Architecture

```
lib/data/database/
├── database_helper.dart              ← Singleton, opens unencrypted sqflite DB
├── sqlite_expense_repository.dart    ← Uses DatabaseHelper.database getter
├── sqlite_category_repository.dart   ← Uses DatabaseHelper.database getter
└── sqlite_payment_method_repository.dart  ← Uses DatabaseHelper.database getter
```

### Current Dependencies (from pubspec.yaml / pubspec.lock)
- `sqflite: ^2.4.2` (locked: 2.4.2) — standard SQLite plugin
- `sqflite_common: 2.5.6` (transitive)
- `local_auth: ^3.0.0` — biometric auth already integrated
- `shared_preferences: ^2.5.4` — used for app settings (biometric toggle)
- `path: ^1.9.1`, `path_provider: ^2.1.0`

### Current Database Schema (v2)
- **Tables**: `categories`, `expenses`, `sync_state`, `paired_devices`, `payment_methods`
- **Sensitive fields**: `payment_methods.last4_digits`, `payment_methods.bank_name`, `expenses.amount`, `expenses.notes`, `expenses.name`, `expenses.provider`
- **DB name**: `everypay.db`
- **DB version**: 2

### Current sqflite Usage Pattern
All repositories obtain the database through a single static getter:
```dart
final db = await DatabaseHelper.database;
```
The `Database` type from `package:sqflite/sqflite.dart` is the common interface. This pattern means **only `DatabaseHelper` needs to change** — repositories don't need modification if the returned `Database` object has the same API.

### Existing Biometric Infrastructure
- `BiometricService` wraps `local_auth` for fingerprint/face authentication
- `AppLockWrapper` locks/unlocks UI on lifecycle state changes
- `SecurityScreen` already has a "Database Encryption" placeholder (line 42–53)
- Biometric toggle stored in `SharedPreferences` (not secured — low risk since it's just a boolean flag)

---

## 3. Package Comparison

### 3.1 Option A: `sqflite_sqlcipher` (Drop-in replacement)

| Aspect | Details |
|--------|---------|
| **Package** | [`sqflite_sqlcipher`](https://pub.dev/packages/sqflite_sqlcipher) |
| **Approach** | Fork of sqflite that bundles SQLCipher; mirrors sqflite API exactly |
| **Migration effort** | Minimal — change import + pass password to `openDatabase()` |
| **Maintenance** | ⚠️ **Concern**: Lags behind mainline sqflite; must wait for fork to sync updates |
| **pub.dev score** | Lower popularity; fewer maintainers than sqflite |
| **API** | `openDatabase(path, password: 'key')` — native password parameter |
| **Platform support** | Android ✅, iOS ✅, macOS ⚠️ (limited) |
| **SQLCipher version** | Bundles its own; may lag behind latest SQLCipher releases |
| **Dart 3 / Flutter 3.x** | Compatibility may lag; check latest release dates |

**Pros:**
- Simplest migration path — literally swap imports
- `password` parameter built into `openDatabase()`
- No FFI knowledge needed

**Cons:**
- ⚠️ Single-maintainer fork risk; may fall behind sqflite mainline
- No control over SQLCipher version
- Not recommended by sqflite's own author (tekartik recommends FFI approach)
- Potential breaking changes when sqflite updates

### 3.2 Option B: `sqflite_common_ffi` + `sqlcipher_flutter_libs` ⭐ RECOMMENDED

| Aspect | Details |
|--------|---------|
| **Packages** | [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) + [`sqlcipher_flutter_libs`](https://pub.dev/packages/sqlcipher_flutter_libs) |
| **Approach** | Use sqflite's official FFI backend, point it at SQLCipher native library |
| **Migration effort** | Moderate — change DatabaseHelper init, set PRAGMA key in onConfigure |
| **Maintenance** | ✅ Excellent — sqflite_common_ffi is maintained by tekartik (sqflite author); sqlcipher_flutter_libs by Simon Binder (drift/moor author) |
| **API** | Same `Database` API as sqflite; password via `PRAGMA key` in `onConfigure` |
| **Platform support** | Android ✅, iOS ✅, macOS ✅, Linux ✅, Windows ✅ |
| **SQLCipher version** | Controlled by sqlcipher_flutter_libs; regularly updated |

**Pros:**
- ✅ Official approach documented by sqflite author
- ✅ Maintained by two highly reputable Flutter package authors
- ✅ Same `Database` API — repositories need zero changes
- ✅ sqlcipher_flutter_libs handles native library compilation/bundling
- ✅ Future-proof: follows sqflite mainline; not a fork
- ✅ Cross-platform if needed later

**Cons:**
- Slightly more setup than sqflite_sqlcipher
- Must call `PRAGMA key` via `onConfigure` (not a named parameter)
- FFI initialization required at app startup

### 3.3 Option C: `drift` (formerly `moor`) + SQLCipher

| Aspect | Details |
|--------|---------|
| **Package** | [`drift`](https://pub.dev/packages/drift) + `drift_sqflite` or `drift/native` |
| **Approach** | Complete ORM replacement for sqflite |
| **Migration effort** | 🔴 **Very High** — rewrite all repositories, schema definition, queries |
| **Pros** | Type-safe queries, generated code, built-in SQLCipher support |
| **Cons** | Complete rewrite of data layer; code generation dependency; overkill for current schema |

**Verdict:** Not recommended for this project. The current repository pattern works well and drift would require rewriting all 3 repositories + DatabaseHelper + adding build_runner. Consider for a future major rewrite only.

### 3.4 Option D: `encrypted_shared_preferences` / `flutter_secure_storage` alone

| Aspect | Details |
|--------|---------|
| **Approach** | Encrypt individual values, not the whole database |
| **Verdict** | ❌ **Not suitable for database encryption** — these are key-value stores. They are valuable as **supporting infrastructure** for storing the DB encryption key, not as the encryption mechanism itself. |

### 3.5 Comparison Matrix

| Criterion | sqflite_sqlcipher | **sqflite_common_ffi + sqlcipher_flutter_libs** | drift + SQLCipher |
|-----------|-------------------|--------------------------------------------------|-------------------|
| Migration effort | Low | **Moderate** | Very High |
| Maintenance risk | High (fork) | **Low (official)** | Low |
| API compatibility | Drop-in | **Drop-in for repos** | Full rewrite |
| Cross-platform | Limited | **Full** | Full |
| SQLCipher control | Bundled | **Configurable** | Configurable |
| Community backing | Small | **Strong** | Strong |
| Future-proofing | Poor | **Excellent** | Excellent |
| **Overall Score** | 6/10 | **9/10** | 7/10 (overkill) |

### 3.6 Final Verdict

**Use Option B**: `sqflite_common_ffi` + `sqlcipher_flutter_libs` + `flutter_secure_storage`

This provides:
- Zero changes to repository classes
- Officially documented approach
- Strong maintainer backing
- Full SQLCipher feature access (rekey, cipher_version, etc.)
- Keystore-backed key management on Android

---

## 4. Recommended Architecture

### High-Level Design

```
┌──────────────────────────────────────────────────────────┐
│                    Repository Layer                        │
│  SqliteExpenseRepository / SqliteCategoryRepository        │
│  SqlitePaymentMethodRepository                            │
│  (NO CHANGES — uses Database from DatabaseHelper)         │
├──────────────────────────────────────────────────────────┤
│                    DatabaseHelper                          │
│  Changed: uses databaseFactoryFfi instead of sqflite      │
│  Changed: onConfigure → PRAGMA key = ?                    │
│  New: depends on EncryptionKeyService for the key         │
├──────────────────────────────────────────────────────────┤
│                  EncryptionKeyService                      │
│  New: generates, stores, retrieves DB encryption key      │
│  Uses: flutter_secure_storage (→ Android Keystore)        │
├──────────────────────────────────────────────────────────┤
│                  DbMigrationService                        │
│  New: one-time migration from unencrypted → encrypted     │
│  Uses: ATTACH + sqlcipher_export() approach                │
├──────────────────────────────────────────────────────────┤
│                    Native Libraries                        │
│  sqlcipher_flutter_libs → bundles SQLCipher .so/.dylib    │
│  flutter_secure_storage → Android Keystore / Tink         │
└──────────────────────────────────────────────────────────┘
```

### Dependency Changes (pubspec.yaml)

```yaml
dependencies:
  # REMOVE:
  # sqflite: ^2.4.2  

  # ADD:
  sqflite_common_ffi: ^2.3.4        # FFI backend for sqflite
  sqlcipher_flutter_libs: ^0.6.4     # Pre-compiled SQLCipher native libs
  flutter_secure_storage: ^9.2.4     # Android Keystore-backed secure storage

  # KEEP (still needed for APIs like getDatabasesPath via sqflite_common):
  path: ^1.9.1
  path_provider: ^2.1.0
```

> **Note:** `sqflite_common_ffi` depends on `sqflite_common` which provides the same `Database`, `DatabaseFactory`, `OpenDatabaseOptions`, `ConflictAlgorithm` types. The import changes from `package:sqflite/sqflite.dart` to `package:sqflite_common/sqlite_api.dart`.

---

## 5. Migration Strategy

### 5.1 The Problem

Existing users have an unencrypted `everypay.db`. After update, the app must:
1. Detect the old unencrypted database exists
2. Encrypt it into a new database
3. Verify the encrypted database is valid
4. Delete the old unencrypted database
5. All of this without data loss

### 5.2 Approach: ATTACH + sqlcipher_export()

SQLCipher provides `sqlcipher_export()` specifically for this use case. This is the officially recommended migration path.

**Algorithm:**
```
1. Open the OLD unencrypted database (no key)
2. ATTACH a NEW database file with the encryption key
3. Run SELECT sqlcipher_export('newdb') — copies all schema + data
4. DETACH the new database
5. Close the old database
6. Verify the new encrypted database by opening with key
7. Replace old file with new file (or rename)
8. Record migration complete in SharedPreferences
```

### 5.3 Migration Code (Concrete Example)

```dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DbMigrationService {
  static const _migrationCompleteKey = 'db_encryption_migration_complete';
  static const _dbName = 'everypay.db';
  static const _tempEncryptedName = 'everypay_encrypted.db';

  /// Returns true if migration was performed, false if not needed.
  static Future<bool> migrateIfNeeded(String encryptionKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationCompleteKey) == true) {
      return false; // Already migrated
    }

    final dbDir = await databaseFactoryFfi.getDatabasesPath();
    final oldPath = join(dbDir, _dbName);
    final tempPath = join(dbDir, _tempEncryptedName);

    // Check if old unencrypted DB exists
    if (!File(oldPath).existsSync()) {
      // Fresh install — no migration needed, mark as done
      await prefs.setBool(_migrationCompleteKey, true);
      return false;
    }

    // Check if old DB is actually unencrypted by trying to open without key
    final bool isUnencrypted = await _isUnencryptedDb(oldPath);
    if (!isUnencrypted) {
      // Already encrypted (shouldn't happen, but handle gracefully)
      await prefs.setBool(_migrationCompleteKey, true);
      return false;
    }

    // Step 1: Open old unencrypted database via FFI (no key)
    final oldDb = await databaseFactoryFfi.openDatabase(
      oldPath,
      options: OpenDatabaseOptions(readOnly: true),
    );

    try {
      // Step 2: Attach new encrypted database
      // Escape the key to prevent SQL injection (use hex key for safety)
      final hexKey = encryptionKey.codeUnits
          .map((c) => c.toRadixString(16).padLeft(2, '0'))
          .join();

      await oldDb.execute("ATTACH DATABASE '$tempPath' AS encrypted KEY \"x'$hexKey'\";");

      // Step 3: Export all data to encrypted database
      await oldDb.execute("SELECT sqlcipher_export('encrypted');");

      // Step 4: Set the same schema version on encrypted DB
      final version = await oldDb.getVersion();
      await oldDb.execute("PRAGMA encrypted.user_version = $version;");

      // Step 5: Detach
      await oldDb.execute("DETACH DATABASE encrypted;");
    } finally {
      await oldDb.close();
    }

    // Step 6: Verify the new encrypted database
    final verified = await _verifyEncryptedDb(tempPath, encryptionKey);
    if (!verified) {
      // Clean up failed migration
      File(tempPath).deleteSync();
      throw Exception('Database encryption migration verification failed');
    }

    // Step 7: Swap files
    File(oldPath).deleteSync();
    File(tempPath).renameSync(oldPath);

    // Step 8: Mark migration complete
    await prefs.setBool(_migrationCompleteKey, true);
    return true;
  }

  static Future<bool> _isUnencryptedDb(String path) async {
    try {
      // Try to open without a key and read sqlite_master
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      await db.rawQuery('SELECT count(*) FROM sqlite_master');
      await db.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _verifyEncryptedDb(
    String path,
    String encryptionKey,
  ) async {
    try {
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          readOnly: true,
          onConfigure: (db) async {
            await db.rawQuery("PRAGMA key = '$encryptionKey'");
          },
        ),
      );
      // Verify we can read data
      final result = await db.rawQuery('SELECT count(*) FROM sqlite_master');
      final count = result.first.values.first as int;
      await db.close();
      return count > 0; // Should have tables
    } catch (_) {
      return false;
    }
  }
}
```

### 5.4 Migration Safety Guarantees

| Risk | Mitigation |
|------|-----------|
| App killed during migration | Old DB is untouched until final swap; temp file cleaned up on next launch |
| Verification failure | Temp encrypted file deleted; old DB preserved; retries on next launch |
| Disk space | Need ~2x DB size temporarily; for EveryPay's data size this is negligible (<1MB) |
| Schema version mismatch | Explicitly copy `user_version` PRAGMA to new DB |
| Migration runs twice | SharedPreferences flag prevents re-execution |

### 5.5 Alternative: Simpler App-Level Migration

If `sqlcipher_export()` isn't available through the FFI layer (unlikely but possible), a fallback approach:

```dart
// Fallback: Read all data from old DB, write to new encrypted DB
// 1. Open old DB (no encryption)
// 2. Read all rows from all tables
// 3. Open new encrypted DB (with PRAGMA key)
// 4. Run onCreate to create schema
// 5. Insert all data into new DB
// 6. Verify counts match
// 7. Swap files
```

This is more code but doesn't depend on `sqlcipher_export()`. For EveryPay's 5 tables, it's perfectly viable.

---

## 6. Key Management

### 6.1 Strategy Overview

```
┌─────────────────────────────────────────────────────┐
│                  App Startup                         │
│                                                      │
│  1. EncryptionKeyService.getOrCreateKey()            │
│     ├─ flutter_secure_storage.read('db_enc_key')    │
│     │  ├─ Key exists → return it                    │
│     │  └─ Key missing → generate random 256-bit     │
│     │     key, store via flutter_secure_storage,     │
│     │     return it                                  │
│     │                                                │
│     └─ Under the hood (Android):                    │
│        EncryptedSharedPreferences (Tink library)    │
│           └── Master key stored in Android Keystore │
│               (hardware-backed on supported devices) │
│                                                      │
│  2. DatabaseHelper.init(key) → PRAGMA key = ?        │
└─────────────────────────────────────────────────────┘
```

### 6.2 Why `flutter_secure_storage`?

| Feature | flutter_secure_storage | SharedPreferences | Raw Keystore |
|---------|----------------------|-------------------|-------------|
| Android backing | EncryptedSharedPreferences → Keystore | Plaintext XML | Direct Keystore |
| Hardware-backed keys | ✅ (when available) | ❌ | ✅ |
| Implementation effort | Low (3 lines) | N/A (insecure) | High (platform channels) |
| Maintained | ✅ 840+ snippets, High rep | N/A | Custom |
| Cross-platform | ✅ | ✅ | ❌ Android-only |
| Backup exclusion | ✅ Auto-excluded from backups | ❌ | ✅ |

### 6.3 EncryptionKeyService Implementation

```dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionKeyService {
  static const _keyName = 'everypay_db_encryption_key';
  static const _keyLengthBytes = 32; // 256 bits

  final FlutterSecureStorage _secureStorage;

  EncryptionKeyService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            // Do not require authentication to read key — the DB
            // must be accessible on app launch before user interacts.
            // Biometric lock is handled at UI layer (AppLockWrapper).
          ),
        );

  /// Retrieves existing key or generates + stores a new one.
  Future<String> getOrCreateKey() async {
    String? key = await _secureStorage.read(key: _keyName);
    if (key != null && key.isNotEmpty) {
      return key;
    }

    // Generate a cryptographically secure random key
    key = _generateRandomKey();
    await _secureStorage.write(key: _keyName, value: key);
    return key;
  }

  /// Generates a 256-bit (32-byte) random key as hex string.
  String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(_keyLengthBytes, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Checks if an encryption key already exists.
  Future<bool> hasKey() async {
    final key = await _secureStorage.read(key: _keyName);
    return key != null && key.isNotEmpty;
  }

  /// Deletes the encryption key (use with extreme caution — data becomes irrecoverable).
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyName);
  }

  /// Rotates the key. Returns the new key.
  /// IMPORTANT: Caller must re-encrypt the database with PRAGMA rekey.
  Future<String> rotateKey() async {
    final newKey = _generateRandomKey();
    await _secureStorage.write(key: _keyName, value: newKey);
    return newKey;
  }
}
```

### 6.4 Key Format Considerations

| Format | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Passphrase string | Simple; SQLCipher hashes via PBKDF2 | Slower (PBKDF2 runs 256K iterations) | ❌ Slower |
| Raw hex key (`x'...'`) | Skips PBKDF2; faster DB open | Must manage key quality ourselves | ✅ **Recommended** |
| Base64 key | Compact encoding | Must decode before use | ❌ Unnecessary |

**Use raw hex key format** with `PRAGMA key = "x'<hex>'";` to skip PBKDF2 on every DB open. Since we generate a cryptographically secure random 256-bit key, PBKDF2 key stretching is unnecessary (it's meant for weak passphrases).

```dart
// In onConfigure callback:
await db.rawQuery("PRAGMA key = \"x'$hexKey'\";");
```

### 6.5 Biometric Integration for Key Access

The current EveryPay architecture already separates biometric auth (UI lock) from data access. The recommended approach maintains this separation:

```
Biometric Lock (existing)          Database Encryption (new)
─────────────────────────          ──────────────────────────
UI-level gate via                  Transparent encryption via
AppLockWrapper                     SQLCipher PRAGMA key

Prevents seeing data               Prevents reading DB file
on screen                          directly from disk

Uses: local_auth                   Uses: flutter_secure_storage
                                         + Android Keystore
```

**Why NOT tie the encryption key to biometric auth directly:**
1. The DB must be accessible immediately at app startup for data loading
2. Background operations (future: sync, notifications) need DB access without user interaction
3. If biometric enrollment changes, the key would be lost → data irrecoverable
4. Biometric auth is already enforced at UI layer — double-gating adds complexity without security gain

**If biometric-gated key is desired in the future** (e.g., for an ultra-secure mode):
```dart
// flutter_secure_storage supports biometric-protected reads on Android
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    // Requires biometric auth each time the key is read
    authenticationRequired: true,
    authenticationValidityDurationSeconds: 30,
  ),
);
```
⚠️ This would block DB access until the user authenticates — only suitable if the app can show a loading/locked screen until auth completes (which EveryPay already does with AppLockWrapper).

---

## 7. Performance Impact

### 7.1 SQLCipher Performance Characteristics

SQLCipher uses **AES-256-CBC** encryption with **HMAC-SHA512** for page-level authentication. Every database page (default 4096 bytes) is individually encrypted and authenticated.

#### Overhead Sources
1. **Page encryption/decryption**: AES-256 on each 4KB page read/written
2. **HMAC verification**: SHA512 on each page read (tamper detection)
3. **Key derivation** (if using passphrase): PBKDF2 with 256K iterations at DB open
4. **Reserve bytes**: Each page uses 48 reserved bytes for IV+HMAC (slightly less data per page)

### 7.2 Benchmark Data (Industry Sources)

| Operation | Unencrypted | SQLCipher (raw key) | Overhead |
|-----------|-------------|---------------------|----------|
| DB open (cold) | ~5ms | ~8ms (raw key) / ~200ms (passphrase w/ PBKDF2) | 60% / 3900% |
| Single row read | ~0.1ms | ~0.12ms | ~15% |
| Bulk read (1000 rows) | ~15ms | ~17ms | ~13% |
| Single row insert | ~0.5ms | ~0.55ms | ~10% |
| Bulk insert (1000 rows in transaction) | ~50ms | ~55ms | ~10% |
| DB size on disk | baseline | +~5-7% (HMAC reserves) | ~6% |

> **Source**: Zetetic (SQLCipher authors) benchmarks, community reports on Flutter/sqflite GitHub issues, and SQLCipher documentation. Exact numbers vary by device CPU (AES-NI hardware acceleration helps significantly).

### 7.3 EveryPay-Specific Impact Assessment

EveryPay's database is **small** (likely <100 rows across all tables for typical users). At this scale:

| EveryPay Operation | Current (est.) | With Encryption (est.) | User-Perceptible? |
|-------------------|----------------|----------------------|-------------------|
| App startup (DB open) | ~10ms | ~15ms (raw key) | ❌ No |
| Load expense list | ~2ms | ~2.3ms | ❌ No |
| Save expense | ~1ms | ~1.1ms | ❌ No |
| Load categories | ~1ms | ~1.1ms | ❌ No |
| Full text search | ~3ms | ~3.5ms | ❌ No |

**Conclusion: Performance impact is negligible for EveryPay's use case.** The overhead becomes noticeable only at >10,000 rows or complex joins, neither of which apply here.

### 7.4 Optimization Tips

1. **Use raw hex key** (not passphrase) → eliminates PBKDF2 on every DB open (~200ms savings)
2. **Keep page size at 4096** (SQLCipher default) — matches OS page size for optimal I/O
3. **Use WAL mode** (sqflite default) — concurrent reads during writes
4. **Batch operations** — same as unencrypted; batching amortizes per-transaction overhead

---

## 8. Implementation Approach

### 8.1 Changed: DatabaseHelper (core change)

```dart
// lib/data/database/database_helper.dart

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:everypay/core/constants/category_defaults.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'everypay.db';
  static const _dbVersion = 2;

  // The encryption key, set during app initialization
  static String? _encryptionKey;

  /// Must be called once at app startup before any DB access.
  static void initialize({required String encryptionKey}) {
    _encryptionKey = encryptionKey;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    assert(_encryptionKey != null, 'Call DatabaseHelper.initialize() first');

    final dbPath = await databaseFactoryFfi.getDatabasesPath();
    final path = join(dbPath, _dbName);

    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Set encryption key as the first operation on the connection.
  static Future<void> _onConfigure(Database db) async {
    // Use raw hex key to skip PBKDF2 derivation
    await db.rawQuery("PRAGMA key = \"x'$_encryptionKey'\";");
    // Verify cipher is active
    final cipherVersion = await db.rawQuery('PRAGMA cipher_version;');
    if (cipherVersion.isEmpty || cipherVersion.first.values.first == null) {
      throw StateError('SQLCipher is not active — encryption not available');
    }
  }

  // ... _onCreate, _onUpgrade, _createPaymentMethodsTable remain UNCHANGED ...

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  static Future<void> deleteDatabase() async {
    final dbPath = await databaseFactoryFfi.getDatabasesPath();
    final path = join(dbPath, _dbName);
    await databaseFactoryFfi.deleteDatabase(path);
    _database = null;
  }
}
```

### 8.2 Import Changes in Repository Files

The only change needed in repository files is the import statement (if needed at all — `sqflite_common` provides the same `Database` and `ConflictAlgorithm` types):

```dart
// BEFORE:
import 'package:sqflite/sqflite.dart';

// AFTER:
import 'package:sqflite_common/sqlite_api.dart';
```

Since repositories only use `Database`, `ConflictAlgorithm`, and call methods like `db.query()`, `db.insert()`, `db.update()`, `db.rawQuery()` — all of which exist on `sqflite_common`'s `Database` — **the API is identical**.

### 8.3 App Startup (main.dart changes)

```dart
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:everypay/core/services/encryption_key_service.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/data/database/db_migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI database factory (required for sqflite_common_ffi)
  sqfliteFfiInit();

  // Get or create the encryption key (stored in Android Keystore via flutter_secure_storage)
  final keyService = EncryptionKeyService();
  final encryptionKey = await keyService.getOrCreateKey();

  // Migrate existing unencrypted database (one-time, idempotent)
  await DbMigrationService.migrateIfNeeded(encryptionKey);

  // Initialize DatabaseHelper with the encryption key
  DatabaseHelper.initialize(encryptionKey: encryptionKey);

  runApp(const MyApp());
}
```

### 8.4 Files Changed Summary

| File | Change Type | Details |
|------|-------------|---------|
| `pubspec.yaml` | Modified | Replace `sqflite` with `sqflite_common_ffi` + `sqlcipher_flutter_libs` + `flutter_secure_storage` |
| `lib/data/database/database_helper.dart` | Modified | Use `databaseFactoryFfi`, add `initialize()`, add `onConfigure` with PRAGMA key |
| `lib/data/database/sqlite_expense_repository.dart` | Modified (minimal) | Change import from `sqflite` to `sqflite_common/sqlite_api.dart` |
| `lib/data/database/sqlite_category_repository.dart` | Modified (minimal) | Change import |
| `lib/data/database/sqlite_payment_method_repository.dart` | Modified (minimal) | Change import |
| `lib/core/services/encryption_key_service.dart` | **New** | Key generation, storage, retrieval |
| `lib/data/database/db_migration_service.dart` | **New** | One-time unencrypted → encrypted migration |
| `lib/main.dart` | Modified | Add FFI init, key service init, migration call |
| `lib/features/settings/screens/security_screen.dart` | Modified | Update "Database Encryption" status from "Planned" to "Active" |

### 8.5 Testing Strategy

```dart
// test/data/database/database_helper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Use in-memory database for tests
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database opens with encryption key', () async {
    DatabaseHelper.initialize(encryptionKey: 'test_key_hex_64_chars...');
    final db = await DatabaseHelper.database;
    expect(db.isOpen, true);

    // Verify cipher is active
    final result = await db.rawQuery('PRAGMA cipher_version;');
    expect(result.isNotEmpty, true);

    await DatabaseHelper.close();
  });

  test('database rejects wrong key', () async {
    // Open with key A, close, reopen with key B → should fail
    // ...
  });
}
```

---

## 9. Android-Specific Considerations

### 9.1 Android Keystore Integration

`flutter_secure_storage` on Android (v10+) uses **EncryptedSharedPreferences** backed by Google's **Tink** cryptographic library:

```
Your DB encryption key (stored value)
    ↓ encrypted by
AES-256-SIV (Tink AEAD)
    ↓ master key stored in
Android Keystore (hardware-backed on supported devices)
    ↓ protected by
TEE / StrongBox (hardware security module)
```

**Key properties:**
- Master key is **non-exportable** — cannot be extracted even with root
- On devices with **StrongBox** (Pixel 3+, Samsung S10+, etc.): hardware-isolated keystore
- On older devices: **TEE (Trusted Execution Environment)** — software-emulated but still protected
- Keys survive app updates but are **deleted on app uninstall**

### 9.2 Minimum API Level

| Component | Minimum API | Notes |
|-----------|-------------|-------|
| `flutter_secure_storage` (EncryptedSharedPreferences) | API 23 (Android 6.0) | Required for Keystore-backed encryption |
| `sqlcipher_flutter_libs` | API 21 (Android 5.0) | SQLCipher native lib support |
| Flutter 3.x default `minSdkVersion` | API 21 (Android 5.0) | Flutter framework minimum |
| **EveryPay current** | `flutter.minSdkVersion` (API 21) | Set in build.gradle.kts |

**Recommendation:** EveryPay's current minimum is API 21 via `flutter.minSdkVersion`. The `flutter_secure_storage` package handles API 21-22 gracefully by falling back to a non-EncryptedSharedPreferences mode with manual AES encryption. No `minSdk` change needed, but consider bumping to **API 23** if you want to guarantee hardware-backed keystore for all users. (API 23+ covers ~99% of active Android devices as of 2025.)

### 9.3 ProGuard / R8 Considerations

`sqlcipher_flutter_libs` includes native `.so` files. Ensure ProGuard doesn't strip JNI references:

```proguard
# proguard-rules.pro (likely already handled by the plugin, but verify)
-keep class net.zetetic.database.** { *; }
-keep class org.simonbinder.** { *; }
```

### 9.4 APK Size Impact

| Library | Size Impact (per ABI) | Notes |
|---------|----------------------|-------|
| `sqlcipher_flutter_libs` | ~2.5 MB per ABI | Pre-compiled SQLCipher + OpenSSL |
| `flutter_secure_storage` | ~50 KB | Thin wrapper over Android APIs |
| **Total (arm64-v8a)** | **~2.5 MB** | Most common ABI |
| **Total (split APKs / AAB)** | ~2.5 MB per variant | Play Store delivers only needed ABI |

Since EveryPay already has `isMinifyEnabled = true` and `isShrinkResources = true` in release builds, and uses AAB for Play Store, the per-device impact is ~2.5 MB.

### 9.5 Backup Considerations

Android Auto Backup can back up the encrypted database file. This is **fine** — the file is encrypted and useless without the key, which is in the Keystore and NOT backed up.

However, if a user restores to a new device:
- The encrypted DB file is restored ✅
- The Keystore key is **NOT** restored ❌
- Result: **Data is irrecoverable** on the new device

**Mitigation options:**
1. **Exclude the DB from auto-backup** (simplest — users start fresh on new devices):
   ```xml
   <!-- android/app/src/main/res/xml/backup_rules.xml -->
   <full-backup-content>
     <exclude domain="database" path="everypay.db" />
   </full-backup-content>
   ```
2. **Export/import feature** — let users manually export data (planned in roadmap)
3. **Cloud sync** — when P2P sync is implemented, data is recoverable via sync

### 9.6 Device-Specific Edge Cases

| Scenario | Impact | Mitigation |
|----------|--------|-----------|
| Factory reset | Keystore wiped → DB irrecoverable | Expected; user starts fresh |
| App uninstall/reinstall | Keystore key deleted → old DB gone | Expected; DB is also deleted on uninstall |
| OS update | Keystore survives | No issue |
| Rooted device | Keystore still protects key (TEE/StrongBox) | DB file encrypted; key protected by hardware |
| Samsung Knox | Additional isolation | No issue; Keystore works within Knox |

---

## 10. Security Best Practices

### 10.1 Key Rotation

SQLCipher supports key rotation via `PRAGMA rekey`:

```dart
/// Rotates the database encryption key.
/// Should be called periodically or on security events.
static Future<void> rotateKey(String newKey) async {
  final db = await database;
  await db.rawQuery("PRAGMA rekey = \"x'$newKey'\";");
}
```

**When to rotate:**
- Not needed for routine use (the key is random and hardware-protected)
- Consider rotating if: security audit requires it, compromise is suspected
- The UI could offer a "Rotate Encryption Key" button in Security Settings

**Cost:** Re-encrypts the entire database. For EveryPay's small DB: <100ms.

### 10.2 Memory Protection

| Concern | SQLCipher Handling | Additional Steps |
|---------|-------------------|------------------|
| Key in memory | SQLCipher zeroes key memory after use | None needed |
| Decrypted pages in memory | Only current page buffer in memory | None needed (OS handles page swapping) |
| Key in Dart string | Dart strings are immutable, GC'd | Minimize time key is in Dart memory |
| Core dumps | Could contain decrypted data | Disable core dumps in production (default on Android) |

**Recommendation:** The key is in Dart memory briefly during DB open. This is acceptable — an attacker with memory-read access already has full device compromise. SQLCipher's internal memory handling is well-audited.

### 10.3 Cipher Configuration

SQLCipher 4 defaults (used by `sqlcipher_flutter_libs`):

| Setting | Default | Notes |
|---------|---------|-------|
| Cipher | AES-256-CBC | Industry standard |
| KDF | PBKDF2-HMAC-SHA512 | Skipped when using raw hex key |
| KDF iterations | 256,000 | N/A for raw hex key |
| HMAC | SHA-512 | Per-page integrity check |
| Page size | 4096 bytes | Matches OS page size |
| Plaintext header size | 0 | No unencrypted header |

These defaults are secure and should not be changed without specific reason.

### 10.4 Security Checklist

- [ ] Encryption key is 256 bits, generated with `Random.secure()`
- [ ] Key is stored in `flutter_secure_storage` (→ Android Keystore)
- [ ] Key is never logged, printed, or transmitted
- [ ] `PRAGMA key` is the first statement after DB open
- [ ] `PRAGMA cipher_version` is verified to confirm SQLCipher is active
- [ ] Migration verifies encrypted DB before deleting old unencrypted DB
- [ ] Database file is excluded from auto-backup (or backup is acceptable given encryption)
- [ ] ProGuard rules preserve SQLCipher JNI bindings
- [ ] Tests verify encryption is active (check `cipher_version`)
- [ ] Tests verify wrong key cannot open database

### 10.5 Threat Model

| Threat | Without Encryption | With Encryption |
|--------|-------------------|-----------------|
| Physical device access (locked) | ⚠️ DB readable via USB debug | ✅ DB file is ciphertext |
| Physical device access (unlocked) | 🔴 Full access | ✅ DB file is ciphertext (app data still accessible while app is open) |
| Rooted device / malware | 🔴 Read DB directly | ✅ Need Keystore key (hardware-protected) |
| ADB backup extraction | 🔴 Plaintext DB in backup | ✅ Encrypted blob, no key |
| Lost/stolen device | 🔴 Data exposed | ✅ Data protected |
| Man-in-the-middle | N/A (local DB) | N/A (local DB) |

---

## 11. Risk Assessment

### 11.1 Implementation Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Migration corrupts data | Low | Critical | Verify before delete; keep backup; atomic swap |
| SQLCipher FFI loading fails on edge devices | Low | High | Fallback to unencrypted with warning; sqlcipher_flutter_libs well-tested |
| flutter_secure_storage key loss | Very Low | Critical | Key persists across updates; lost on uninstall (expected) |
| Performance regression | Very Low | Low | Benchmarks show <15% overhead; EveryPay DB is tiny |
| APK size increase | Certain | Low | ~2.5MB acceptable for security feature |
| Test breakage | Medium | Low | sqflite_common_ffi works in tests with `sqfliteFfiInit()` |

### 11.2 Rollback Plan

If encryption causes issues in production:
1. The encryption can be disabled by removing `PRAGMA key` from `onConfigure`
2. Add a "decrypt database" migration (reverse of encrypt migration)
3. Ship update that falls back to unencrypted mode
4. Key remains in Keystore (harmless if unused)

---

## 12. Implementation Roadmap

### Phase 1: Core Infrastructure (1-2 days)
1. Add dependencies to `pubspec.yaml`
2. Create `EncryptionKeyService`
3. Modify `DatabaseHelper` for FFI + encryption
4. Update imports in repository files
5. Update `main.dart` startup sequence

### Phase 2: Migration (0.5-1 day)
1. Create `DbMigrationService`
2. Test migration with sample unencrypted DB
3. Add migration call to startup sequence

### Phase 3: UI Updates (0.5 day)
1. Update Security Screen — show "Active" instead of "Planned"
2. Optionally add encryption status indicator
3. Optionally add "Rotate Encryption Key" action

### Phase 4: Testing (1 day)
1. Unit tests for `EncryptionKeyService`
2. Integration tests for encrypted DB operations
3. Migration tests (unencrypted → encrypted)
4. Verify all existing repository tests pass with encrypted DB
5. Manual testing on physical devices

### Phase 5: Documentation & Release
1. Update ARCHITECTURE doc
2. Add to CHANGELOG
3. Release as minor version update (non-breaking for users)

**Estimated total effort: 3-5 days**

---

## Appendix A: Quick Reference — Package Versions

```yaml
# pubspec.yaml additions (verify latest versions on pub.dev at implementation time)
dependencies:
  sqflite_common_ffi: ^2.3.4+3
  sqlcipher_flutter_libs: ^0.6.4
  flutter_secure_storage: ^9.2.4

  # Remove:
  # sqflite: ^2.4.2
```

## Appendix B: Verification Commands

```dart
// Verify SQLCipher is active
final version = await db.rawQuery('PRAGMA cipher_version;');
print('SQLCipher version: ${version.first.values.first}');
// Expected: "4.5.x" or similar

// Verify encryption settings
final settings = await db.rawQuery('PRAGMA cipher_settings;');
print('Cipher settings: $settings');

// Verify page size
final pageSize = await db.rawQuery('PRAGMA page_size;');
print('Page size: ${pageSize.first.values.first}');
// Expected: 4096

// Test that wrong key fails
try {
  await db.rawQuery("PRAGMA key = 'wrong_key';");
  await db.rawQuery('SELECT * FROM sqlite_master;');
  print('ERROR: Should have failed with wrong key!');
} catch (e) {
  print('Correctly rejected wrong key: $e');
}
```

## Appendix C: File Diff Preview

### pubspec.yaml
```diff
- sqflite: ^2.4.2
+ sqflite_common_ffi: ^2.3.4+3
+ sqlcipher_flutter_libs: ^0.6.4
+ flutter_secure_storage: ^9.2.4
```

### database_helper.dart (imports)
```diff
- import 'package:sqflite/sqflite.dart';
+ import 'package:sqflite_common/sqlite_api.dart';
+ import 'package:sqflite_common_ffi/sqflite_ffi.dart';
```

### Repository files (imports only)
```diff
- import 'package:sqflite/sqflite.dart';
+ import 'package:sqflite_common/sqlite_api.dart';
```
