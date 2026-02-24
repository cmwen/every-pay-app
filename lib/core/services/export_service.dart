import 'dart:convert';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/category_repository.dart';

class ExportService {
  final ExpenseRepository _expenseRepo;
  final CategoryRepository _categoryRepo;

  ExportService({
    required ExpenseRepository expenseRepo,
    required CategoryRepository categoryRepo,
  })  : _expenseRepo = expenseRepo,
        _categoryRepo = categoryRepo;

  /// Export all data as JSON string
  Future<String> exportJson() async {
    final expenses = await _expenseRepo.getAllExpenses();
    final categories = await _categoryRepo.getAllCategories();

    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'expenses': expenses.map(_expenseToJson).toList(),
      'categories': categories.map(_categoryToJson).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export expenses as CSV string
  Future<String> exportCsv() async {
    final expenses = await _expenseRepo.getAllExpenses();
    final categories = await _categoryRepo.getAllCategories();
    final categoryMap = {for (final c in categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln(
      'Name,Provider,Category,Amount,Currency,Billing Cycle,Start Date,End Date,Status,Notes,Tags',
    );

    for (final e in expenses) {
      final fields = [
        _csvEscape(e.name),
        _csvEscape(e.provider ?? ''),
        _csvEscape(categoryMap[e.categoryId] ?? 'Unknown'),
        e.amount.toStringAsFixed(2),
        e.currency,
        e.billingCycle.name,
        e.startDate.toIso8601String().split('T').first,
        e.endDate?.toIso8601String().split('T').first ?? '',
        e.status.name,
        _csvEscape(e.notes ?? ''),
        _csvEscape(e.tags.join('; ')),
      ];
      buffer.writeln(fields.join(','));
    }

    return buffer.toString();
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Map<String, dynamic> _expenseToJson(Expense e) => {
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
        'tags': e.tags,
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
        'device_id': e.deviceId,
      };

  Map<String, dynamic> _categoryToJson(Category c) => {
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'colour': c.colour,
        'is_default': c.isDefault,
        'sort_order': c.sortOrder,
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
      };
}
