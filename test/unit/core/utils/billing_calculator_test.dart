import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/core/utils/billing_calculator.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';

void main() {
  group('BillingCalculator', () {
    group('calculateNextDueDate', () {
      test('monthly cycle returns next month from start', () {
        final start = DateTime(2026, 1, 15);
        final relativeTo = DateTime(2026, 2, 10);
        final next = BillingCalculator.calculateNextDueDate(
          start,
          BillingCycle.monthly,
          relativeTo: relativeTo,
        );
        expect(next, DateTime(2026, 2, 15));
      });

      test('returns date after today when start is in the past', () {
        final start = DateTime(2024, 1, 1);
        final relativeTo = DateTime(2026, 2, 24);
        final next = BillingCalculator.calculateNextDueDate(
          start,
          BillingCycle.monthly,
          relativeTo: relativeTo,
        );
        expect(next.isAfter(relativeTo), isTrue);
      });

      test('weekly cycle advances by 7 days', () {
        final start = DateTime(2026, 2, 1);
        final relativeTo = DateTime(2026, 2, 10);
        final next = BillingCalculator.calculateNextDueDate(
          start,
          BillingCycle.weekly,
          relativeTo: relativeTo,
        );
        // Feb 1 + 7 = Feb 8, + 7 = Feb 15 (first after Feb 10)
        expect(next, DateTime(2026, 2, 15));
      });

      test('yearly cycle advances by 1 year', () {
        final start = DateTime(2024, 6, 15);
        final relativeTo = DateTime(2026, 2, 24);
        final next = BillingCalculator.calculateNextDueDate(
          start,
          BillingCycle.yearly,
          relativeTo: relativeTo,
        );
        expect(next, DateTime(2026, 6, 15));
      });

      test('custom cycle uses custom days', () {
        final start = DateTime(2026, 2, 1);
        final relativeTo = DateTime(2026, 2, 10);
        final next = BillingCalculator.calculateNextDueDate(
          start,
          BillingCycle.custom,
          customDays: 15,
          relativeTo: relativeTo,
        );
        // Feb 1 + 15 = Feb 16 (first after Feb 10)
        expect(next, DateTime(2026, 2, 16));
      });
    });

    group('calculateTotalPaid', () {
      test('monthly for 12 months', () {
        final start = DateTime(2025, 2, 1);
        final relativeTo = DateTime(2026, 2, 2);
        final total = BillingCalculator.calculateTotalPaid(
          start,
          10.0,
          BillingCycle.monthly,
          relativeTo: relativeTo,
        );
        // Feb 1 2025 through Feb 1 2026 = 13 payment dates before Feb 2 2026
        expect(total, closeTo(130.0, 0.01));
      });

      test('returns 0 for future start date', () {
        final start = DateTime(2030, 1, 1);
        final total = BillingCalculator.calculateTotalPaid(
          start,
          10.0,
          BillingCycle.monthly,
        );
        expect(total, 0.0);
      });
    });

    group('paymentCount', () {
      test('monthly for 3 months', () {
        final start = DateTime(2026, 1, 1);
        final relativeTo = DateTime(2026, 3, 15);
        final count = BillingCalculator.paymentCount(
          start,
          BillingCycle.monthly,
          relativeTo: relativeTo,
        );
        expect(count, 3); // Jan 1, Feb 1, Mar 1
      });

      test('returns 0 for future start', () {
        final start = DateTime(2030, 1, 1);
        final count = BillingCalculator.paymentCount(
          start,
          BillingCycle.monthly,
        );
        expect(count, 0);
      });
    });
  });
}
