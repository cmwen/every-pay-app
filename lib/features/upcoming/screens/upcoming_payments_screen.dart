import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/features/stats/providers/upcoming_provider.dart';
import 'package:everypay/features/upcoming/providers/upcoming_payments_provider.dart';
import 'package:everypay/features/upcoming/widgets/upcoming_list_item.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/empty_state.dart';

class UpcomingPaymentsScreen extends ConsumerStatefulWidget {
  const UpcomingPaymentsScreen({super.key});

  @override
  ConsumerState<UpcomingPaymentsScreen> createState() =>
      _UpcomingPaymentsScreenState();
}

class _UpcomingPaymentsScreenState
    extends ConsumerState<UpcomingPaymentsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final upcomingAsync = ref.watch(upcomingPaymentsProvider(_days));
    final categoriesAsync = ref.watch(categoriesProvider);
    final methodsAsync = ref.watch(allPaymentMethodsProvider);

    final categoryMap = <String, Category>{};
    if (categoriesAsync is AsyncData<List<Category>>) {
      for (final c in categoriesAsync.value) {
        categoryMap[c.id] = c;
      }
    }

    final methodMap = <String, PaymentMethod>{};
    if (methodsAsync is AsyncData<List<PaymentMethod>>) {
      for (final m in methodsAsync.value) {
        methodMap[m.id] = m;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Payments')),
      body: Column(
        children: [
          // Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 7,
                  label: Text('This Week'),
                  icon: Icon(Icons.view_week),
                ),
                ButtonSegment(
                  value: 30,
                  label: Text('This Month'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_days},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) setState(() => _days = set.first);
              },
            ),
          ),

          // Content
          Expanded(
            child: upcomingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (stats) {
                if (stats.groupedByDate.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.event_available,
                    title: 'Nothing due in the next $_days days',
                    subtitle: _days == 7
                        ? 'Your week looks clear. Switch to "This Month" to see further ahead.'
                        : 'No payments scheduled in the next 30 days.',
                  );
                }

                return _UpcomingList(
                  stats: stats,
                  days: _days,
                  categoryMap: categoryMap,
                  methodMap: methodMap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingList extends ConsumerWidget {
  final UpcomingStats stats;
  final int days;
  final Map<String, Category> categoryMap;
  final Map<String, PaymentMethod> methodMap;

  const _UpcomingList({
    required this.stats,
    required this.days,
    required this.categoryMap,
    required this.methodMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sortedDates = stats.groupedByDate.keys.toList()..sort();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: ListView(
        key: ValueKey(days),
        children: [
          // Period summary card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Semantics(
              label:
                  'Total due in next $days days: ${stats.totalAmount.formatCurrency()}',
              child: Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${stats.groupedByDate.values.fold<int>(0, (sum, list) => sum + list.length)} '
                        'payment${stats.groupedByDate.values.fold<int>(0, (sum, list) => sum + list.length) == 1 ? '' : 's'} '
                        'due in next $days days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.totalAmount.formatCurrency(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Date groups
          for (final date in sortedDates) ...[
            _DateGroupHeader(date: date),
            ...stats.groupedByDate[date]!.map((payment) {
              return UpcomingListItem(
                payment: payment,
                category: categoryMap[payment.expense.categoryId],
                paymentMethod: payment.expense.paymentMethodId != null
                    ? methodMap[payment.expense.paymentMethodId]
                    : null,
                onTap: () => context.push('/expense/${payment.expense.id}'),
              );
            }),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  final DateTime date;

  const _DateGroupHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    final String label;
    if (diff == 0) {
      label = 'TODAY, ${DateFormat('EEE MMM d').format(date).toUpperCase()}';
    } else if (diff == 1) {
      label = 'TOMORROW, ${DateFormat('EEE MMM d').format(date).toUpperCase()}';
    } else {
      label = DateFormat('EEE MMM d').format(date);
    }

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
