import 'dart:math';
import 'package:flutter/material.dart';
import 'package:everypay/features/stats/providers/yearly_stats_provider.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthData> months;
  final double height;

  const MonthlyBarChart({super.key, required this.months, this.height = 200});

  static const _monthLabels = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAmount = months.isEmpty
        ? 100.0
        : months.map((m) => m.amount).reduce(max);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(months.length, (index) {
          final month = months[index];
          final barHeight = maxAmount > 0
              ? (month.amount / maxAmount) * (height - 30)
              : 0.0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: month.isProjected
                        ? theme.colorScheme.primary.withAlpha(77)
                        : theme.colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_monthLabels[index], style: theme.textTheme.labelSmall),
              ],
            ),
          );
        }),
      ),
    );
  }
}
