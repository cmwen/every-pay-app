import 'package:sqflite/sqflite.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/domain/entities/sync_state.dart';
import 'package:everypay/domain/repositories/sync_state_repository.dart';

class SqliteSyncStateRepository implements SyncStateRepository {
  Map<String, dynamic> _toMap(SyncState s) => {
    'device_id': s.deviceId,
    'last_sync_at': s.lastSyncAt.toIso8601String(),
    'last_expense_sync': s.lastExpenseSync?.toIso8601String(),
    'last_category_sync': s.lastCategorySync?.toIso8601String(),
  };

  SyncState _fromMap(Map<String, dynamic> m) => SyncState(
    deviceId: m['device_id'] as String,
    lastSyncAt: DateTime.parse(m['last_sync_at'] as String),
    lastExpenseSync: m['last_expense_sync'] != null
        ? DateTime.parse(m['last_expense_sync'] as String)
        : null,
    lastCategorySync: m['last_category_sync'] != null
        ? DateTime.parse(m['last_category_sync'] as String)
        : null,
  );

  @override
  Future<SyncState?> getSyncState(String deviceId) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'sync_state',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  @override
  Future<void> upsertSyncState(SyncState state) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'sync_state',
      _toMap(state),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSyncState(String deviceId) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      'sync_state',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }
}
