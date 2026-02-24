import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';

class SqliteExpenseRepository implements ExpenseRepository {
  final _changeController = StreamController<void>.broadcast();

  Map<String, dynamic> _toMap(Expense e) => {
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
        'is_deleted': 0,
      };

  Expense _fromMap(Map<String, dynamic> m) => Expense(
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
      );

  @override
  Stream<List<Expense>> watchExpenses({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async* {
    yield await _queryExpenses(
      categoryId: categoryId,
      status: status,
      searchQuery: searchQuery,
    );
    await for (final _ in _changeController.stream) {
      yield await _queryExpenses(
        categoryId: categoryId,
        status: status,
        searchQuery: searchQuery,
      );
    }
  }

  Future<List<Expense>> _queryExpenses({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async {
    final db = await DatabaseHelper.database;
    final where = <String>['is_deleted = 0'];
    final args = <dynamic>[];

    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (status != null && status != 'all') {
      where.add('status = ?');
      args.add(status);
    }

    final results = await db.query(
      'expenses',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'next_due_date ASC',
    );

    var expenses = results.map(_fromMap).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      expenses = expenses.where((e) {
        return e.name.toLowerCase().contains(q) ||
            (e.provider?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return expenses;
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'expenses',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  @override
  Future<void> upsertExpense(Expense expense) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'expenses',
      _toMap(expense),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'expenses',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'expenses',
      where: 'is_deleted = 0',
      orderBy: 'next_due_date ASC',
    );
    return results.map(_fromMap).toList();
  }

  void dispose() {
    _changeController.close();
  }
}
