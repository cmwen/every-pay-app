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
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SummaryCard(summary: summary),
                ),
                const DueSoonSection(),
                const Expanded(
                  child: EmptyStateView(
                    icon: Icons.celebration,
                    title: 'No expenses yet!',
                    subtitle:
                        'Tap + to add your first subscription or recurring expense.',
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
                child: SummaryCard(summary: summary),
              ),
              const DueSoonSection(),
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
                      expense: expense,
                      category: category,
                      paymentMethod: paymentMethod,
                      onTap: () => context.go('/expense/${expense.id}'),
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
        onPressed: () => context.go('/expense/add'),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
