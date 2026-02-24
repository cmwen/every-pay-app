import 'package:everypay/core/utils/billing_calculator.dart';
import 'package:everypay/domain/entities/expense.dart';

class UpcomingPayment {
  final Expense expense;
  final DateTime dueDate;

  const UpcomingPayment({required this.expense, required this.dueDate});
}

class UpcomingStats {
  final double totalAmount;
  final Map<DateTime, List<UpcomingPayment>> groupedByDate;

  const UpcomingStats({
    required this.totalAmount,
    required this.groupedByDate,
  });

  static UpcomingStats compute({
    required List<Expense> expenses,
    required int days,
    DateTime? relativeTo,
  }) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.add(Duration(days: days));

    final upcoming = <UpcomingPayment>[];

    for (final expense in expenses) {
      if (!expense.isActive) continue;

      var dueDate = BillingCalculator.calculateNextDueDate(
        expense.startDate,
        expense.billingCycle,
        customDays: expense.customDays,
        relativeTo: now,
      );

      // Collect all due dates within the window
      while (!dueDate.isAfter(cutoff)) {
        upcoming.add(UpcomingPayment(expense: expense, dueDate: dueDate));
        dueDate = BillingCalculator.calculateNextDueDate(
          dueDate,
          expense.billingCycle,
          customDays: expense.customDays,
          relativeTo: dueDate,
        );
      }
    }

    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final totalAmount =
        upcoming.fold<double>(0, (sum, p) => sum + p.expense.amount);

    // Group by date
    final grouped = <DateTime, List<UpcomingPayment>>{};
    for (final payment in upcoming) {
      final dateKey = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(payment);
    }

    return UpcomingStats(
      totalAmount: totalAmount,
      groupedByDate: grouped,
    );
  }
}
