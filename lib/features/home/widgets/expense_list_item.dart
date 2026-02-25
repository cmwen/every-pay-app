import 'package:flutter/material.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/core/extensions/date_extensions.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/shared/widgets/payment_method_chip.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final PaymentMethod? paymentMethod;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseListItem({
    super.key,
    required this.expense,
    this.category,
    this.paymentMethod,
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

    // Build subtitle text
    final subtitleLine =
        '${cat?.name ?? 'Unknown'} · ${expense.billingCycle.displayName}'
        '${expense.nextDueDate != null ? '\n${expense.nextDueDate!.daysFromNow()}${paymentMethod != null ? '' : ''}' : ''}';

    if (paymentMethod != null && expense.nextDueDate != null) {
      // 3-line with PM chip inline on the due-date line
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
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cat?.name ?? 'Unknown'} · ${expense.billingCycle.displayName}',
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  expense.nextDueDate!.daysFromNow(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                PaymentMethodChip(paymentMethod: paymentMethod!),
              ],
            ),
          ],
        ),
        isThreeLine: true,
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
      subtitle: Text(subtitleLine),
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
