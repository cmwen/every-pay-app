import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/payment_method_avatar.dart';

/// Opens a modal bottom sheet to select a payment method.
/// Returns the selected [PaymentMethod] or null (to clear selection).
Future<PaymentMethod?> showPaymentMethodPicker(
  BuildContext context,
  WidgetRef ref, {
  required String? currentId,
}) async {
  return showModalBottomSheet<PaymentMethod?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PaymentMethodPickerSheet(currentId: currentId),
  );
}

class _PaymentMethodPickerSheet extends ConsumerWidget {
  final String? currentId;

  const _PaymentMethodPickerSheet({this.currentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(allPaymentMethodsProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Clear selection
                  if (currentId != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: methodsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (methods) {
                  if (methods.isEmpty) {
                    return _EmptyMethodsState();
                  }
                  return ListView(
                    controller: scrollController,
                    children: [
                      ...methods.map((method) {
                        final isSelected = method.id == currentId;
                        return ListTile(
                          leading: PaymentMethodAvatar(paymentMethod: method),
                          title: Text(method.name),
                          subtitle: Text(
                            [
                              method.type.displayName,
                              if (method.bankName != null) method.bankName!,
                              if (method.last4Digits != null)
                                '••${method.last4Digits}',
                            ].join(' · '),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(method),
                        );
                      }),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.add,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: const Text('Add new payment method'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/settings/payment-methods/add');
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyMethodsState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.credit_card,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No payment methods set up yet.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add one in Settings to assign it to your expenses.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/settings/payment-methods/add');
            },
            child: const Text('Go to Settings → Payment Methods'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
