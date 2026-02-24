import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/features/stats/providers/yearly_stats_provider.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  final now = DateTime(2026, 6, 15);

  Expense makeExpense({
    double amount = 10.0,
    BillingCycle cycle = BillingCycle.monthly,
  }) {
    return Expense(
      id: 'e1',
      name: 'Test',
      categoryId: 'cat-entertainment',
      amount: amount,
      currency: 'USD',
      billingCycle: cycle,
      startDate: DateTime(2025, 1, 1),
      status: ExpenseStatus.active,
      createdAt: now,
      updatedAt: now,
      deviceId: 'test-device',
    );
  }

  group('YearlyStats.compute', () {
    test('returns zero for empty list', () {
      final stats = YearlyStats.compute(
        expenses: [],
        year: 2026,
        now: now,
      );
      expect(stats.totalActual, 0);
      expect(stats.totalProjected, 0);
      expect(stats.months.length, 12);
    });

    test('computes 12 months', () {
      final stats = YearlyStats.compute(
        expenses: [makeExpense(amount: 100)],
        year: 2026,
        now: now,
      );
      expect(stats.months.length, 12);
      expect(stats.totalProjected, closeTo(1200, 0.01));
      // June is month 6, so actual = 6 * 100
      expect(stats.totalActual, closeTo(600, 0.01));
      expect(stats.monthlyAverage, closeTo(100, 0.01));
    });

    test('marks future months as projected', () {
      final stats = YearlyStats.compute(
        expenses: [makeExpense()],
        year: 2026,
        now: now, // June
      );
      // Months 1-6 actual, 7-12 projected
      expect(stats.months.where((m) => !m.isProjected).length, 6);
      expect(stats.months.where((m) => m.isProjected).length, 6);
    });

    test('all months projected for future year', () {
      final stats = YearlyStats.compute(
        expenses: [makeExpense()],
        year: 2027,
        now: now,
      );
      // Different year uses 12 as currentMonth
      expect(stats.months.where((m) => !m.isProjected).length, 12);
    });
  });
}
