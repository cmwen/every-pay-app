import 'package:flutter/material.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/shared/widgets/payment_method_avatar.dart';

/// Compact chip showing a payment method — used in expense list items and
/// the expense detail screen.
class PaymentMethodChip extends StatelessWidget {
  final PaymentMethod paymentMethod;

  const PaymentMethodChip({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          'Paid with ${paymentMethod.name}${paymentMethod.last4Digits != null ? ', ending ${paymentMethod.last4Digits}' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: PaymentMethodAvatar(
                paymentMethod: paymentMethod,
                size: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(paymentMethod.compactLabel, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
