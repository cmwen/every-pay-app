import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/core/extensions/currency_extensions.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/features/stats/providers/upcoming_provider.dart';
import 'package:everypay/features/upcoming/widgets/urgency_chip.dart';
import 'package:everypay/shared/widgets/payment_method_chip.dart';

/// A single item in the upcoming payments list.
/// Shows name, category, billing cycle, urgency chip, and optional PM chip.
class UpcomingListItem extends ConsumerWidget {
  final UpcomingPayment payment;
  final Category? category;
  final PaymentMethod? paymentMethod;
  final VoidCallback? onTap;

  const UpcomingListItem({
    super.key,
    required this.payment,
    this.category,
    this.paymentMethod,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cat = category;
    final catColor = cat != null
        ? categoryColor(cat.colour)
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: catColor.withAlpha(30),
                child: Icon(
                  cat != null ? categoryIcon(cat.icon) : Icons.category,
                  color: catColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + amount row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            payment.expense.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 3),
                    // Category · cycle
                    Text(
                      '${cat?.name ?? 'Unknown'} · ${payment.expense.billingCycle.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Urgency chip + PM chip
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        UrgencyChip(dueDate: payment.dueDate),
                        if (paymentMethod != null)
                          PaymentMethodChip(paymentMethod: paymentMethod!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
