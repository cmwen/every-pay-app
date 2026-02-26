import 'dart:async';
import 'dart:typed_data';

import 'package:everypay/core/services/conflict_resolver.dart';
import 'package:everypay/core/services/sync_service.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/data/transport/p2p_transport.dart';
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
import 'package:everypay/features/sync/services/delta_calculator.dart';
import 'package:everypay/features/sync/services/payload_serializer.dart';

class SyncEngine {
  final P2PTransport transport;
  final SyncStateRepository syncStateRepo;
  final ExpenseRepository expenseRepo;
  final CategoryRepository categoryRepo;
  final PaymentMethodRepository paymentMethodRepo;
  final PayloadSerializer serializer;
  final ConflictResolver conflictResolver;
  final String localDeviceId;

  static const _timeout = Duration(seconds: 30);

  SyncEngine({
    required this.transport,
    required this.syncStateRepo,
    required this.expenseRepo,
    required this.categoryRepo,
    required this.paymentMethodRepo,
    required this.serializer,
    required this.conflictResolver,
    required this.localDeviceId,
  });

  Future<SyncResult> syncWithDevice(String remoteDeviceId) async {
    try {
      // 1. Get last sync state for the device
      final lastSync = await syncStateRepo.getSyncState(remoteDeviceId);

      // 2. Compute local delta
      final db = await DatabaseHelper.database;
      final deltaCalc = DeltaCalculator(db);
      final localPayload = await deltaCalc.computeDelta(
        localDeviceId,
        lastSync,
      );

      // 3. Serialize and send local changes
      final outBytes = serializer.serialize(localPayload);
      await transport.sendData(remoteDeviceId, outBytes);

      // 4. Receive and deserialize remote changes
      final remoteBytes = await _awaitResponse(remoteDeviceId);
      final remotePayload = serializer.deserialize(remoteBytes);

      // 5. Apply remote changes with conflict resolution
      final stats = await _applyRemoteChanges(remotePayload);

      // 6. Update sync state
      final now = DateTime.now();
      await syncStateRepo.upsertSyncState(
        SyncState(
          deviceId: remoteDeviceId,
          lastSyncAt: now,
          lastExpenseSync: now,
          lastCategorySync: now,
        ),
      );

      return SyncResult(
        deviceId: remoteDeviceId,
        success: true,
        expensesSynced: stats.expenses,
        categoriesSynced: stats.categories,
        conflicts: stats.conflicts,
      );
    } catch (e) {
      return SyncResult(
        deviceId: remoteDeviceId,
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<Uint8List> _awaitResponse(String deviceId) {
    final completer = Completer<Uint8List>();
    late final StreamSubscription<({String deviceId, Uint8List data})> sub;

    sub = transport.receivedData.listen((event) {
      if (event.deviceId == deviceId) {
        if (!completer.isCompleted) completer.complete(event.data);
        sub.cancel();
      }
    });

    return completer.future.timeout(
      _timeout,
      onTimeout: () {
        sub.cancel();
        throw TimeoutException(
          'No response from $deviceId within ${_timeout.inSeconds}s',
        );
      },
    );
  }

  Future<_SyncStats> _applyRemoteChanges(SyncPayload remote) async {
    var expenses = 0;
    var categories = 0;
    var paymentMethods = 0;
    var conflicts = 0;

    // --- Expenses ---
    for (final map in remote.expenses) {
      final remoteExpense = _expenseFromMap(map);
      final remoteDeleted = map['is_deleted'] == 1;
      final local = await expenseRepo.getExpenseById(remoteExpense.id);

      if (local == null) {
        // New record — just insert (or soft-delete insert)
        if (remoteDeleted) {
          await expenseRepo.upsertExpense(remoteExpense);
          await expenseRepo.deleteExpense(remoteExpense.id);
        } else {
          await expenseRepo.upsertExpense(remoteExpense);
        }
        expenses++;
      } else {
        // Conflict — use resolver
        // getExpenseById filters is_deleted = 0, so if we got a result it's not deleted locally
        final result = conflictResolver.resolveExpense(
          local: local,
          remote: remoteExpense,
          localDeleted: false,
          remoteDeleted: remoteDeleted,
        );
        conflicts++;
        if (result.action == ConflictAction.keepRemote) {
          await expenseRepo.upsertExpense(result.winner);
          if (remoteDeleted) {
            await expenseRepo.deleteExpense(result.winner.id);
          }
        }
        expenses++;
      }
    }

    // --- Categories ---
    for (final map in remote.categories) {
      final remoteCategory = _categoryFromMap(map);
      final remoteDeleted = map['is_deleted'] == 1;
      final local = await categoryRepo.getCategoryById(remoteCategory.id);

      if (local == null) {
        if (remoteDeleted) {
          await categoryRepo.upsertCategory(remoteCategory);
          await categoryRepo.deleteCategory(remoteCategory.id);
        } else {
          await categoryRepo.upsertCategory(remoteCategory);
        }
        categories++;
      } else {
        final result = conflictResolver.resolveCategory(
          local: local,
          remote: remoteCategory,
          localDeleted: false,
          remoteDeleted: remoteDeleted,
        );
        conflicts++;
        if (result.action == ConflictAction.keepRemote) {
          await categoryRepo.upsertCategory(result.winner);
          if (remoteDeleted) {
            await categoryRepo.deleteCategory(result.winner.id);
          }
        }
        categories++;
      }
    }

    // --- Payment Methods (simple LWW by updatedAt) ---
    for (final map in remote.paymentMethods) {
      final remotePm = _paymentMethodFromMap(map);
      final remoteDeleted = map['is_deleted'] == 1;
      final local = await paymentMethodRepo.getPaymentMethodById(remotePm.id);

      if (local == null) {
        if (remoteDeleted) {
          await paymentMethodRepo.upsertPaymentMethod(remotePm);
          await paymentMethodRepo.deletePaymentMethod(remotePm.id);
        } else {
          await paymentMethodRepo.upsertPaymentMethod(remotePm);
        }
        paymentMethods++;
      } else {
        // LWW: remote wins if its updatedAt is strictly after local
        if (remotePm.updatedAt.isAfter(local.updatedAt)) {
          await paymentMethodRepo.upsertPaymentMethod(remotePm);
          if (remoteDeleted) {
            await paymentMethodRepo.deletePaymentMethod(remotePm.id);
          }
        }
        paymentMethods++;
      }
    }

    return _SyncStats(
      expenses: expenses,
      categories: categories,
      paymentMethods: paymentMethods,
      conflicts: conflicts,
    );
  }

  // ---------------------------------------------------------------------------
  // Map → Entity helpers (mirrors the _fromMap in Sqlite*Repository classes)
  // ---------------------------------------------------------------------------

  static Expense _expenseFromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as String,
    name: m['name'] as String,
    provider: m['provider'] as String?,
    categoryId: m['category_id'] as String,
    amount: (m['amount'] as num).toDouble(),
    currency: m['currency'] as String,
    billingCycle: BillingCycle.values.byName(m['billing_cycle'] as String),
    customDays: m['custom_days'] as int?,
    startDate: DateTime.parse(m['start_date'] as String),
    endDate: m['end_date'] != null
        ? DateTime.parse(m['end_date'] as String)
        : null,
    nextDueDate: m['next_due_date'] != null
        ? DateTime.parse(m['next_due_date'] as String)
        : null,
    status: ExpenseStatus.values.byName(m['status'] as String),
    notes: m['notes'] as String?,
    logoAsset: m['logo_asset'] as String?,
    tags: (m['tags'] as String?)?.isNotEmpty == true
        ? (m['tags'] as String).split(',')
        : const [],
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
    deviceId: m['device_id'] as String,
    paymentMethodId: m['payment_method_id'] as String?,
  );

  static Category _categoryFromMap(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String,
    colour: m['colour'] as String,
    isDefault: m['is_default'] == 1 || m['is_default'] == true,
    sortOrder: m['sort_order'] as int,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  static PaymentMethod _paymentMethodFromMap(Map<String, dynamic> m) =>
      PaymentMethod(
        id: m['id'] as String,
        name: m['name'] as String,
        type: PaymentMethodType.values.byName(m['type'] as String),
        last4Digits: m['last4_digits'] as String?,
        bankName: m['bank_name'] as String?,
        colourHex: m['colour_hex'] as String,
        isDefault: m['is_default'] == 1 || m['is_default'] == true,
        sortOrder: m['sort_order'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}

class _SyncStats {
  final int expenses;
  final int categories;
  final int paymentMethods;
  final int conflicts;

  const _SyncStats({
    required this.expenses,
    required this.categories,
    required this.paymentMethods,
    required this.conflicts,
  });
}
