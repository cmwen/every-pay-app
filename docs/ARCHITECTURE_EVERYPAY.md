---
title: Every-Pay — Architecture Specification
version: 1.0.0
created: 2026-02-24
owner: Architect
status: Final
references:
  - docs/REQUIREMENTS_EVERYPAY.md
  - docs/REQUIREMENTS_DATA_MODEL.md
  - docs/REQUIREMENTS_SYNC.md
  - docs/RESEARCH_EVERYPAY.md
  - docs/UX_DESIGN_EVERYPAY.md
---

# Every-Pay — Architecture Specification

## 1. Architecture Overview

Every-Pay follows a **layered clean architecture** with clear separation of concerns. The codebase uses **feature-first** organisation for UI and shared layers for data/domain logic.

```
┌─────────────────────────────────────────────────────┐
│                    Presentation                      │
│  Screens → Widgets → Providers (Riverpod)           │
├─────────────────────────────────────────────────────┤
│                    Application                       │
│  Use Cases / Notifiers (business logic)             │
├─────────────────────────────────────────────────────┤
│                      Domain                          │
│  Entities, Repository Interfaces, Value Objects      │
├─────────────────────────────────────────────────────┤
│                    Infrastructure                    │
│  Drift DB, DAOs, Sync Engine, Encryption Service     │
└─────────────────────────────────────────────────────┘
```

### Dependency Rule
Each layer depends only on the layer below it. The Domain layer has **zero** Flutter/package dependencies — pure Dart only.

---

## 2. Folder Structure

```
lib/
├── main.dart                          # App entry, ProviderScope, MaterialApp
├── app.dart                           # MaterialApp.router configuration
├── router.dart                        # GoRouter route definitions
│
├── core/                              # Shared utilities & constants
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide constants
│   │   └── category_defaults.dart     # Default category seed data
│   ├── extensions/
│   │   ├── date_extensions.dart       # DateTime helpers
│   │   └── currency_extensions.dart   # Currency formatting
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData definitions
│   │   └── app_colors.dart            # Color constants
│   └── utils/
│       ├── billing_calculator.dart    # Cycle multipliers, next due date
│       └── id_generator.dart          # UUID wrapper
│
├── domain/                            # Pure Dart domain layer
│   ├── entities/
│   │   ├── expense.dart               # Expense entity (immutable)
│   │   ├── category.dart              # Category entity
│   │   ├── tag.dart                   # Tag entity
│   │   └── service_template.dart      # Service template (read-only)
│   ├── enums/
│   │   ├── billing_cycle.dart         # BillingCycle enum
│   │   ├── expense_status.dart        # ExpenseStatus enum
│   │   └── sync_status.dart           # SyncStatus enum
│   └── repositories/
│       ├── expense_repository.dart    # Abstract expense repo interface
│       ├── category_repository.dart   # Abstract category repo interface
│       └── preferences_repository.dart # Abstract prefs repo interface
│
├── data/                              # Infrastructure / data layer
│   ├── database/
│   │   ├── app_database.dart          # Drift database class (@DriftDatabase)
│   │   ├── app_database.g.dart        # Generated code
│   │   ├── tables/
│   │   │   ├── expenses_table.dart    # Drift table definition
│   │   │   ├── categories_table.dart
│   │   │   ├── tags_table.dart
│   │   │   ├── expense_tags_table.dart
│   │   │   └── preferences_table.dart
│   │   └── daos/
│   │       ├── expense_dao.dart       # Expense CRUD + queries
│   │       ├── category_dao.dart      # Category CRUD + queries
│   │       ├── tag_dao.dart           # Tag CRUD + queries
│   │       └── preferences_dao.dart   # Key-value preferences
│   ├── repositories/
│   │   ├── expense_repository_impl.dart    # Implements domain interface
│   │   ├── category_repository_impl.dart
│   │   └── preferences_repository_impl.dart
│   ├── mappers/
│   │   ├── expense_mapper.dart        # DB row ↔ domain entity
│   │   └── category_mapper.dart
│   └── templates/
│       └── service_templates.dart     # Hardcoded service library data
│
├── features/                          # Feature-first UI modules
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart       # Main expense list
│   │   ├── widgets/
│   │   │   ├── summary_card.dart      # Monthly total card
│   │   │   ├── expense_list_item.dart # Single expense row
│   │   │   ├── expense_list.dart      # Expense ListView
│   │   │   ├── filter_chips.dart      # Category filter bar
│   │   │   └── empty_state.dart       # No expenses view
│   │   └── providers/
│   │       ├── expense_list_provider.dart  # Filtered/sorted expense list
│   │       └── home_summary_provider.dart  # Monthly total, count
│   │
│   ├── expense/
│   │   ├── screens/
│   │   │   ├── add_expense_screen.dart
│   │   │   ├── edit_expense_screen.dart
│   │   │   ├── expense_detail_screen.dart
│   │   │   └── service_library_screen.dart
│   │   ├── widgets/
│   │   │   ├── expense_form.dart           # Shared form widget
│   │   │   ├── billing_cycle_picker.dart
│   │   │   ├── category_picker.dart
│   │   │   └── tag_input.dart
│   │   └── providers/
│   │       ├── expense_form_provider.dart   # Form state notifier
│   │       ├── expense_detail_provider.dart # Single expense + computed
│   │       └── service_library_provider.dart # Template list + search
│   │
│   ├── stats/
│   │   ├── screens/
│   │   │   ├── stats_screen.dart           # Tab controller
│   │   │   ├── monthly_stats_screen.dart
│   │   │   ├── yearly_stats_screen.dart
│   │   │   └── upcoming_screen.dart
│   │   ├── widgets/
│   │   │   ├── category_pie_chart.dart
│   │   │   ├── monthly_bar_chart.dart
│   │   │   ├── insights_card.dart
│   │   │   └── upcoming_list.dart
│   │   └── providers/
│   │       ├── monthly_stats_provider.dart
│   │       ├── yearly_stats_provider.dart
│   │       └── upcoming_provider.dart
│   │
│   ├── settings/
│   │   ├── screens/
│   │   │   ├── settings_screen.dart
│   │   │   ├── categories_screen.dart
│   │   │   ├── export_screen.dart
│   │   │   └── about_screen.dart
│   │   ├── widgets/
│   │   │   ├── settings_tile.dart
│   │   │   └── category_list_item.dart
│   │   └── providers/
│   │       ├── settings_provider.dart
│   │       └── categories_provider.dart
│   │
│   └── sync/                               # V1.0
│       ├── screens/
│       │   ├── devices_screen.dart
│       │   └── pair_device_screen.dart
│       ├── widgets/
│       │   ├── qr_display.dart
│       │   ├── qr_scanner.dart
│       │   └── device_list_item.dart
│       ├── providers/
│       │   ├── sync_provider.dart
│       │   └── devices_provider.dart
│       └── services/
│           ├── sync_engine.dart
│           ├── discovery_service.dart
│           ├── pairing_service.dart
│           └── encryption_service.dart
│
└── shared/                             # Shared UI components
    ├── widgets/
    │   ├── app_scaffold.dart           # Scaffold with bottom nav
    │   ├── loading_indicator.dart
    │   ├── error_view.dart
    │   ├── confirm_dialog.dart
    │   └── status_badge.dart
    └── providers/
        ├── database_provider.dart      # AppDatabase singleton
        ├── preferences_provider.dart   # Global preferences
        └── theme_provider.dart         # Theme mode
```

---

## 3. Provider Architecture (Riverpod)

### Provider Dependency Graph

```
                    ┌──────────────────┐
                    │ databaseProvider  │  (Provider<AppDatabase>)
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
    ┌─────────────┐ ┌──────────────┐ ┌──────────────┐
    │ expenseDao  │ │ categoryDao  │ │  prefDao     │
    │  Provider   │ │   Provider   │ │  Provider    │
    └──────┬──────┘ └──────┬───────┘ └──────┬───────┘
           │               │                │
    ┌──────▼──────┐ ┌──────▼───────┐ ┌──────▼───────┐
    │ expenseRepo │ │ categoryRepo │ │  prefRepo    │
    │  Provider   │ │   Provider   │ │  Provider    │
    └──────┬──────┘ └──────┬───────┘ └──────┬───────┘
           │               │                │
    ┌──────▼──────────────────────────────────────────┐
    │              Presentation Providers              │
    │                                                  │
    │  expenseListProvider    (StreamProvider)          │
    │  homeSummaryProvider    (FutureProvider)          │
    │  monthlyStatsProvider   (FutureProvider)          │
    │  yearlyStatsProvider    (FutureProvider)          │
    │  upcomingProvider       (FutureProvider)          │
    │  categoriesProvider     (StreamProvider)          │
    │  filterProvider         (NotifierProvider)        │
    │  settingsProvider       (NotifierProvider)        │
    │  expenseFormProvider    (NotifierProvider)        │
    │  serviceLibraryProvider (Provider)               │
    └──────────────────────────────────────────────────┘
```

### Key Provider Definitions

```dart
// --- Infrastructure ---

// Database singleton
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

// DAOs
@riverpod
ExpenseDao expenseDao(Ref ref) => ref.watch(databaseProvider).expenseDao;

// Repositories
@riverpod
ExpenseRepository expenseRepository(Ref ref) {
  return ExpenseRepositoryImpl(ref.watch(expenseDaoProvider));
}

// --- Presentation ---

// Reactive expense list (filtered)
@riverpod
Stream<List<Expense>> expenseList(Ref ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(filterProvider);
  return repo.watchExpenses(
    categoryId: filter.categoryId,
    status: filter.status,
    sortBy: filter.sortBy,
  );
}

// Monthly summary (computed)
@riverpod
Future<MonthlySummary> homeSummary(Ref ref) async {
  final expenses = await ref.watch(expenseListProvider.future);
  return MonthlySummary.compute(expenses, DateTime.now());
}

// Form state (mutable)
@riverpod
class ExpenseForm extends _$ExpenseForm {
  @override
  ExpenseFormState build() => ExpenseFormState.empty();

  void updateName(String name) => state = state.copyWith(name: name);
  void updateAmount(double amount) => state = state.copyWith(amount: amount);
  // ...

  Future<void> save() async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.upsertExpense(state.toExpense());
  }
}
```

---

## 4. Data Layer Architecture

### Drift Database

```dart
// lib/data/database/app_database.dart

@DriftDatabase(
  tables: [
    ExpensesTable,
    CategoriesTable,
    TagsTable,
    ExpenseTagsTable,
    PreferencesTable,
    // V1.0:
    PairedDevicesTable,
    SyncStateTable,
    SyncConflictLogTable,
  ],
  daos: [
    ExpenseDao,
    CategoryDao,
    TagDao,
    PreferencesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations here
    },
  );

  Future<void> _seedDefaultCategories() async {
    await into(categoriesTable).insertAll(defaultCategories);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'everypay.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

### DAO Example

```dart
// lib/data/database/daos/expense_dao.dart

@DriftAccessor(tables: [ExpensesTable, CategoriesTable, ExpenseTagsTable, TagsTable])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(AppDatabase db) : super(db);

  // Watch all active expenses, sorted by next due date
  Stream<List<ExpenseWithCategory>> watchAllExpenses({
    String? categoryId,
    String status = 'active',
  }) {
    final query = select(expensesTable).join([
      innerJoin(categoriesTable, categoriesTable.id.equalsExp(expensesTable.categoryId)),
    ]);

    query.where(expensesTable.isDeleted.equals(false));
    if (status != 'all') {
      query.where(expensesTable.status.equals(status));
    }
    if (categoryId != null) {
      query.where(expensesTable.categoryId.equals(categoryId));
    }
    query.orderBy([OrderingTerm.asc(expensesTable.nextDueDate)]);

    return query.watch().map((rows) => rows.map((row) {
      return ExpenseWithCategory(
        expense: row.readTable(expensesTable),
        category: row.readTable(categoriesTable),
      );
    }).toList());
  }

  // Insert or update expense
  Future<void> upsertExpense(ExpensesTableCompanion expense) {
    return into(expensesTable).insertOnConflictUpdate(expense);
  }

  // Soft delete for sync
  Future<void> softDelete(String id) {
    return (update(expensesTable)..where((e) => e.id.equals(id)))
      .write(ExpensesTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ));
  }

  // Get changes since timestamp (for sync)
  Future<List<ExpensesTableData>> getChangesSince(DateTime since) {
    return (select(expensesTable)
      ..where((e) => e.updatedAt.isBiggerThanValue(since.toIso8601String())))
      .get();
  }
}
```

### Repository Pattern

```dart
// lib/domain/repositories/expense_repository.dart (interface)
abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses({String? categoryId, String? status});
  Future<Expense?> getExpenseById(String id);
  Future<void> upsertExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getChangesSince(DateTime since);
}

// lib/data/repositories/expense_repository_impl.dart
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseDao _dao;

  ExpenseRepositoryImpl(this._dao);

  @override
  Stream<List<Expense>> watchExpenses({String? categoryId, String? status}) {
    return _dao.watchAllExpenses(categoryId: categoryId, status: status ?? 'active')
      .map((rows) => rows.map(ExpenseMapper.toDomain).toList());
  }

  @override
  Future<void> upsertExpense(Expense expense) {
    return _dao.upsertExpense(ExpenseMapper.toCompanion(expense));
  }

  // ...
}
```

---

## 5. Routing Architecture

```dart
// lib/router.dart

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'expense/add',
                  builder: (context, state) => const AddExpenseScreen(),
                  routes: [
                    GoRoute(
                      path: 'library',
                      builder: (context, state) => const ServiceLibraryScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'expense/:id',
                  builder: (context, state) => ExpenseDetailScreen(
                    id: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => EditExpenseScreen(
                        id: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          // Stats tab
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ]),
          // Settings tab
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'categories', builder: (_, __) => const CategoriesScreen()),
                GoRoute(path: 'devices', builder: (_, __) => const DevicesScreen()),
                GoRoute(path: 'devices/pair', builder: (_, __) => const PairDeviceScreen()),
                GoRoute(path: 'export', builder: (_, __) => const ExportScreen()),
                GoRoute(path: 'security', builder: (_, __) => const SecurityScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
```

---

## 6. Domain Entities

```dart
// lib/domain/entities/expense.dart

class Expense {
  final String id;
  final String name;
  final String? provider;
  final String categoryId;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final int? customDays;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextDueDate;
  final ExpenseStatus status;
  final String? notes;
  final String? logoAsset;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;

  const Expense({
    required this.id,
    required this.name,
    this.provider,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    this.customDays,
    required this.startDate,
    this.endDate,
    this.nextDueDate,
    required this.status,
    this.notes,
    this.logoAsset,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
  });

  // Computed properties
  double get monthlyCost => amount * billingCycle.monthlyMultiplier(customDays);
  double get yearlyCost => monthlyCost * 12;
  bool get isExpiringSoon =>
    endDate != null && endDate!.difference(DateTime.now()).inDays <= 30 && endDate!.isAfter(DateTime.now());
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get isActive => status == ExpenseStatus.active && !isExpired;
}

// lib/domain/enums/billing_cycle.dart

enum BillingCycle {
  weekly,
  fortnightly,
  monthly,
  quarterly,
  biannual,
  yearly,
  custom;

  double monthlyMultiplier([int? customDays]) {
    return switch (this) {
      BillingCycle.weekly     => 52 / 12,
      BillingCycle.fortnightly => 26 / 12,
      BillingCycle.monthly    => 1.0,
      BillingCycle.quarterly  => 1 / 3,
      BillingCycle.biannual   => 1 / 6,
      BillingCycle.yearly     => 1 / 12,
      BillingCycle.custom     => customDays != null ? 365 / (customDays * 12) : 1.0,
    };
  }

  String get displayName => switch (this) {
    BillingCycle.weekly     => 'Weekly',
    BillingCycle.fortnightly => 'Fortnightly',
    BillingCycle.monthly    => 'Monthly',
    BillingCycle.quarterly  => 'Quarterly',
    BillingCycle.biannual   => 'Bi-annual',
    BillingCycle.yearly     => 'Yearly',
    BillingCycle.custom     => 'Custom',
  };
}
```

---

## 7. Sync Architecture (V1.0)

### Component Diagram

```
┌─────────────────────────────────────────────────────┐
│                  SyncEngine                          │
│                                                      │
│  ┌────────────────┐  ┌──────────────────────────┐   │
│  │ DiscoveryService│  │    PairingService         │   │
│  │ (mDNS/NSD)     │  │ - QR generation           │   │
│  │ - register      │  │ - QR scanning             │   │
│  │ - discover      │  │ - ECDH key exchange       │   │
│  └───────┬────────┘  │ - HMAC verification        │   │
│          │           └──────────┬─────────────────┘   │
│          │                     │                      │
│  ┌───────▼─────────────────────▼─────────────────┐   │
│  │            SyncTransport                       │   │
│  │  - TCP ServerSocket (listen for peers)         │   │
│  │  - TCP Socket (connect to peers)               │   │
│  │  - TLS 1.3 handshake                           │   │
│  │  - Length-prefixed message framing             │   │
│  └───────────────────┬───────────────────────────┘   │
│                      │                               │
│  ┌───────────────────▼───────────────────────────┐   │
│  │         EncryptionService                      │   │
│  │  - AES-256-GCM encrypt/decrypt                │   │
│  │  - ECDH shared secret derivation              │   │
│  │  - Android Keystore integration               │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  ┌───────────────────────────────────────────────┐   │
│  │         ConflictResolver                       │   │
│  │  - Last-write-wins comparison                 │   │
│  │  - Device ID tiebreaker                       │   │
│  │  - Edit-beats-delete rule                     │   │
│  │  - Conflict logging                           │   │
│  └───────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Sync Lifecycle

```dart
class SyncEngine {
  final DiscoveryService _discovery;
  final PairingService _pairing;
  final SyncTransport _transport;
  final EncryptionService _encryption;
  final ConflictResolver _conflictResolver;
  final ExpenseDao _expenseDao;
  final SyncStateDao _syncStateDao;

  // Called when app comes to foreground
  Future<void> startSync() async {
    final peers = await _discovery.discoverPeers();
    for (final peer in peers) {
      if (!peer.isPaired) continue;
      await _syncWithPeer(peer);
    }
  }

  Future<void> _syncWithPeer(Peer peer) async {
    final lastSync = await _syncStateDao.getLastSyncTime(peer.deviceId);
    final localChanges = await _expenseDao.getChangesSince(lastSync);

    // Encrypt and send
    final payload = _encryption.encrypt(localChanges.toJson(), peer.sharedKey);
    final response = await _transport.sendDelta(peer, payload);

    // Decrypt and merge
    final remoteChanges = _encryption.decrypt(response, peer.sharedKey);
    for (final change in remoteChanges) {
      final resolved = _conflictResolver.resolve(
        local: await _expenseDao.getById(change.id),
        remote: change,
      );
      await _expenseDao.upsertExpense(resolved);
    }

    await _syncStateDao.updateLastSync(peer.deviceId, DateTime.now());
  }
}
```

---

## 8. Testing Strategy

### Test Pyramid

```
          ╱╲
         ╱  ╲        Integration Tests (10%)
        ╱ E2E╲       - Full app flows via flutter_test
       ╱──────╲
      ╱        ╲     Widget Tests (30%)
     ╱  Widget  ╲    - Screen rendering, form validation
    ╱────────────╲   - Provider integration
   ╱              ╲  Unit Tests (60%)
  ╱   Unit Tests   ╲ - Entities, repos, DAOs, billing calc
 ╱──────────────────╲ - Sync conflict resolver
```

### Test Organisation

```
test/
├── unit/
│   ├── domain/
│   │   ├── entities/
│   │   │   └── expense_test.dart          # Computed properties
│   │   └── enums/
│   │       └── billing_cycle_test.dart    # Multiplier accuracy
│   ├── data/
│   │   ├── daos/
│   │   │   ├── expense_dao_test.dart      # In-memory DB queries
│   │   │   └── category_dao_test.dart
│   │   ├── repositories/
│   │   │   └── expense_repository_test.dart
│   │   └── mappers/
│   │       └── expense_mapper_test.dart
│   └── core/
│       └── utils/
│           └── billing_calculator_test.dart
├── widget/
│   ├── features/
│   │   ├── home/
│   │   │   ├── home_screen_test.dart
│   │   │   └── expense_list_item_test.dart
│   │   ├── expense/
│   │   │   ├── add_expense_screen_test.dart
│   │   │   └── expense_form_test.dart
│   │   └── stats/
│   │       └── monthly_stats_test.dart
│   └── shared/
│       └── widgets/
│           └── status_badge_test.dart
└── integration/
    └── expense_crud_test.dart
```

### Testing Approach

| Layer | Tool | Strategy |
|-------|------|----------|
| Domain entities | `flutter_test` | Pure unit tests, no mocks needed |
| DAOs | `drift` in-memory DB | Real SQLite, fast, deterministic |
| Repositories | `mocktail` | Mock DAOs, test mapping/logic |
| Providers | `riverpod` test utilities | Override providers, verify state |
| Widgets | `flutter_test` | `pumpWidget`, verify renders |
| Sync | `mocktail` + in-memory | Mock network, test conflict resolution |

---

## 9. Error Handling Strategy

```dart
// Sealed class for typed errors
sealed class AppError {
  const AppError();
}

class DatabaseError extends AppError {
  final String message;
  const DatabaseError(this.message);
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(this.fieldErrors);
}

class SyncError extends AppError {
  final String peerDeviceId;
  final String message;
  const SyncError(this.peerDeviceId, this.message);
}

// Result type
typedef Result<T> = ({T? data, AppError? error});
```

---

## 10. Implementation Plan

### Phase 1: MVP Foundation (V0.1)

**Order of implementation:**

| Step | What | Files | Depends On |
|------|------|-------|-----------|
| 1 | **Project setup** — add dependencies to pubspec.yaml, configure build_runner | `pubspec.yaml` | — |
| 2 | **Domain layer** — entities, enums, repository interfaces | `lib/domain/**` | — |
| 3 | **Core utilities** — billing calculator, ID gen, theme, constants | `lib/core/**` | — |
| 4 | **Database** — Drift tables, DAOs, database class, seed categories | `lib/data/database/**` | Step 1 |
| 5 | **Repositories** — implement repo interfaces with DAOs + mappers | `lib/data/repositories/**` | Step 2, 4 |
| 6 | **Shared providers** — database, repo, preferences providers | `lib/shared/providers/**` | Step 5 |
| 7 | **Service templates** — hardcoded template data | `lib/data/templates/**` | Step 2 |
| 8 | **Router** — GoRouter setup with bottom nav shell | `lib/router.dart`, `lib/app.dart` | Step 1 |
| 9 | **Home screen** — expense list, summary card, filter chips, empty state | `lib/features/home/**` | Step 6, 8 |
| 10 | **Add/Edit expense** — form, library picker, category picker | `lib/features/expense/**` | Step 6, 7 |
| 11 | **Expense detail** — detail view with computed fields | `lib/features/expense/**` | Step 10 |
| 12 | **Settings** — currency, theme, categories management | `lib/features/settings/**` | Step 6 |
| 13 | **Tests** — unit tests for domain + data, widget tests for screens | `test/**` | Step 9–12 |

### Phase 2: Statistics (V0.5)

| Step | What |
|------|------|
| 14 | Monthly stats provider + pie chart widget |
| 15 | Yearly stats provider + bar chart widget |
| 16 | Upcoming payments provider + list widget |
| 17 | Insights card |
| 18 | Stats tab integration |
| 19 | Tests for stats providers and charts |

### Phase 3: Privacy & Sync (V1.0)

| Step | What |
|------|------|
| 20 | SQLCipher integration (encrypted DB at rest) |
| 21 | Biometric lock (local_auth) |
| 22 | mDNS discovery service |
| 23 | QR pairing flow (generate + scan) |
| 24 | ECDH key exchange + Android Keystore |
| 25 | TCP transport + message framing |
| 26 | Delta sync logic |
| 27 | Conflict resolver |
| 28 | Data export (CSV + JSON) |
| 29 | Sync UI (devices screen, pair screen, sync status) |
| 30 | End-to-end sync integration tests |

---

## 11. Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod 3 (code-gen) | Compile-safe, async-native, testable |
| Database | Drift (code-gen) | Type-safe, reactive streams, migration support |
| Architecture | Layered clean arch | Testable, sync-ready, swappable infra |
| Folder structure | Feature-first | Scales with features; shared data layer |
| IDs | UUID v4 (String) | No auto-increment conflicts across devices |
| Timestamps | ISO 8601 String in DB | Portable, sortable, timezone-safe |
| Soft deletes | `is_deleted` flag | Required for sync (propagate deletions) |
| Conflict resolution | LWW + device tiebreaker | Simple, deterministic, no user UI needed |
| Code gen | `build_runner` | Single pipeline for drift + riverpod + json |
| Router | go_router | Official, declarative, shell routes for bottom nav |

---

## 12. Related Documents

- `docs/REQUIREMENTS_EVERYPAY.md` — Product requirements
- `docs/REQUIREMENTS_DATA_MODEL.md` — Data model specification
- `docs/REQUIREMENTS_SYNC.md` — Sync protocol specification
- `docs/RESEARCH_EVERYPAY.md` — Technology research
- `docs/UX_DESIGN_EVERYPAY.md` — UX design specification
- `docs/ROADMAP_EVERYPAY.md` — Product roadmap
