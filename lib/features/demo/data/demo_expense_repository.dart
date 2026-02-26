import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/features/demo/data/demo_data.dart';

/// In-memory, read-only expense repository for demo mode.
class DemoExpenseRepository implements ExpenseRepository {
  @override
  Stream<List<Expense>> watchExpenses({
    String? categoryId,
    String? status,
    String? searchQuery,
    String? paymentMethodId,
  }) {
    var result = List<Expense>.from(demoExpenses);
    if (categoryId != null) {
      result = result.where((e) => e.categoryId == categoryId).toList();
    }
    if (status != null) {
      result = result.where((e) => e.status.name == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                (e.provider?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    if (paymentMethodId != null) {
      result =
          result.where((e) => e.paymentMethodId == paymentMethodId).toList();
    }
    return Stream.value(result);
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    try {
      return demoExpenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertExpense(Expense expense) async {
    // No-op in demo mode
  }

  @override
  Future<void> deleteExpense(String id) async {
    // No-op in demo mode
  }

  @override
  Future<List<Expense>> getAllExpenses() async => List.from(demoExpenses);
}
