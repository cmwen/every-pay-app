import 'package:everypay/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses({
    String? categoryId,
    String? status,
    String? searchQuery,
  });
  Future<Expense?> getExpenseById(String id);
  Future<void> upsertExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getAllExpenses();
}
