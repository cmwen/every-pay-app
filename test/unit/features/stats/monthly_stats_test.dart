import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/features/stats/providers/monthly_stats_provider.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  final now = DateTime(2026, 6, 15);

  Expense makeExpense({
    String id = 'e1',
    String name = 'Netflix',
    String categoryId = 'cat-entertainment',
    double amount = 15.99,
    BillingCycle cycle = BillingCycle.monthly,
    ExpenseStatus status = ExpenseStatus.active,
  }) {
    return Expense(
      id: id,
      name: name,
      categoryId: categoryId,
      amount: amount,
      currency: 'USD',
      billingCycle: cycle,
      startDate: DateTime(2025, 1, 1),
      status: status,
      createdAt: now,
      updatedAt: now,
      deviceId: 'test-device',
    );
  }

  final categoryMap = <String, ({String name, String icon, String colour})>{
    'cat-entertainment': (
      name: 'Entertainment',
      icon: 'play_circle',
      colour: '#E53935'
    ),
    'cat-software': (
      name: 'Software',
      icon: 'cloud',
      colour: '#8E24AA'
    ),
  };

  group('MonthlyStats.compute', () {
    test('returns zero totals for empty list', () {
      final stats = MonthlyStats.compute(
        expenses: [],
        categoryMap: categoryMap,
        month: now,
      );
      expect(stats.totalSpend, 0);
      expect(stats.activeCount, 0);
      expect(stats.categoryBreakdown, isEmpty);
      expect(stats.biggestExpenseName, isNull);
      expect(stats.averagePerSubscription, 0);
    });

    test('computes totals for single expense', () {
      final stats = MonthlyStats.compute(
        expenses: [makeExpense()],
        categoryMap: categoryMap,
        month: now,
      );
      expect(stats.totalSpend, closeTo(15.99, 0.01));
      expect(stats.activeCount, 1);
      expect(stats.categoryBreakdown.length, 1);
      expect(stats.biggestExpenseName, 'Netflix');
      expect(stats.averagePerSubscription, closeTo(15.99, 0.01));
    });

    test('groups by category correctly', () {
      final stats = MonthlyStats.compute(
        expenses: [
          makeExpense(id: 'e1', categoryId: 'cat-entertainment', amount: 10),
          makeExpense(id: 'e2', categoryId: 'cat-entertainment', amount: 5),
          makeExpense(id: 'e3', categoryId: 'cat-software', amount: 20),
        ],
        categoryMap: categoryMap,
        month: now,
      );
      expect(stats.totalSpend, closeTo(35, 0.01));
      expect(stats.categoryBreakdown.length, 2);
      // Sorted by amount desc — software (20) first, entertainment (15)
      expect(stats.categoryBreakdown[0].categoryId, 'cat-software');
      expect(stats.categoryBreakdown[0].amount, closeTo(20, 0.01));
      expect(stats.categoryBreakdown[1].categoryId, 'cat-entertainment');
    });

    test('excludes paused expenses', () {
      final stats = MonthlyStats.compute(
        expenses: [
          makeExpense(status: ExpenseStatus.active),
          makeExpense(
              id: 'e2', status: ExpenseStatus.paused, amount: 100),
        ],
        categoryMap: categoryMap,
        month: now,
      );
      expect(stats.activeCount, 1);
      expect(stats.totalSpend, closeTo(15.99, 0.01));
    });

    test('percentage sums to 100', () {
      final stats = MonthlyStats.compute(
        expenses: [
          makeExpense(id: 'e1', categoryId: 'cat-entertainment', amount: 30),
          makeExpense(id: 'e2', categoryId: 'cat-software', amount: 70),
        ],
        categoryMap: categoryMap,
        month: now,
      );
      final totalPct = stats.categoryBreakdown
          .fold<double>(0, (sum, c) => sum + c.percentage);
      expect(totalPct, closeTo(100, 0.01));
    });

    test('identifies biggest expense', () {
      final stats = MonthlyStats.compute(
        expenses: [
          makeExpense(id: 'e1', name: 'Small', amount: 5),
          makeExpense(id: 'e2', name: 'Big', amount: 50),
          makeExpense(id: 'e3', name: 'Medium', amount: 20),
        ],
        categoryMap: categoryMap,
        month: now,
      );
      expect(stats.biggestExpenseName, 'Big');
      expect(stats.biggestExpenseAmount, closeTo(50, 0.01));
    });
  });
}
