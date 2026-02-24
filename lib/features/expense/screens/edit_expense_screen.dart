import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/utils/billing_calculator.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/features/expense/widgets/expense_form.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class EditExpenseScreen extends ConsumerWidget {
  final String id;

  const EditExpenseScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Expense?>(
      future: ref.watch(expenseRepositoryProvider).getExpenseById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final expense = snapshot.data;
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Expense not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Expense')),
          body: ExpenseForm(
            initialExpense: expense,
            onSave: (formData) async {
              final updated = expense.copyWith(
                name: formData.name,
                provider: formData.provider,
                categoryId: formData.categoryId,
                amount: formData.amount,
                currency: formData.currency,
                billingCycle: formData.billingCycle,
                customDays: formData.customDays,
                startDate: formData.startDate,
                endDate: formData.endDate,
                nextDueDate: BillingCalculator.calculateNextDueDate(
                  formData.startDate,
                  formData.billingCycle,
                  customDays: formData.customDays,
                ),
                notes: formData.notes,
                tags: formData.tags,
                updatedAt: DateTime.now(),
              );

              await ref.read(expenseRepositoryProvider).upsertExpense(updated);
              if (context.mounted) context.pop();
            },
          ),
        );
      },
    );
  }
}
