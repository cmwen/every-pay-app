import 'package:flutter/material.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';

class InsightsCard extends StatelessWidget {
  final String? biggestExpenseName;
  final double? biggestExpenseAmount;
  final int activeCount;
  final double averagePerSubscription;
  final String currency;

  const InsightsCard({
    super.key,
    this.biggestExpenseName,
    this.biggestExpenseAmount,
    required this.activeCount,
    required this.averagePerSubscription,
    this.currency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Insights',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (biggestExpenseName != null)
              _InsightRow(
                icon: Icons.monetization_on,
                text:
                    'Biggest: $biggestExpenseName ${biggestExpenseAmount?.formatCurrency(currency) ?? ''}',
              ),
            _InsightRow(
              icon: Icons.bar_chart,
              text: '$activeCount active subscription${activeCount == 1 ? '' : 's'}',
            ),
            if (activeCount > 0)
              _InsightRow(
                icon: Icons.calendar_today,
                text:
                    'Avg: ${averagePerSubscription.formatCurrency(currency)}/subscription',
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InsightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
