import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/core/extensions/date_extensions.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/empty_state.dart';
import 'package:everypay/features/stats/providers/monthly_stats_provider.dart';
import 'package:everypay/features/stats/providers/yearly_stats_provider.dart';
import 'package:everypay/features/stats/providers/upcoming_provider.dart';
import 'package:everypay/features/stats/widgets/category_pie_chart.dart';
import 'package:everypay/features/stats/widgets/monthly_bar_chart.dart';
import 'package:everypay/features/stats/widgets/insights_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
              Tab(text: 'Upcoming'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_MonthlyTab(), _YearlyTab(), _UpcomingTab()],
        ),
      ),
    );
  }
}

// Monthly tab with category pie chart
class _MonthlyTab extends ConsumerStatefulWidget {
  const _MonthlyTab();

  @override
  ConsumerState<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends ConsumerState<_MonthlyTab> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const EmptyStateView(
            icon: Icons.pie_chart,
            title: 'No expenses yet',
            subtitle: 'Add some subscriptions to see monthly stats.',
          );
        }

        final categoryMap =
            <String, ({String name, String icon, String colour})>{};
        final cats = switch (categoriesAsync) {
          AsyncData(:final value) => value,
          _ => <Category>[],
        };
        for (final c in cats) {
          categoryMap[c.id] = (name: c.name, icon: c.icon, colour: c.colour);
        }

        final stats = MonthlyStats.compute(
          expenses: expenses,
          categoryMap: categoryMap,
          month: _selectedMonth,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Month navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  DateFormat.yMMMM().format(_selectedMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Total
            Center(
              child: Text(
                stats.totalSpend.formatCurrency(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Center(
              child: Text(
                'per month',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pie chart
            Center(child: CategoryPieChart(data: stats.categoryBreakdown)),
            const SizedBox(height: 16),
            // Category legend
            ...stats.categoryBreakdown.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: categoryColor(c.categoryColour),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.categoryName)),
                    Text(c.amount.formatCurrency()),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${c.percentage.toStringAsFixed(0)}%',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Insights
            InsightsCard(
              biggestExpenseName: stats.biggestExpenseName,
              biggestExpenseAmount: stats.biggestExpenseAmount,
              activeCount: stats.activeCount,
              averagePerSubscription: stats.averagePerSubscription,
            ),
          ],
        );
      },
    );
  }
}

// Yearly tab with bar chart
class _YearlyTab extends ConsumerStatefulWidget {
  const _YearlyTab();

  @override
  ConsumerState<_YearlyTab> createState() => _YearlyTabState();
}

class _YearlyTabState extends ConsumerState<_YearlyTab> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const EmptyStateView(
            icon: Icons.bar_chart,
            title: 'No expenses yet',
            subtitle: 'Add some subscriptions to see yearly stats.',
          );
        }

        final stats = YearlyStats.compute(
          expenses: expenses,
          year: _selectedYear,
          now: DateTime.now(),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Year navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Text(
                  '$_selectedYear',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _selectedYear++),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Actual',
                    value: stats.totalActual.formatCurrency(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryChip(
                    label: 'Projected',
                    value: stats.totalProjected.formatCurrency(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Bar chart
            MonthlyBarChart(months: stats.months),
            const SizedBox(height: 16),
            _SummaryChip(
              label: 'Monthly Average',
              value: stats.monthlyAverage.formatCurrency(),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Upcoming tab — enhanced with 7/30-day toggle and UpcomingListItem
class _UpcomingTab extends ConsumerStatefulWidget {
  const _UpcomingTab();

  @override
  ConsumerState<_UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends ConsumerState<_UpcomingTab> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryMap = <String, Category>{};
    if (categoriesAsync is AsyncData<List<Category>>) {
      for (final c in categoriesAsync.value) {
        categoryMap[c.id] = c;
      }
    }

    return Column(
      children: [
        // Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('This Week')),
              ButtonSegment(value: 30, label: Text('This Month')),
            ],
            selected: {_days},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) setState(() => _days = set.first);
            },
          ),
        ),

        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (expenses) {
              final stats = UpcomingStats.compute(
                expenses: expenses,
                days: _days,
              );

              if (stats.groupedByDate.isEmpty) {
                return EmptyStateView(
                  icon: Icons.event,
                  title: 'No upcoming payments',
                  subtitle: 'Nothing due in the next $_days days!',
                );
              }

              final sortedDates = stats.groupedByDate.keys.toList()..sort();

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: ListView(
                  key: ValueKey(_days),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Next $_days Days',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stats.totalAmount.formatCurrency(),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...sortedDates.map((date) {
                      final payments = stats.groupedByDate[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              date.daysFromNow(),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                          ...payments.map(
                            (p) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payment),
                              title: Text(p.expense.name),
                              subtitle: Text(
                                p.expense.provider ??
                                    p.expense.billingCycle.displayName,
                              ),
                              trailing: Text(
                                p.expense.amount.formatCurrency(
                                  p.expense.currency,
                                ),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
