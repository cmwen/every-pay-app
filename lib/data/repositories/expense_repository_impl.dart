import 'dart:async';

import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> _expenses = {};
  final _controller = StreamController<void>.broadcast();

  void _notify() {
    _controller.add(null);
  }

  List<Expense> _applyFilters({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) {
    var filtered = _expenses.values.toList();

    if (categoryId != null) {
      filtered = filtered.where((e) => e.categoryId == categoryId).toList();
    }
    if (status != null && status != 'all') {
      filtered = filtered.where((e) => e.status.name == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.name.toLowerCase().contains(query) ||
            (e.provider?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    filtered.sort((a, b) {
      final aDue = a.nextDueDate ?? DateTime(2099);
      final bDue = b.nextDueDate ?? DateTime(2099);
      return aDue.compareTo(bDue);
    });

    return filtered;
  }

  @override
  Stream<List<Expense>> watchExpenses({
    String? categoryId,
    String? status,
    String? searchQuery,
  }) async* {
    yield _applyFilters(
      categoryId: categoryId,
      status: status,
      searchQuery: searchQuery,
    );
    await for (final _ in _controller.stream) {
      yield _applyFilters(
        categoryId: categoryId,
        status: status,
        searchQuery: searchQuery,
      );
    }
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    return _expenses[id];
  }

  @override
  Future<void> upsertExpense(Expense expense) async {
    _expenses[expense.id] = expense;
    _notify();
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.remove(id);
    _notify();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return _expenses.values.toList();
  }

  void dispose() {
    _controller.close();
  }
}
