import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/confirm_dialog.dart';
import 'package:everypay/shared/widgets/empty_state.dart';
import 'package:everypay/shared/widgets/payment_method_avatar.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(allPaymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/settings/payment-methods/add'),
        tooltip: 'Add Payment Method',
        child: const Icon(Icons.add),
      ),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (methods) {
          if (methods.isEmpty) {
            return EmptyStateView(
              icon: Icons.credit_card,
              title: 'No payment methods yet.',
              subtitle:
                  'Assign a card, account, or wallet to your expenses to track how you pay for each subscription.',
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Payment Method'),
                onPressed: () => context.push('/settings/payment-methods/add'),
              ),
            );
          }

          return ListView.builder(
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return _PaymentMethodTile(method: method);
            },
          );
        },
      ),
    );
  }
}

class _PaymentMethodTile extends ConsumerWidget {
  final PaymentMethod method;

  const _PaymentMethodTile({required this.method});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(method.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmDelete(context, ref),
      onDismissed: (_) {},
      child: ListTile(
        leading: PaymentMethodAvatar(paymentMethod: method),
        title: Text(method.name),
        subtitle: Text(
          [
            method.type.displayName,
            if (method.bankName != null) method.bankName!,
            if (method.last4Digits != null) '••${method.last4Digits}',
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Default',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () =>
            context.push('/settings/payment-methods/${method.id}/edit'),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(paymentMethodRepositoryProvider);
    final count = await repo.countExpensesUsingPaymentMethod(method.id);

    if (!context.mounted) return false;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Payment Method',
      content: count > 0
          ? 'This payment method is assigned to $count expense${count == 1 ? '' : 's'}.\n'
                'Removing it will clear those assignments.'
          : 'Delete "${method.name}"?',
    );

    if (confirmed) {
      if (count > 0) {
        await repo.clearPaymentMethodFromExpenses(method.id);
      }
      await repo.deletePaymentMethod(method.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${method.name} deleted.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    return confirmed;
  }
}
