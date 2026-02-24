import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/utils/billing_calculator.dart';
import 'package:everypay/core/utils/id_generator.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/service_template.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';
import 'package:everypay/features/expense/widgets/expense_form.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? prefilled;

  const AddExpenseScreen({super.key, this.prefilled});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  Expense? _prefilled;

  @override
  void initState() {
    super.initState();
    _prefilled = widget.prefilled;
  }

  Future<void> _openLibrary() async {
    final template =
        await context.push<ServiceTemplate>('/expense/add/library');
    if (template != null && mounted) {
      setState(() {
        // Convert template to a lightweight Expense for pre-filling the form.
        final now = DateTime.now();
        _prefilled = Expense(
          id: '',
          name: template.name,
          provider: template.provider,
          categoryId: template.defaultCategoryId,
          amount: template.suggestedAmount ?? 0,
          currency: 'USD',
          billingCycle: BillingCycle.values.firstWhere(
            (c) => c.name == template.defaultBillingCycle,
            orElse: () => BillingCycle.monthly,
          ),
          startDate: now,
          status: ExpenseStatus.active,
          createdAt: now,
          updatedAt: now,
          deviceId: 'local',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ExpenseForm(
        key: ValueKey(_prefilled?.name),
        initialExpense: _prefilled,
        onSave: (formData) async {
          final now = DateTime.now();
          final cycle = formData.billingCycle;
          final startDate = formData.startDate ?? now;

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
        onLibrary: _openLibrary,
      ),
    );
  }
}
