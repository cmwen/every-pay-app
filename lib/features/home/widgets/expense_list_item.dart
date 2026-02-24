import 'package:flutter/material.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/core/extensions/date_extensions.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/expense.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseListItem({
    super.key,
    required this.expense,
    this.category,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = category;
    final catColor = cat != null
        ? categoryColor(cat.colour)
        : theme.colorScheme.primary;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: catColor.withAlpha(30),
        child: Icon(
          cat != null ? categoryIcon(cat.icon) : Icons.category,
          color: catColor,
          size: 20,
        ),
      ),
      title: Text(
        expense.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${cat?.name ?? 'Unknown'} · ${expense.billingCycle.displayName}'
        '${expense.nextDueDate != null ? '\n${expense.nextDueDate!.daysFromNow()}' : ''}',
      ),
      isThreeLine: expense.nextDueDate != null,
      trailing: Text(
        expense.amount.formatCurrency(expense.currency),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
