import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/domain/repositories/payment_method_repository.dart';

class SqlitePaymentMethodRepository implements PaymentMethodRepository {
  final _changeController = StreamController<void>.broadcast();

  Map<String, dynamic> _toMap(PaymentMethod pm) => {
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
    'is_deleted': 0,
  };

  PaymentMethod _fromMap(Map<String, dynamic> m) => PaymentMethod(
    id: m['id'] as String,
    name: m['name'] as String,
    type: PaymentMethodType.values.byName(m['type'] as String),
    last4Digits: m['last4_digits'] as String?,
    bankName: m['bank_name'] as String?,
    colourHex: m['colour_hex'] as String,
    isDefault: m['is_default'] == 1,
    sortOrder: m['sort_order'] as int,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );

  @override
  Stream<List<PaymentMethod>> watchPaymentMethods() async* {
    yield await _query();
    await for (final _ in _changeController.stream) {
      yield await _query();
    }
  }

  Future<List<PaymentMethod>> _query() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'payment_methods',
      where: 'is_deleted = 0',
      orderBy: 'sort_order ASC, name ASC',
    );
    return results.map(_fromMap).toList();
  }

  @override
  Future<PaymentMethod?> getPaymentMethodById(String id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'payment_methods',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  @override
  Future<void> upsertPaymentMethod(PaymentMethod paymentMethod) async {
    final db = await DatabaseHelper.database;
    // If this is being set as default, clear existing default first.
    if (paymentMethod.isDefault) {
      await db.update(
        'payment_methods',
        {'is_default': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id != ? AND is_deleted = 0',
        whereArgs: [paymentMethod.id],
      );
    }
    await db.insert(
      'payment_methods',
      _toMap(paymentMethod),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  @override
  Future<void> deletePaymentMethod(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'payment_methods',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  @override
  Future<List<PaymentMethod>> getAllPaymentMethods() async {
    return _query();
  }

  @override
  Future<int> countExpensesUsingPaymentMethod(String id) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM expenses WHERE payment_method_id = ? AND is_deleted = 0',
      [id],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  @override
  Future<void> clearPaymentMethodFromExpenses(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'expenses',
      {
        'payment_method_id': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'payment_method_id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  @override
  void dispose() {
    _changeController.close();
  }
}
