import 'package:sqflite/sqflite.dart';
import 'package:everypay/domain/entities/sync_payload.dart';
import 'package:everypay/domain/entities/sync_state.dart';

class DeltaCalculator {
  final Database _db;

  DeltaCalculator(this._db);

  Future<List<Map<String, dynamic>>> getExpensesSince(DateTime? since) async {
    if (since == null) {
      return _db.query('expenses');
    }
    return _db.query(
      'expenses',
      where: 'updated_at > ?',
      whereArgs: [since.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getCategoriesSince(DateTime? since) async {
    if (since == null) {
      return _db.query('categories');
    }
    return _db.query(
      'categories',
      where: 'updated_at > ?',
      whereArgs: [since.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentMethodsSince(
    DateTime? since,
  ) async {
    if (since == null) {
      return _db.query('payment_methods');
    }
    return _db.query(
      'payment_methods',
      where: 'updated_at > ?',
      whereArgs: [since.toIso8601String()],
    );
  }

  Future<SyncPayload> computeDelta(
    String localDeviceId,
    SyncState? lastSync,
  ) async {
    final now = DateTime.now();
    final expenses = await getExpensesSince(lastSync?.lastExpenseSync);
    final categories = await getCategoriesSince(lastSync?.lastCategorySync);
    final paymentMethods = await getPaymentMethodsSince(lastSync?.lastSyncAt);

    return SyncPayload(
      deviceId: localDeviceId,
      syncTimestamp: now.toIso8601String(),
      schemaVersion: 2,
      expenses: expenses,
      categories: categories,
      paymentMethods: paymentMethods,
    );
  }
}
