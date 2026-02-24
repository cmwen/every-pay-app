import 'package:everypay/domain/enums/billing_cycle.dart';

class BillingCalculator {
  const BillingCalculator._();

  /// Calculate the next due date from a start date and billing cycle.
  static DateTime calculateNextDueDate(
    DateTime startDate,
    BillingCycle cycle, {
    int? customDays,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var nextDue = DateTime(startDate.year, startDate.month, startDate.day);

    while (nextDue.isBefore(today) || nextDue.isAtSameMomentAs(today)) {
      nextDue = _addCycle(nextDue, cycle, customDays);
    }

    return nextDue;
  }

  static DateTime _addCycle(
    DateTime date,
    BillingCycle cycle,
    int? customDays,
  ) {
    return switch (cycle) {
      BillingCycle.weekly => date.add(const Duration(days: 7)),
      BillingCycle.fortnightly => date.add(const Duration(days: 14)),
      BillingCycle.monthly => DateTime(date.year, date.month + 1, date.day),
      BillingCycle.quarterly => DateTime(date.year, date.month + 3, date.day),
      BillingCycle.biannual => DateTime(date.year, date.month + 6, date.day),
      BillingCycle.yearly => DateTime(date.year + 1, date.month, date.day),
      BillingCycle.custom => date.add(Duration(days: customDays ?? 30)),
    };
  }

  /// Calculate total amount paid from start date to now.
  static double calculateTotalPaid(
    DateTime startDate,
    double amount,
    BillingCycle cycle, {
    int? customDays,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    var date = DateTime(startDate.year, startDate.month, startDate.day);
    int count = 0;

    while (date.isBefore(now)) {
      count++;
      date = _addCycle(date, cycle, customDays);
    }

    return count * amount;
  }

  /// Number of payment occurrences from start date to now.
  static int paymentCount(
    DateTime startDate,
    BillingCycle cycle, {
    int? customDays,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    var date = DateTime(startDate.year, startDate.month, startDate.day);
    int count = 0;

    while (date.isBefore(now)) {
      count++;
      date = _addCycle(date, cycle, customDays);
    }

    return count;
  }
}
