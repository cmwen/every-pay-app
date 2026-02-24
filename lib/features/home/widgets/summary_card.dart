import 'package:flutter/material.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/features/home/providers/home_summary.dart';

class SummaryCard extends StatelessWidget {
  final HomeSummary summary;

  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.monthlyTotal.formatCurrency(),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            if (summary.percentChange != null)
              Text(
                '${summary.percentChange! >= 0 ? '▲' : '▼'} '
                '${summary.percentChange!.abs().toStringAsFixed(1)}% vs last month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withAlpha(179),
                ),
              ),
            Text(
              '${summary.activeCount} active subscription${summary.activeCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
