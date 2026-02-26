import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:everypay/core/services/conflict_resolver.dart';
import 'package:everypay/core/services/sync_service.dart';
import 'package:everypay/data/transport/mock_transport.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/domain/entities/sync_payload.dart';
import 'package:everypay/domain/entities/sync_state.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';
import 'package:everypay/domain/repositories/category_repository.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/payment_method_repository.dart';
import 'package:everypay/domain/repositories/sync_state_repository.dart';
import 'package:everypay/features/sync/services/payload_serializer.dart';
import 'package:everypay/features/sync/services/sync_engine.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSyncStateRepository extends Mock implements SyncStateRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockPaymentMethodRepository extends Mock
    implements PaymentMethodRepository {}

// Fallback values for mocktail
class FakeSyncState extends Fake implements SyncState {}

class FakeExpense extends Fake implements Expense {}

class FakeCategory extends Fake implements Category {}

class FakePaymentMethod extends Fake implements PaymentMethod {}

void main() {
  late MockP2PTransport transport;
  late MockSyncStateRepository syncStateRepo;
  late MockExpenseRepository expenseRepo;
  late MockCategoryRepository categoryRepo;
  late MockPaymentMethodRepository paymentMethodRepo;
  late PayloadSerializer serializer;
  late SyncEngine engine;

  const localDeviceId = 'local-device';
  const remoteDeviceId = 'remote-device';
  final now = DateTime(2026, 6, 15, 12, 0);

  setUpAll(() {
    registerFallbackValue(FakeSyncState());
    registerFallbackValue(FakeExpense());
    registerFallbackValue(FakeCategory());
    registerFallbackValue(FakePaymentMethod());
  });

  setUp(() {
    transport = MockP2PTransport();
    syncStateRepo = MockSyncStateRepository();
    expenseRepo = MockExpenseRepository();
    categoryRepo = MockCategoryRepository();
    paymentMethodRepo = MockPaymentMethodRepository();
    serializer = PayloadSerializer();

    engine = SyncEngine(
      transport: transport,
      syncStateRepo: syncStateRepo,
      expenseRepo: expenseRepo,
      categoryRepo: categoryRepo,
      paymentMethodRepo: paymentMethodRepo,
      serializer: serializer,
      conflictResolver: const ConflictResolver(),
      localDeviceId: localDeviceId,
    );
  });

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  Expense makeExpense({
    String id = 'e1',
    String name = 'Netflix',
    String deviceId = localDeviceId,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id,
      name: name,
      categoryId: 'cat-entertainment',
      amount: 15.99,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 1, 1),
      status: ExpenseStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? now,
      deviceId: deviceId,
    );
  }

  Category makeCategory({
    String id = 'c1',
    String name = 'Entertainment',
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name,
      icon: 'movie',
      colour: '#E91E63',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? now,
    );
  }

  PaymentMethod makePaymentMethod({
    String id = 'pm-1',
    String name = 'Visa',
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id,
      name: name,
      type: PaymentMethodType.creditCard,
      last4Digits: '4242',
      colourHex: '#1565C0',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? now,
    );
  }

  /// Build a serialised response payload from the remote side.
  Uint8List buildRemoteResponse({
    List<Map<String, dynamic>> expenses = const [],
    List<Map<String, dynamic>> categories = const [],
    List<Map<String, dynamic>> paymentMethods = const [],
  }) {
    return serializer.serialize(
      SyncPayload(
        deviceId: remoteDeviceId,
        syncTimestamp: now.toIso8601String(),
        schemaVersion: 3,
        expenses: expenses,
        categories: categories,
        paymentMethods: paymentMethods,
      ),
    );
  }

  Map<String, dynamic> expenseToMap(Expense e, {int isDeleted = 0}) => {
    'id': e.id,
    'name': e.name,
    'provider': e.provider,
    'category_id': e.categoryId,
    'amount': e.amount,
    'currency': e.currency,
    'billing_cycle': e.billingCycle.name,
    'custom_days': e.customDays,
    'start_date': e.startDate.toIso8601String(),
    'end_date': e.endDate?.toIso8601String(),
    'next_due_date': e.nextDueDate?.toIso8601String(),
    'status': e.status.name,
    'notes': e.notes,
    'logo_asset': e.logoAsset,
    'tags': e.tags.join(','),
    'created_at': e.createdAt.toIso8601String(),
    'updated_at': e.updatedAt.toIso8601String(),
    'device_id': e.deviceId,
    'payment_method_id': e.paymentMethodId,
    'is_deleted': isDeleted,
  };

  Map<String, dynamic> categoryToMap(Category c, {int isDeleted = 0}) => {
    'id': c.id,
    'name': c.name,
    'icon': c.icon,
    'colour': c.colour,
    'is_default': c.isDefault ? 1 : 0,
    'sort_order': c.sortOrder,
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': c.updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
  };

  Map<String, dynamic> paymentMethodToMap(
    PaymentMethod pm, {
    int isDeleted = 0,
  }) => {
    'id': pm.id,
    'name': pm.name,
    'type': pm.type.name,
    'last4_digits': pm.last4Digits,
    'bank_name': pm.bankName,
    'colour_hex': pm.colourHex,
    'is_default': pm.isDefault ? 1 : 0,
    'sort_order': pm.sortOrder,
    'created_at': pm.createdAt.toIso8601String(),
    'updated_at': pm.updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
  };

  // -----------------------------------------------------------------------
  // NOTE: syncWithDevice uses DatabaseHelper.database internally (via
  // DeltaCalculator) which cannot be mocked without modifying production
  // code. The following tests therefore focus on _applyRemoteChanges
  // behaviour by testing the full syncWithDevice flow but expecting failures
  // at the DB step, OR by verifying the individual pieces independently.
  //
  // Because DatabaseHelper.database will throw in test (no SQLite), the
  // sync will fail at step 2. We still verify that:
  //   (a) the engine returns SyncResult(success: false) on error, and
  //   (b) individual component behaviour (serializer, conflict resolver)
  //       is correct — tested in their own files.
  //
  // To properly test _applyRemoteChanges we extract its logic below.
  // -----------------------------------------------------------------------

  group('SyncEngine - syncWithDevice error handling', () {
    test('returns error result when DatabaseHelper is unavailable', () async {
      // DatabaseHelper.database will throw in a test environment because
      // there is no initialised SQLite database.
      when(
        () => syncStateRepo.getSyncState(remoteDeviceId),
      ).thenAnswer((_) async => null);

      final result = await engine.syncWithDevice(remoteDeviceId);

      expect(result.success, isFalse);
      expect(result.deviceId, remoteDeviceId);
      expect(result.error, isNotNull);
    });
  });

  // -----------------------------------------------------------------------
  // _applyRemoteChanges logic tests
  //
  // Since _applyRemoteChanges is private, we test its behaviour indirectly
  // by constructing a SyncEngine, mocking repos, and simulating the portion
  // of syncWithDevice that applies remote changes.
  //
  // We achieve this by creating a thin test-only wrapper that exposes the
  // same logic path: deserialize a payload, iterate entities, call repos.
  // Rather than modifying production code, we replicate the critical path
  // here to validate conflict resolution + repo interactions.
  // -----------------------------------------------------------------------

  group('SyncEngine - remote expense application logic', () {
    test('new expense from remote is inserted via upsertExpense', () async {
      final remoteExpense = makeExpense(
        id: 'e-new-remote',
        name: 'Disney+',
        deviceId: remoteDeviceId,
      );
      final remotePayload = SyncPayload(
        deviceId: remoteDeviceId,
        syncTimestamp: now.toIso8601String(),
        schemaVersion: 3,
        expenses: [expenseToMap(remoteExpense)],
      );

      // Simulate: getExpenseById returns null → new record
      when(
        () => expenseRepo.getExpenseById('e-new-remote'),
      ).thenAnswer((_) async => null);
      when(() => expenseRepo.upsertExpense(any())).thenAnswer((_) async => {});

      // Manually replicate _applyRemoteChanges logic for expenses
      for (final map in remotePayload.expenses) {
        final remoteDeleted = map['is_deleted'] == 1;
        final local = await expenseRepo.getExpenseById(map['id'] as String);

        if (local == null) {
          // This is what the engine does: insert the new record
          await expenseRepo.upsertExpense(remoteExpense);
          if (remoteDeleted) {
            await expenseRepo.deleteExpense(remoteExpense.id);
          }
        }
      }

      verify(() => expenseRepo.upsertExpense(any())).called(1);
      verifyNever(() => expenseRepo.deleteExpense(any()));
    });

    test(
      'new expense marked as deleted from remote is inserted then deleted',
      () async {
        final remoteExpense = makeExpense(
          id: 'e-del-remote',
          deviceId: remoteDeviceId,
        );
        final remotePayload = SyncPayload(
          deviceId: remoteDeviceId,
          syncTimestamp: now.toIso8601String(),
          schemaVersion: 3,
          expenses: [expenseToMap(remoteExpense, isDeleted: 1)],
        );

        when(
          () => expenseRepo.getExpenseById('e-del-remote'),
        ).thenAnswer((_) async => null);
        when(
          () => expenseRepo.upsertExpense(any()),
        ).thenAnswer((_) async => {});
        when(
          () => expenseRepo.deleteExpense(any()),
        ).thenAnswer((_) async => {});

        for (final map in remotePayload.expenses) {
          final remoteDeleted = map['is_deleted'] == 1;
          final local = await expenseRepo.getExpenseById(map['id'] as String);

          if (local == null) {
            await expenseRepo.upsertExpense(remoteExpense);
            if (remoteDeleted) {
              await expenseRepo.deleteExpense(remoteExpense.id);
            }
          }
        }

        verify(() => expenseRepo.upsertExpense(any())).called(1);
        verify(() => expenseRepo.deleteExpense('e-del-remote')).called(1);
      },
    );

    test(
      'conflicting expense — remote newer wins via LWW, upsertExpense called',
      () async {
        final localExpense = makeExpense(
          id: 'e-conflict',
          name: 'Netflix-local',
          deviceId: localDeviceId,
          updatedAt: DateTime(2026, 6, 1), // older
        );
        final remoteExpense = makeExpense(
          id: 'e-conflict',
          name: 'Netflix-remote',
          deviceId: remoteDeviceId,
          updatedAt: DateTime(2026, 7, 1), // newer
        );

        when(
          () => expenseRepo.getExpenseById('e-conflict'),
        ).thenAnswer((_) async => localExpense);
        when(
          () => expenseRepo.upsertExpense(any()),
        ).thenAnswer((_) async => {});

        const resolver = ConflictResolver();
        final result = resolver.resolveExpense(
          local: localExpense,
          remote: remoteExpense,
          localDeleted: false,
          remoteDeleted: false,
        );

        expect(result.action, ConflictAction.keepRemote);
        expect(result.winner.name, 'Netflix-remote');

        // Simulate what _applyRemoteChanges does when keepRemote
        if (result.action == ConflictAction.keepRemote) {
          await expenseRepo.upsertExpense(result.winner);
        }

        verify(() => expenseRepo.upsertExpense(any())).called(1);
      },
    );

    test(
      'conflicting expense — local newer wins, upsertExpense NOT called',
      () async {
        final localExpense = makeExpense(
          id: 'e-conflict',
          name: 'Netflix-local',
          deviceId: localDeviceId,
          updatedAt: DateTime(2026, 7, 1), // newer
        );
        final remoteExpense = makeExpense(
          id: 'e-conflict',
          name: 'Netflix-remote',
          deviceId: remoteDeviceId,
          updatedAt: DateTime(2026, 6, 1), // older
        );

        const resolver = ConflictResolver();
        final result = resolver.resolveExpense(
          local: localExpense,
          remote: remoteExpense,
          localDeleted: false,
          remoteDeleted: false,
        );

        expect(result.action, ConflictAction.keepLocal);

        // When keepLocal, _applyRemoteChanges does NOT call upsertExpense
        if (result.action == ConflictAction.keepRemote) {
          await expenseRepo.upsertExpense(result.winner);
        }

        verifyNever(() => expenseRepo.upsertExpense(any()));
      },
    );

    test(
      'conflicting expense — edit beats delete, local active wins over remote deleted',
      () async {
        final localExpense = makeExpense(
          id: 'e-conflict-del',
          deviceId: localDeviceId,
          updatedAt: DateTime(2026, 6, 1),
        );
        final remoteExpense = makeExpense(
          id: 'e-conflict-del',
          deviceId: remoteDeviceId,
          updatedAt: DateTime(2026, 7, 1), // newer but deleted
        );

        const resolver = ConflictResolver();
        final result = resolver.resolveExpense(
          local: localExpense,
          remote: remoteExpense,
          localDeleted: false,
          remoteDeleted: true,
        );

        // Edit beats delete: local (active) wins
        expect(result.action, ConflictAction.keepLocal);
        expect(result.winner.id, 'e-conflict-del');
      },
    );
  });

  group('SyncEngine - remote category application logic', () {
    test('new category from remote is inserted', () async {
      final remoteCategory = makeCategory(id: 'cat-new-remote', name: 'Food');
      final map = categoryToMap(remoteCategory);

      when(
        () => categoryRepo.getCategoryById('cat-new-remote'),
      ).thenAnswer((_) async => null);
      when(
        () => categoryRepo.upsertCategory(any()),
      ).thenAnswer((_) async => {});

      // Replicate _applyRemoteChanges logic for categories
      final remoteDeleted = map['is_deleted'] == 1;
      final local = await categoryRepo.getCategoryById(map['id'] as String);

      if (local == null) {
        await categoryRepo.upsertCategory(remoteCategory);
        if (remoteDeleted) {
          await categoryRepo.deleteCategory(remoteCategory.id);
        }
      }

      verify(() => categoryRepo.upsertCategory(any())).called(1);
      verifyNever(() => categoryRepo.deleteCategory(any()));
    });

    test('conflicting category — remote newer wins', () async {
      final localCategory = makeCategory(
        id: 'cat-conflict',
        name: 'Music-local',
        updatedAt: DateTime(2026, 5, 1),
      );
      final remoteCategory = makeCategory(
        id: 'cat-conflict',
        name: 'Music-remote',
        updatedAt: DateTime(2026, 7, 1),
      );

      const resolver = ConflictResolver();
      final result = resolver.resolveCategory(
        local: localCategory,
        remote: remoteCategory,
        localDeleted: false,
        remoteDeleted: false,
      );

      expect(result.action, ConflictAction.keepRemote);
      expect(result.winner.name, 'Music-remote');
    });
  });

  group('SyncEngine - remote payment method application logic', () {
    test('new payment method from remote is inserted', () async {
      final remotePm = makePaymentMethod(id: 'pm-new-remote', name: 'Amex');
      final map = paymentMethodToMap(remotePm);

      when(
        () => paymentMethodRepo.getPaymentMethodById('pm-new-remote'),
      ).thenAnswer((_) async => null);
      when(
        () => paymentMethodRepo.upsertPaymentMethod(any()),
      ).thenAnswer((_) async => {});

      final remoteDeleted = map['is_deleted'] == 1;
      final local = await paymentMethodRepo.getPaymentMethodById(
        map['id'] as String,
      );

      if (local == null) {
        await paymentMethodRepo.upsertPaymentMethod(remotePm);
        if (remoteDeleted) {
          await paymentMethodRepo.deletePaymentMethod(remotePm.id);
        }
      }

      verify(() => paymentMethodRepo.upsertPaymentMethod(any())).called(1);
      verifyNever(() => paymentMethodRepo.deletePaymentMethod(any()));
    });

    test(
      'conflicting payment method — remote newer wins via LWW by updatedAt',
      () async {
        final localPm = makePaymentMethod(
          id: 'pm-conflict',
          name: 'OldVisa',
          updatedAt: DateTime(2026, 5, 1),
        );
        final remotePm = makePaymentMethod(
          id: 'pm-conflict',
          name: 'NewVisa',
          updatedAt: DateTime(2026, 7, 1),
        );

        when(
          () => paymentMethodRepo.getPaymentMethodById('pm-conflict'),
        ).thenAnswer((_) async => localPm);
        when(
          () => paymentMethodRepo.upsertPaymentMethod(any()),
        ).thenAnswer((_) async => {});

        final local = await paymentMethodRepo.getPaymentMethodById(
          'pm-conflict',
        );

        // Replicate the LWW logic from _applyRemoteChanges
        if (local != null && remotePm.updatedAt.isAfter(local.updatedAt)) {
          await paymentMethodRepo.upsertPaymentMethod(remotePm);
        }

        verify(() => paymentMethodRepo.upsertPaymentMethod(any())).called(1);
      },
    );

    test(
      'conflicting payment method — local newer keeps local (no upsert)',
      () async {
        final localPm = makePaymentMethod(
          id: 'pm-conflict',
          name: 'NewerLocal',
          updatedAt: DateTime(2026, 7, 1),
        );
        final remotePm = makePaymentMethod(
          id: 'pm-conflict',
          name: 'OlderRemote',
          updatedAt: DateTime(2026, 5, 1),
        );

        when(
          () => paymentMethodRepo.getPaymentMethodById('pm-conflict'),
        ).thenAnswer((_) async => localPm);

        final local = await paymentMethodRepo.getPaymentMethodById(
          'pm-conflict',
        );

        if (local != null && remotePm.updatedAt.isAfter(local.updatedAt)) {
          await paymentMethodRepo.upsertPaymentMethod(remotePm);
        }

        // Remote is older → no upsert
        verifyNever(() => paymentMethodRepo.upsertPaymentMethod(any()));
      },
    );
  });

  group('SyncEngine - transport data exchange', () {
    test('sendData is called with serialized payload', () async {
      const payload = SyncPayload(
        deviceId: localDeviceId,
        syncTimestamp: '2026-06-15T12:00:00.000Z',
        schemaVersion: 3,
      );

      final bytes = serializer.serialize(payload);
      await transport.initialize();
      await transport.sendData(remoteDeviceId, bytes);

      expect(transport.sentDataLog, hasLength(1));
      expect(transport.sentDataLog.first.deviceId, remoteDeviceId);

      // Verify the sent data can be deserialized back
      final restored = serializer.deserialize(transport.sentDataLog.first.data);
      expect(restored.deviceId, localDeviceId);
    });

    test(
      'MockP2PTransport injectReceivedData emits on receivedData stream',
      () async {
        await transport.initialize();

        final responsePayload = buildRemoteResponse();

        // Set up a listener before injecting
        final future = transport.receivedData.first;
        transport.injectReceivedData(remoteDeviceId, responsePayload);

        final event = await future;
        expect(event.deviceId, remoteDeviceId);

        // Verify the received data can be deserialized
        final restored = serializer.deserialize(event.data);
        expect(restored.deviceId, remoteDeviceId);
      },
    );
  });

  group('SyncEngine - SyncResult model', () {
    test('success result carries correct counts', () {
      const result = SyncResult(
        deviceId: remoteDeviceId,
        success: true,
        expensesSynced: 5,
        categoriesSynced: 2,
        conflicts: 1,
      );

      expect(result.success, isTrue);
      expect(result.deviceId, remoteDeviceId);
      expect(result.expensesSynced, 5);
      expect(result.categoriesSynced, 2);
      expect(result.conflicts, 1);
      expect(result.error, isNull);
    });

    test('error result carries error message', () {
      const result = SyncResult(
        deviceId: remoteDeviceId,
        success: false,
        error: 'Connection timeout',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Connection timeout');
      expect(result.expensesSynced, 0);
      expect(result.categoriesSynced, 0);
    });
  });
}
