import 'package:everypay/domain/entities/expense.dart';

class CategorySpend {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColour;
  final double amount;
  final double percentage;

  const CategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColour,
    required this.amount,
    required this.percentage,
  });
}

class MonthlyStats {
  final DateTime month;
  final double totalSpend;
  final List<CategorySpend> categoryBreakdown;
  final int activeCount;
  final String? biggestExpenseName;
  final double? biggestExpenseAmount;
  final double averagePerSubscription;

  const MonthlyStats({
    required this.month,
    required this.totalSpend,
    required this.categoryBreakdown,
    required this.activeCount,
    this.biggestExpenseName,
    this.biggestExpenseAmount,
    required this.averagePerSubscription,
  });

  static MonthlyStats compute({
    required List<Expense> expenses,
    required Map<String, ({String name, String icon, String colour})>
    categoryMap,
    required DateTime month,
  }) {
    final activeExpenses = expenses.where((e) => e.isActive).toList();

    final totalSpend = activeExpenses.fold<double>(
      0,
      (sum, e) => sum + e.monthlyCost,
    );

    // Group by category
    final categoryTotals = <String, double>{};
    for (final e in activeExpenses) {
      categoryTotals[e.categoryId] =
          (categoryTotals[e.categoryId] ?? 0) + e.monthlyCost;
    }

    final breakdown = categoryTotals.entries.map((entry) {
      final cat = categoryMap[entry.key];
      return CategorySpend(
        categoryId: entry.key,
        categoryName: cat?.name ?? 'Unknown',
        categoryIcon: cat?.icon ?? 'category',
        categoryColour: cat?.colour ?? '#546E7A',
        amount: entry.value,
        percentage: totalSpend > 0 ? (entry.value / totalSpend) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Find biggest
    Expense? biggest;
    for (final e in activeExpenses) {
      if (biggest == null || e.monthlyCost > biggest.monthlyCost) {
        biggest = e;
      }
    }

    return MonthlyStats(
      month: month,
      totalSpend: totalSpend,
      categoryBreakdown: breakdown,
      activeCount: activeExpenses.length,
      biggestExpenseName: biggest?.name,
      biggestExpenseAmount: biggest?.monthlyCost,
      averagePerSubscription: activeExpenses.isEmpty
          ? 0
          : totalSpend / activeExpenses.length,
    );
  }
}
