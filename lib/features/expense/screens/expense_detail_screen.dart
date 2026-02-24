import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/core/extensions/date_extensions.dart';
import 'package:everypay/core/utils/billing_calculator.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/confirm_dialog.dart';
import 'package:everypay/shared/widgets/status_badge.dart';
import 'package:everypay/domain/enums/expense_status.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String id;

  const ExpenseDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<Expense?>(
      future: ref.watch(expenseRepositoryProvider).getExpenseById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final expense = snapshot.data;
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Expense not found')),
          );
        }

        return FutureBuilder<Category?>(
          future: ref
              .watch(categoryRepositoryProvider)
              .getCategoryById(expense.categoryId),
          builder: (context, catSnapshot) {
            final category = catSnapshot.data;

            return Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.go('/expense/$id/edit'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Delete Expense',
                        content:
                            'Are you sure you want to delete "${expense.name}"?',
                      );
                      if (confirmed && context.mounted) {
                        await ref
                            .read(expenseRepositoryProvider)
                            .deleteExpense(id);
                        if (context.mounted) context.pop();
                      }
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    if (category != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: categoryColor(
                              category.colour,
                            ).withAlpha(30),
                            child: Icon(
                              categoryIcon(category.icon),
                              color: categoryColor(category.colour),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (expense.provider != null)
                                  Text(
                                    expense.provider!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Amount card
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              '${expense.amount.formatCurrency(expense.currency)}/mo',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${expense.yearlyCost.formatCurrency(expense.currency)} projected/year',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withAlpha(179),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StatusBadge(status: expense.status),
                                if (expense.nextDueDate != null) ...[
                                  const SizedBox(width: 16),
                                  Text(
                                    'Due ${expense.nextDueDate!.shortFormatted}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withAlpha(179),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Details
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _detailRow('Category', category?.name ?? 'Unknown'),
                            _detailRow(
                              'Cycle',
                              expense.billingCycle.displayName,
                            ),
                            _detailRow(
                              'Start Date',
                              expense.startDate.formatted,
                            ),
                            _detailRow(
                              'End Date',
                              expense.endDate?.formatted ?? '—',
                            ),
                            _detailRow(
                              'Total Paid',
                              '${BillingCalculator.calculateTotalPaid(expense.startDate, expense.amount, expense.billingCycle, customDays: expense.customDays).formatCurrency(expense.currency)} '
                                  '(${BillingCalculator.paymentCount(expense.startDate, expense.billingCycle, customDays: expense.customDays)} payments)',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Notes
                    if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Notes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(expense.notes!),
                        ),
                      ),
                    ],

                    // Tags
                    if (expense.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tags',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: expense.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Actions
                    if (expense.status == ExpenseStatus.active)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.pause),
                              label: const Text('Pause'),
                              onPressed: () async {
                                final updated = expense.copyWith(
                                  status: ExpenseStatus.paused,
                                  updatedAt: DateTime.now(),
                                );
                                await ref
                                    .read(expenseRepositoryProvider)
                                    .upsertExpense(updated);
                                if (context.mounted) context.pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                final updated = expense.copyWith(
                                  status: ExpenseStatus.cancelled,
                                  endDate: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                                await ref
                                    .read(expenseRepositoryProvider)
                                    .upsertExpense(updated);
                                if (context.mounted) context.pop();
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
