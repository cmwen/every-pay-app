import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/data/repositories/expense_repository_impl.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  late InMemoryExpenseRepository repo;

  Expense createExpense({
    String id = 'test-1',
    String name = 'Netflix',
    String categoryId = 'cat-entertainment',
    double amount = 15.49,
    ExpenseStatus status = ExpenseStatus.active,
  }) {
    final now = DateTime.now();
    return Expense(
      id: id,
      name: name,
      categoryId: categoryId,
      amount: amount,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2024, 1, 1),
      nextDueDate: DateTime.now().add(const Duration(days: 5)),
      status: status,
      createdAt: now,
      updatedAt: now,
      deviceId: 'local',
    );
  }

  setUp(() {
    repo = InMemoryExpenseRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  group('InMemoryExpenseRepository', () {
    test('initially returns empty list', () async {
      final expenses = await repo.getAllExpenses();
      expect(expenses, isEmpty);
    });

    test('upsertExpense adds new expense', () async {
      final expense = createExpense();
      await repo.upsertExpense(expense);

      final all = await repo.getAllExpenses();
      expect(all.length, 1);
      expect(all.first.name, 'Netflix');
    });

    test('upsertExpense updates existing expense', () async {
      final expense = createExpense();
      await repo.upsertExpense(expense);

      final updated = expense.copyWith(name: 'Netflix 4K');
      await repo.upsertExpense(updated);

      final all = await repo.getAllExpenses();
      expect(all.length, 1);
      expect(all.first.name, 'Netflix 4K');
    });

    test('getExpenseById returns correct expense', () async {
      await repo.upsertExpense(createExpense(id: 'a', name: 'A'));
      await repo.upsertExpense(createExpense(id: 'b', name: 'B'));

      final found = await repo.getExpenseById('b');
      expect(found, isNotNull);
      expect(found!.name, 'B');
    });

    test('getExpenseById returns null for missing id', () async {
      final found = await repo.getExpenseById('nonexistent');
      expect(found, isNull);
    });

    test('deleteExpense removes expense', () async {
      await repo.upsertExpense(createExpense());
      await repo.deleteExpense('test-1');

      final all = await repo.getAllExpenses();
      expect(all, isEmpty);
    });

    test('watchExpenses emits current state immediately', () async {
      await repo.upsertExpense(createExpense());

      final stream = repo.watchExpenses();
      final first = await stream.first;
      expect(first.length, 1);
    });

    test('watchExpenses filters by category', () async {
      await repo.upsertExpense(
        createExpense(id: '1', categoryId: 'cat-entertainment'),
      );
      await repo.upsertExpense(
        createExpense(id: '2', categoryId: 'cat-utilities'),
      );

      final stream = repo.watchExpenses(categoryId: 'cat-entertainment');
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.categoryId, 'cat-entertainment');
    });

    test('watchExpenses filters by status', () async {
      await repo.upsertExpense(createExpense(id: '1'));
      await repo.upsertExpense(
        createExpense(id: '2', status: ExpenseStatus.cancelled),
      );

      final stream = repo.watchExpenses(status: 'active');
      final first = await stream.first;
      expect(first.length, 1);
    });

    test('watchExpenses filters by search query', () async {
      await repo.upsertExpense(createExpense(id: '1', name: 'Netflix'));
      await repo.upsertExpense(createExpense(id: '2', name: 'Spotify'));

      final stream = repo.watchExpenses(searchQuery: 'net');
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.name, 'Netflix');
    });
  });
}
