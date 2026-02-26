import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/features/home/providers/expense_list_provider.dart';
import 'package:everypay/features/home/providers/home_summary.dart';
import 'package:everypay/features/home/widgets/due_soon_section.dart';
import 'package:everypay/features/home/widgets/summary_card.dart';
import 'package:everypay/features/home/widgets/expense_list_item.dart';
import 'package:everypay/features/home/widgets/filter_chips.dart';
import 'package:everypay/features/demo/providers/demo_mode_provider.dart';
import 'package:everypay/features/demo/widgets/tour_step_config.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final demoState = ref.watch(demoModeProvider);
    final registry = TourTargetRegistry.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Every-Pay')),
      body: expensesAsync.when(
        data: (expenses) {
          final categories = switch (categoriesAsync) {
            AsyncData(:final value) => value,
            _ => <Category>[],
          };
          final categoryMap = {for (final c in categories) c.id: c};

          final methodsAsync = ref.watch(allPaymentMethodsProvider);
          final methods = switch (methodsAsync) {
            AsyncData(:final value) => value,
            _ => <PaymentMethod>[],
          };
          final methodMap = {for (final m in methods) m.id: m};

          final summary = HomeSummary.compute(expenses);

          if (expenses.isEmpty) {
            final filter = ref.watch(expenseFilterProvider);
            final hasActiveFilter =
                filter.categoryId != null || filter.paymentMethodId != null;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SummaryCard(summary: summary),
                ),
                const DueSoonSection(),
                if (hasActiveFilter) const FilterChips(),
                Expanded(
                  child: hasActiveFilter
                      ? EmptyStateView(
                          icon: Icons.filter_list_off,
                          title: 'No results',
                          subtitle: 'No expenses match the selected filter.',
                          action: TextButton.icon(
                            onPressed: () => ref
                                .read(expenseFilterProvider.notifier)
                                .setFilter(const ExpenseFilter()),
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear filter'),
                          ),
                        )
                      : EmptyStateView(
                          icon: Icons.celebration,
                          title: 'No expenses yet!',
                          subtitle:
                              'Tap + to add your first subscription or recurring expense.',
                          action: demoState.isActive
                              ? null
                              : FilledButton.tonal(
                                  onPressed: () => ref
                                      .read(demoModeProvider.notifier)
                                      .activate(),
                                  child: const Text('Try Demo'),
                                ),
                        ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SummaryCard(
                  key: registry.summaryCardKey,
                  summary: summary,
                ),
              ),
              DueSoonSection(key: registry.dueSoonKey),
              const FilterChips(),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.separated(
                  itemCount: expenses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final category = categoryMap[expense.categoryId];
                    final paymentMethod = expense.paymentMethodId != null
                        ? methodMap[expense.paymentMethodId]
                        : null;
                    return ExpenseListItem(
                      key: index == 0 ? registry.firstExpenseKey : null,
                      expense: expense,
                      category: category,
                      paymentMethod: paymentMethod,
                      onTap: () {
                        if (demoState.isActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Detail view is read-only in demo mode',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        context.go('/expense/${expense.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        key: registry.fabKey,
        onPressed: () {
          if (demoState.isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Adding expenses is disabled in demo mode'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          context.go('/expense/add');
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
