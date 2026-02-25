import 'package:everypay/domain/entities/expense.dart';

class MonthData {
  final int month; // 1-12
  final double amount;
  final bool isProjected;

  const MonthData({
    required this.month,
    required this.amount,
    this.isProjected = false,
  });
}

class YearlyStats {
  final int year;
  final double totalActual;
  final double totalProjected;
  final List<MonthData> months;
  final double monthlyAverage;
  final MonthData? highestMonth;
  final MonthData? lowestMonth;

  const YearlyStats({
    required this.year,
    required this.totalActual,
    required this.totalProjected,
    required this.months,
    required this.monthlyAverage,
    this.highestMonth,
    this.lowestMonth,
  });

  static YearlyStats compute({
    required List<Expense> expenses,
    required int year,
    required DateTime now,
  }) {
    final activeExpenses = expenses.where((e) => e.isActive).toList();
    final monthlyTotal = activeExpenses.fold<double>(
      0,
      (sum, e) => sum + e.monthlyCost,
    );

    final currentMonth = now.year == year ? now.month : 12;
    final months = <MonthData>[];
    double totalActual = 0;

    for (int m = 1; m <= 12; m++) {
      final isProjected = m > currentMonth;
      final amount = monthlyTotal; // Simplified: same cost each month
      months.add(MonthData(month: m, amount: amount, isProjected: isProjected));
      if (!isProjected) totalActual += amount;
    }

    final totalProjected = monthlyTotal * 12;

    final actualMonths = months.where((m) => !m.isProjected).toList();
    MonthData? highest, lowest;
    if (actualMonths.isNotEmpty) {
      highest = actualMonths.reduce((a, b) => a.amount >= b.amount ? a : b);
      lowest = actualMonths.reduce((a, b) => a.amount <= b.amount ? a : b);
    }

    return YearlyStats(
      year: year,
      totalActual: totalActual,
      totalProjected: totalProjected,
      months: months,
      monthlyAverage: monthlyTotal,
      highestMonth: highest,
      lowestMonth: lowest,
    );
  }
}
