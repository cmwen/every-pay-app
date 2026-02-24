import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  Expense createExpense({
    double amount = 15.49,
    BillingCycle billingCycle = BillingCycle.monthly,
    int? customDays,
    ExpenseStatus status = ExpenseStatus.active,
    DateTime? endDate,
    DateTime? startDate,
  }) {
    final now = DateTime.now();
    return Expense(
      id: 'test-id',
      name: 'Netflix',
      provider: 'Netflix Inc.',
      categoryId: 'cat-entertainment',
      amount: amount,
      currency: 'USD',
      billingCycle: billingCycle,
      customDays: customDays,
      startDate: startDate ?? DateTime(2024, 1, 1),
      endDate: endDate,
      nextDueDate: DateTime.now().add(const Duration(days: 5)),
      status: status,
      tags: const ['streaming', 'family'],
      createdAt: now,
      updatedAt: now,
      deviceId: 'local',
    );
  }

  group('Expense', () {
    group('monthlyCost', () {
      test('monthly expense returns same amount', () {
        final expense = createExpense(amount: 15.49);
        expect(expense.monthlyCost, 15.49);
      });

      test('yearly expense returns amount / 12', () {
        final expense = createExpense(
          amount: 120.0,
          billingCycle: BillingCycle.yearly,
        );
        expect(expense.monthlyCost, closeTo(10.0, 0.01));
      });

      test('weekly expense returns amount * 52/12', () {
        final expense = createExpense(
          amount: 10.0,
          billingCycle: BillingCycle.weekly,
        );
        expect(expense.monthlyCost, closeTo(43.33, 0.01));
      });
    });

    group('yearlyCost', () {
      test('monthly 15.49 returns 185.88/year', () {
        final expense = createExpense(amount: 15.49);
        expect(expense.yearlyCost, closeTo(185.88, 0.01));
      });
    });

    group('isActive', () {
      test('active status without end date is active', () {
        expect(createExpense().isActive, isTrue);
      });

      test('paused status is not active', () {
        expect(createExpense(status: ExpenseStatus.paused).isActive, isFalse);
      });

      test('cancelled status is not active', () {
        expect(
          createExpense(status: ExpenseStatus.cancelled).isActive,
          isFalse,
        );
      });

      test('expired expense is not active', () {
        final expense = createExpense(
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expense.isActive, isFalse);
      });
    });

    group('isExpired', () {
      test('no end date means not expired', () {
        expect(createExpense().isExpired, isFalse);
      });

      test('past end date means expired', () {
        final expense = createExpense(
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expense.isExpired, isTrue);
      });

      test('future end date means not expired', () {
        final expense = createExpense(
          endDate: DateTime.now().add(const Duration(days: 30)),
        );
        expect(expense.isExpired, isFalse);
      });
    });

    group('isExpiringSoon', () {
      test('no end date is not expiring soon', () {
        expect(createExpense().isExpiringSoon, isFalse);
      });

      test('end date within 30 days is expiring soon', () {
        final expense = createExpense(
          endDate: DateTime.now().add(const Duration(days: 15)),
        );
        expect(expense.isExpiringSoon, isTrue);
      });

      test('end date beyond 30 days is not expiring soon', () {
        final expense = createExpense(
          endDate: DateTime.now().add(const Duration(days: 60)),
        );
        expect(expense.isExpiringSoon, isFalse);
      });

      test('past end date is not expiring soon', () {
        final expense = createExpense(
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expense.isExpiringSoon, isFalse);
      });
    });

    group('daysUntilDue', () {
      test('returns days until next due date', () {
        final expense = createExpense();
        expect(expense.daysUntilDue, greaterThanOrEqualTo(4));
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        final original = createExpense();
        final modified = original.copyWith(name: 'Hulu', amount: 9.99);

        expect(modified.name, 'Hulu');
        expect(modified.amount, 9.99);
        expect(modified.id, original.id);
        expect(modified.categoryId, original.categoryId);
        expect(modified.provider, original.provider);
      });
    });
  });
}
