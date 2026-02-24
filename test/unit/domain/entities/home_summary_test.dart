import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/features/home/providers/home_summary.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  Expense createExpense({
    String id = 'test-1',
    double amount = 15.49,
    BillingCycle billingCycle = BillingCycle.monthly,
    ExpenseStatus status = ExpenseStatus.active,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    return Expense(
      id: id,
      name: 'Test',
      categoryId: 'cat-entertainment',
      amount: amount,
      currency: 'USD',
      billingCycle: billingCycle,
      startDate: DateTime(2024, 1, 1),
      endDate: endDate,
      status: status,
      createdAt: now,
      updatedAt: now,
      deviceId: 'local',
    );
  }

  group('HomeSummary', () {
    test('computes monthly total from active expenses', () {
      final expenses = [
        createExpense(id: '1', amount: 15.49),
        createExpense(id: '2', amount: 9.99),
        createExpense(id: '3', amount: 89.00),
      ];

      final summary = HomeSummary.compute(expenses);
      expect(summary.monthlyTotal, closeTo(114.48, 0.01));
      expect(summary.activeCount, 3);
    });

    test('excludes cancelled expenses', () {
      final expenses = [
        createExpense(id: '1', amount: 15.49),
        createExpense(id: '2', amount: 9.99, status: ExpenseStatus.cancelled),
      ];

      final summary = HomeSummary.compute(expenses);
      expect(summary.monthlyTotal, closeTo(15.49, 0.01));
      expect(summary.activeCount, 1);
    });

    test('excludes paused expenses', () {
      final expenses = [
        createExpense(id: '1', amount: 15.49),
        createExpense(id: '2', amount: 9.99, status: ExpenseStatus.paused),
      ];

      final summary = HomeSummary.compute(expenses);
      expect(summary.activeCount, 1);
    });

    test('normalizes yearly expense to monthly', () {
      final expenses = [
        createExpense(
          id: '1',
          amount: 120.0,
          billingCycle: BillingCycle.yearly,
        ),
      ];

      final summary = HomeSummary.compute(expenses);
      expect(summary.monthlyTotal, closeTo(10.0, 0.01));
    });

    test('handles empty list', () {
      final summary = HomeSummary.compute([]);
      expect(summary.monthlyTotal, 0.0);
      expect(summary.activeCount, 0);
    });

    test('percentChange returns null when no previous month', () {
      const summary = HomeSummary(monthlyTotal: 100.0, activeCount: 5);
      expect(summary.percentChange, isNull);
    });

    test('percentChange computes correctly', () {
      const summary = HomeSummary(
        monthlyTotal: 110.0,
        activeCount: 5,
        previousMonthTotal: 100.0,
      );
      expect(summary.percentChange, closeTo(10.0, 0.01));
    });
  });
}
