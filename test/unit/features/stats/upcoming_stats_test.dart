import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/features/stats/providers/upcoming_provider.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  group('UpcomingStats.compute', () {
    Expense makeExpense({
      String id = 'e1',
      double amount = 10.0,
      BillingCycle cycle = BillingCycle.monthly,
      DateTime? startDate,
      ExpenseStatus status = ExpenseStatus.active,
    }) {
      final now = DateTime(2026, 6, 15);
      return Expense(
        id: id,
        name: 'Test $id',
        categoryId: 'cat-entertainment',
        amount: amount,
        currency: 'USD',
        billingCycle: cycle,
        startDate: startDate ?? DateTime(2026, 6, 1),
        status: status,
        createdAt: now,
        updatedAt: now,
        deviceId: 'test-device',
      );
    }

    test('returns empty for no active expenses', () {
      final stats = UpcomingStats.compute(
        expenses: [makeExpense(status: ExpenseStatus.paused)],
        days: 30,
        relativeTo: DateTime(2026, 6, 15),
      );
      expect(stats.groupedByDate, isEmpty);
      expect(stats.totalAmount, 0);
    });

    test('finds upcoming monthly payment', () {
      final stats = UpcomingStats.compute(
        expenses: [makeExpense(startDate: DateTime(2026, 6, 1))],
        days: 30,
        relativeTo: DateTime(2026, 6, 15),
      );
      expect(stats.groupedByDate.isNotEmpty, true);
      // Next due after June 15 from start June 1 monthly = July 1
      expect(stats.groupedByDate.keys.first, DateTime(2026, 7, 1));
    });

    test('finds weekly payments within window', () {
      final stats = UpcomingStats.compute(
        expenses: [
          makeExpense(
            startDate: DateTime(2026, 6, 15),
            cycle: BillingCycle.weekly,
          ),
        ],
        days: 30,
        relativeTo: DateTime(2026, 6, 15),
      );
      // Weekly from June 15: June 22, June 29, July 6, July 13
      expect(stats.groupedByDate.length, 4);
    });

    test('groups payments by date', () {
      final stats = UpcomingStats.compute(
        expenses: [
          makeExpense(
              id: 'e1', startDate: DateTime(2026, 6, 1), amount: 10),
          makeExpense(
              id: 'e2', startDate: DateTime(2026, 6, 1), amount: 20),
        ],
        days: 30,
        relativeTo: DateTime(2026, 6, 15),
      );
      // Both have next due July 1
      final july1 = DateTime(2026, 7, 1);
      expect(stats.groupedByDate[july1]?.length, 2);
      expect(stats.totalAmount, closeTo(30, 0.01));
    });

    test('excludes payments beyond window', () {
      final stats = UpcomingStats.compute(
        expenses: [
          makeExpense(
            startDate: DateTime(2026, 6, 1),
            cycle: BillingCycle.yearly,
          ),
        ],
        days: 30,
        relativeTo: DateTime(2026, 6, 15),
      );
      // Yearly from June 1: next = June 1, 2027 — beyond 30 days
      expect(stats.groupedByDate, isEmpty);
    });
  });
}
