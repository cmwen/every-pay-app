import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/utils/billing_calculator.dart';
import 'package:everypay/core/utils/id_generator.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/expense_status.dart';
import 'package:everypay/features/expense/widgets/expense_form.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class AddExpenseScreen extends ConsumerWidget {
  final Expense? prefilled;

  const AddExpenseScreen({super.key, this.prefilled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ExpenseForm(
        initialExpense: prefilled,
        onSave: (formData) async {
          final now = DateTime.now();
          final cycle = formData.billingCycle;
          final startDate = formData.startDate;

          final expense = Expense(
            id: generateId(),
            name: formData.name,
            provider: formData.provider,
            categoryId: formData.categoryId,
            amount: formData.amount,
            currency: formData.currency,
            billingCycle: cycle,
            customDays: formData.customDays,
            startDate: startDate,
            endDate: formData.endDate,
            nextDueDate: BillingCalculator.calculateNextDueDate(
              startDate,
              cycle,
              customDays: formData.customDays,
            ),
            status: ExpenseStatus.active,
            notes: formData.notes,
            tags: formData.tags,
            createdAt: now,
            updatedAt: now,
            deviceId: 'local',
          );

          await ref.read(expenseRepositoryProvider).upsertExpense(expense);
          if (context.mounted) context.pop();
        },
        onLibrary: () => context.go('/expense/add/library'),
      ),
    );
  }
}
