import 'dart:convert';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/category_repository.dart';

class ImportResult {
  final int expensesImported;
  final int categoriesImported;
  final int expensesSkipped;
  final int categoriesSkipped;
  final List<String> errors;

  const ImportResult({
    required this.expensesImported,
    required this.categoriesImported,
    this.expensesSkipped = 0,
    this.categoriesSkipped = 0,
    this.errors = const [],
  });
}

class ImportService {
  final ExpenseRepository _expenseRepo;
  final CategoryRepository _categoryRepo;

  ImportService({
    required ExpenseRepository expenseRepo,
    required CategoryRepository categoryRepo,
  }) : _expenseRepo = expenseRepo,
       _categoryRepo = categoryRepo;

  /// Import data from JSON string. Merges with existing data (upsert).
  Future<ImportResult> importJson(String jsonString) async {
    final errors = <String>[];
    int expensesImported = 0;
    int categoriesImported = 0;
    int expensesSkipped = 0;
    int categoriesSkipped = 0;

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import categories first
      final categoriesJson = data['categories'] as List<dynamic>? ?? [];
      for (final catJson in categoriesJson) {
        try {
          final cat = _categoryFromJson(catJson as Map<String, dynamic>);
          await _categoryRepo.upsertCategory(cat);
          categoriesImported++;
        } catch (e) {
          errors.add('Category import error: $e');
          categoriesSkipped++;
        }
      }

      // Import expenses
      final expensesJson = data['expenses'] as List<dynamic>? ?? [];
      for (final expJson in expensesJson) {
        try {
          final expense = _expenseFromJson(expJson as Map<String, dynamic>);
          await _expenseRepo.upsertExpense(expense);
          expensesImported++;
        } catch (e) {
          errors.add('Expense import error: $e');
          expensesSkipped++;
        }
      }
    } catch (e) {
      errors.add('JSON parse error: $e');
    }

    return ImportResult(
      expensesImported: expensesImported,
      categoriesImported: categoriesImported,
      expensesSkipped: expensesSkipped,
      categoriesSkipped: categoriesSkipped,
      errors: errors,
    );
  }

  Expense _expenseFromJson(Map<String, dynamic> m) => Expense(
    id: m['id'] as String,
    name: m['name'] as String,
    provider: m['provider'] as String?,
    categoryId: m['category_id'] as String,
    amount: (m['amount'] as num).toDouble(),
    currency: m['currency'] as String? ?? 'USD',
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
    tags: (m['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
    deviceId: m['device_id'] as String? ?? 'imported',
  );

  Category _categoryFromJson(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String? ?? 'category',
    colour: m['colour'] as String? ?? '#546E7A',
    isDefault: m['is_default'] as bool? ?? false,
    sortOrder: m['sort_order'] as int? ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}
