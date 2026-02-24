import 'package:everypay/domain/entities/expense.dart';

class HomeSummary {
  final double monthlyTotal;
  final int activeCount;
  final double? previousMonthTotal;

  const HomeSummary({
    required this.monthlyTotal,
    required this.activeCount,
    this.previousMonthTotal,
  });

  double? get percentChange {
    if (previousMonthTotal == null || previousMonthTotal == 0) return null;
    return ((monthlyTotal - previousMonthTotal!) / previousMonthTotal!) * 100;
  }

  static HomeSummary compute(List<Expense> expenses) {
    final activeExpenses = expenses.where((e) => e.isActive).toList();

    final monthlyTotal = activeExpenses.fold<double>(
      0,
      (sum, e) => sum + e.monthlyCost,
    );

    return HomeSummary(
      monthlyTotal: monthlyTotal,
      activeCount: activeExpenses.length,
    );
  }
}
