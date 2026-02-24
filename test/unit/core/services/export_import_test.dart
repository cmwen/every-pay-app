import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/core/services/export_service.dart';
import 'package:everypay/core/services/import_service.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/category_repository.dart';
import 'dart:convert';

// Simple in-memory mock repos for export/import testing
class _MockExpenseRepo implements ExpenseRepository {
  final List<Expense> _expenses = [];

  @override
  Future<List<Expense>> getAllExpenses() async => List.of(_expenses);

  @override
  Future<Expense?> getExpenseById(String id) async =>
      _expenses.where((e) => e.id == id).firstOrNull;

  @override
  Future<void> upsertExpense(Expense expense) async {
    _expenses.removeWhere((e) => e.id == expense.id);
    _expenses.add(expense);
  }

  @override
  Future<void> deleteExpense(String id) async =>
      _expenses.removeWhere((e) => e.id == id);

  @override
  Stream<List<Expense>> watchExpenses({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async* {
    yield _expenses;
  }
}

class _MockCategoryRepo implements CategoryRepository {
  final List<Category> _categories = [];

  @override
  Future<List<Category>> getAllCategories() async => List.of(_categories);

  @override
  Future<Category?> getCategoryById(String id) async =>
      _categories.where((c) => c.id == id).firstOrNull;

  @override
  Future<void> upsertCategory(Category category) async {
    _categories.removeWhere((c) => c.id == category.id);
    _categories.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async =>
      _categories.removeWhere((c) => c.id == id);

  @override
  Stream<List<Category>> watchCategories() async* {
    yield _categories;
  }
}

void main() {
  final now = DateTime(2026, 6, 15);

  final testCategory = Category(
    id: 'cat-entertainment',
    name: 'Entertainment',
    icon: 'play_circle',
    colour: '#E53935',
    isDefault: true,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );

  final testExpense = Expense(
    id: 'exp-1',
    name: 'Netflix',
    provider: 'Netflix Inc',
    categoryId: 'cat-entertainment',
    amount: 15.99,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2025, 1, 1),
    status: ExpenseStatus.active,
    notes: 'Standard plan',
    tags: ['streaming', 'video'],
    createdAt: now,
    updatedAt: now,
    deviceId: 'test-device',
  );

  group('ExportService', () {
    late _MockExpenseRepo expenseRepo;
    late _MockCategoryRepo categoryRepo;
    late ExportService exportService;

    setUp(() {
      expenseRepo = _MockExpenseRepo();
      categoryRepo = _MockCategoryRepo();
      exportService = ExportService(
        expenseRepo: expenseRepo,
        categoryRepo: categoryRepo,
      );
    });

    test('exports empty data as valid JSON', () async {
      final json = await exportService.exportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect(data['version'], 1);
      expect(data['expenses'], isEmpty);
      expect(data['categories'], isEmpty);
    });

    test('exports expenses and categories as JSON', () async {
      await categoryRepo.upsertCategory(testCategory);
      await expenseRepo.upsertExpense(testExpense);

      final json = await exportService.exportJson();
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect((data['expenses'] as List).length, 1);
      expect((data['categories'] as List).length, 1);

      final exp = (data['expenses'] as List).first as Map<String, dynamic>;
      expect(exp['name'], 'Netflix');
      expect(exp['amount'], 15.99);
      expect(exp['tags'], ['streaming', 'video']);
    });

    test('exports CSV with headers', () async {
      await categoryRepo.upsertCategory(testCategory);
      await expenseRepo.upsertExpense(testExpense);

      final csv = await exportService.exportCsv();
      final lines = csv.trim().split('\n');
      expect(lines.length, 2); // header + 1 row
      expect(lines[0], contains('Name'));
      expect(lines[1], contains('Netflix'));
      expect(lines[1], contains('Entertainment'));
    });

    test('CSV escapes commas in values', () async {
      final expWithComma = testExpense.copyWith(
        notes: 'Has, comma',
      );
      await categoryRepo.upsertCategory(testCategory);
      await expenseRepo.upsertExpense(expWithComma);

      final csv = await exportService.exportCsv();
      expect(csv, contains('"Has, comma"'));
    });
  });

  group('ImportService', () {
    late _MockExpenseRepo expenseRepo;
    late _MockCategoryRepo categoryRepo;
    late ImportService importService;

    setUp(() {
      expenseRepo = _MockExpenseRepo();
      categoryRepo = _MockCategoryRepo();
      importService = ImportService(
        expenseRepo: expenseRepo,
        categoryRepo: categoryRepo,
      );
    });

    test('imports valid JSON', () async {
      final json = jsonEncode({
        'version': 1,
        'expenses': [
          {
            'id': 'exp-1',
            'name': 'Netflix',
            'category_id': 'cat-entertainment',
            'amount': 15.99,
            'currency': 'USD',
            'billing_cycle': 'monthly',
            'start_date': '2025-01-01T00:00:00.000',
            'status': 'active',
            'tags': ['streaming'],
            'created_at': '2026-06-15T00:00:00.000',
            'updated_at': '2026-06-15T00:00:00.000',
            'device_id': 'test-device',
          }
        ],
        'categories': [
          {
            'id': 'cat-entertainment',
            'name': 'Entertainment',
            'icon': 'play_circle',
            'colour': '#E53935',
            'is_default': true,
            'sort_order': 0,
            'created_at': '2026-06-15T00:00:00.000',
            'updated_at': '2026-06-15T00:00:00.000',
          }
        ],
      });

      final result = await importService.importJson(json);
      expect(result.expensesImported, 1);
      expect(result.categoriesImported, 1);
      expect(result.errors, isEmpty);

      final expenses = await expenseRepo.getAllExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.name, 'Netflix');
    });

    test('handles invalid JSON gracefully', () async {
      final result = await importService.importJson('not json');
      expect(result.errors, isNotEmpty);
      expect(result.expensesImported, 0);
    });

    test('handles partial invalid data', () async {
      final json = jsonEncode({
        'version': 1,
        'expenses': [
          {'id': 'bad'}, // Missing required fields
        ],
        'categories': [],
      });

      final result = await importService.importJson(json);
      expect(result.expensesSkipped, 1);
      expect(result.errors, isNotEmpty);
    });

    test('merges with existing data (upsert)', () async {
      await expenseRepo.upsertExpense(testExpense);

      final updatedJson = jsonEncode({
        'version': 1,
        'expenses': [
          {
            'id': 'exp-1',
            'name': 'Netflix Premium',
            'category_id': 'cat-entertainment',
            'amount': 22.99,
            'currency': 'USD',
            'billing_cycle': 'monthly',
            'start_date': '2025-01-01T00:00:00.000',
            'status': 'active',
            'tags': [],
            'created_at': '2026-06-15T00:00:00.000',
            'updated_at': '2026-07-01T00:00:00.000',
            'device_id': 'test-device',
          }
        ],
        'categories': [],
      });

      final result = await importService.importJson(updatedJson);
      expect(result.expensesImported, 1);

      final expenses = await expenseRepo.getAllExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.name, 'Netflix Premium');
      expect(expenses.first.amount, 22.99);
    });
  });

  group('Round-trip export/import', () {
    test('export then import preserves data', () async {
      final sourceExpRepo = _MockExpenseRepo();
      final sourceCatRepo = _MockCategoryRepo();
      await sourceCatRepo.upsertCategory(testCategory);
      await sourceExpRepo.upsertExpense(testExpense);

      final exportService = ExportService(
        expenseRepo: sourceExpRepo,
        categoryRepo: sourceCatRepo,
      );
      final json = await exportService.exportJson();

      final targetExpRepo = _MockExpenseRepo();
      final targetCatRepo = _MockCategoryRepo();
      final importService = ImportService(
        expenseRepo: targetExpRepo,
        categoryRepo: targetCatRepo,
      );
      final result = await importService.importJson(json);

      expect(result.expensesImported, 1);
      expect(result.categoriesImported, 1);

      final expenses = await targetExpRepo.getAllExpenses();
      expect(expenses.first.name, testExpense.name);
      expect(expenses.first.amount, testExpense.amount);
      expect(expenses.first.tags, testExpense.tags);
    });
  });
}
