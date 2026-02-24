import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';

void main() {
  group('BillingCycle', () {
    group('monthlyMultiplier', () {
      test('weekly returns ~4.333', () {
        expect(BillingCycle.weekly.monthlyMultiplier(), closeTo(4.333, 0.001));
      });

      test('fortnightly returns ~2.167', () {
        expect(
          BillingCycle.fortnightly.monthlyMultiplier(),
          closeTo(2.167, 0.001),
        );
      });

      test('monthly returns 1.0', () {
        expect(BillingCycle.monthly.monthlyMultiplier(), 1.0);
      });

      test('quarterly returns ~0.333', () {
        expect(
          BillingCycle.quarterly.monthlyMultiplier(),
          closeTo(0.333, 0.001),
        );
      });

      test('biannual returns ~0.167', () {
        expect(
          BillingCycle.biannual.monthlyMultiplier(),
          closeTo(0.167, 0.001),
        );
      });

      test('yearly returns ~0.083', () {
        expect(BillingCycle.yearly.monthlyMultiplier(), closeTo(0.083, 0.001));
      });

      test('custom with 30 days returns ~1.014', () {
        expect(
          BillingCycle.custom.monthlyMultiplier(30),
          closeTo(365 / (30 * 12), 0.001),
        );
      });

      test('custom with null days returns 1.0', () {
        expect(BillingCycle.custom.monthlyMultiplier(), 1.0);
      });

      test('custom with 0 days returns 1.0 (safe fallback)', () {
        expect(BillingCycle.custom.monthlyMultiplier(0), 1.0);
      });
    });

    group('displayName', () {
      test('all cycles have display names', () {
        for (final cycle in BillingCycle.values) {
          expect(cycle.displayName, isNotEmpty);
        }
      });

      test('monthly displays Monthly', () {
        expect(BillingCycle.monthly.displayName, 'Monthly');
      });

      test('yearly displays Yearly', () {
        expect(BillingCycle.yearly.displayName, 'Yearly');
      });
    });

    group('typicalDays', () {
      test('weekly is 7', () {
        expect(BillingCycle.weekly.typicalDays, 7);
      });

      test('monthly is 30', () {
        expect(BillingCycle.monthly.typicalDays, 30);
      });

      test('yearly is 365', () {
        expect(BillingCycle.yearly.typicalDays, 365);
      });
    });
  });
}
