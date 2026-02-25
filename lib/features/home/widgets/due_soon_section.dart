import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/features/stats/providers/upcoming_provider.dart';
import 'package:everypay/features/upcoming/providers/upcoming_payments_provider.dart';
import 'package:everypay/features/upcoming/widgets/urgency_chip.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

/// Inline "Due Soon" section shown between the Summary Card and Filter Chips on Home.
/// Only rendered when there are expenses due within 7 days (or a hint for 30-day items).
class DueSoonSection extends ConsumerWidget {
  const DueSoonSection({super.key});

  static const int _maxItems = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(upcomingPaymentsProvider(7));
    final monthAsync = ref.watch(upcomingPaymentsProvider(30));
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryMap = <String, Category>{};
    if (categoriesAsync is AsyncData<List<Category>>) {
      for (final c in categoriesAsync.value) {
        categoryMap[c.id] = c;
      }
    }

    return weekAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (weekStats) {
        // Count total items in 7-day window
        final weekItems =
            weekStats.groupedByDate.values.expand((list) => list).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        // Nothing in 7 days — check 30 days for collapsed hint
        if (weekItems.isEmpty) {
          return monthAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (monthStats) {
              final monthCount = monthStats.groupedByDate.values.fold<int>(
                0,
                (sum, l) => sum + l.length,
              );
              if (monthCount == 0) return const SizedBox.shrink();
              return _DueSoonCard(isEmpty: true, monthCount: monthCount);
            },
          );
        }

        final visibleItems = weekItems.take(_maxItems).toList();
        final totalCount = weekItems.length;

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
          child: _DueSoonCard(
            isEmpty: false,
            totalCount: totalCount,
            visibleItems: visibleItems,
            categoryMap: categoryMap,
          ),
        );
      },
    );
  }
}

class _DueSoonCard extends StatelessWidget {
  final bool isEmpty;
  final int? monthCount;
  final int? totalCount;
  final List<UpcomingPayment> visibleItems;
  final Map<String, Category> categoryMap;

  const _DueSoonCard({
    required this.isEmpty,
    this.monthCount,
    this.totalCount,
    this.visibleItems = const [],
    this.categoryMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final seeAllLabel = (totalCount != null && totalCount! > 3)
        ? 'See all ($totalCount)'
        : 'See all';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Semantics(
        label: isEmpty
            ? 'Due soon — nothing due this week, $monthCount due this month'
            : 'Due soon — $totalCount expense${totalCount == 1 ? '' : 's'} due in the next 7 days',
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: cs.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due Soon',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'View all upcoming payments',
                      child: TextButton(
                        onPressed: () => context.push('/upcoming'),
                        child: Text(seeAllLabel),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, indent: 16),

              // Collapsed hint variant
              if (isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: cs.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nothing due this week',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '$monthCount payment${monthCount == 1 ? '' : 's'} due this month',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Item rows
              if (!isEmpty)
                ...visibleItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final payment = entry.value;
                  final cat = categoryMap[payment.expense.categoryId];
                  return _DueSoonItem(
                    payment: payment,
                    category: cat,
                    showDivider: i < visibleItems.length - 1,
                  );
                }),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueSoonItem extends StatelessWidget {
  final UpcomingPayment payment;
  final Category? category;
  final bool showDivider;

  const _DueSoonItem({
    required this.payment,
    this.category,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = category;
    final catColor = cat != null
        ? categoryColor(cat.colour)
        : theme.colorScheme.primary;

    return InkWell(
      onTap: () => context.push('/expense/${payment.expense.id}'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Category avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: catColor.withAlpha(30),
                  child: Icon(
                    cat != null ? categoryIcon(cat.icon) : Icons.category,
                    color: catColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),

                // Name + urgency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.expense.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      UrgencyChip(dueDate: payment.dueDate),
                    ],
                  ),
                ),

                // Amount
                Text(
                  payment.expense.amount.formatCurrency(
                    payment.expense.currency,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              indent: 44,
              endIndent: 12,
              color: theme.colorScheme.outlineVariant,
            ),
        ],
      ),
    );
  }
}
