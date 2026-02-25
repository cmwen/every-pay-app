import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/core/constants/app_constants.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/features/expense/widgets/payment_method_picker.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/payment_method_avatar.dart';

class ExpenseFormData {
  final String name;
  final String? provider;
  final String categoryId;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final int? customDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final List<String> tags;
  final String? paymentMethodId;

  const ExpenseFormData({
    required this.name,
    this.provider,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    this.customDays,
    this.startDate,
    this.endDate,
    this.notes,
    this.tags = const [],
    this.paymentMethodId,
  });
}

class ExpenseForm extends ConsumerStatefulWidget {
  final Expense? initialExpense;
  final Future<void> Function(ExpenseFormData) onSave;
  final VoidCallback? onLibrary;

  const ExpenseForm({
    super.key,
    this.initialExpense,
    required this.onSave,
    this.onLibrary,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _providerController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagController;

  late String _categoryId;
  late String _currency;
  late BillingCycle _billingCycle;
  int? _customDays;
  DateTime? _startDate;
  DateTime? _endDate;
  late List<String> _tags;
  String? _paymentMethodId;
  PaymentMethod? _selectedPaymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    _nameController = TextEditingController(text: e?.name ?? '');
    _providerController = TextEditingController(text: e?.provider ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _tagController = TextEditingController();

    _categoryId = e?.categoryId ?? defaultCategories.first.id;
    _currency = e?.currency ?? AppConstants.defaultCurrency;
    _billingCycle = e?.billingCycle ?? BillingCycle.monthly;
    _customDays = e?.customDays;
    _startDate = e?.startDate;
    _endDate = e?.endDate;
    _tags = e?.tags.toList() ?? [];
    _paymentMethodId = e?.paymentMethodId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    // Load the selected payment method name when it changes
    if (_paymentMethodId != null && _selectedPaymentMethod == null) {
      ref.watch(allPaymentMethodsProvider).whenData((methods) {
        final found = methods.where((m) => m.id == _paymentMethodId);
        if (found.isNotEmpty && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedPaymentMethod = found.first);
            }
          });
        }
      });
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Library shortcut
          if (widget.onLibrary != null) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.library_books),
              label: const Text('Choose from library'),
              onPressed: widget.onLibrary,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or enter manually'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // Provider
          TextFormField(
            controller: _providerController,
            decoration: const InputDecoration(labelText: 'Provider'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Category
          categoriesAsync.when(
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          Icon(
                            categoryIcon(c.icon),
                            size: 18,
                            color: categoryColor(c.colour),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoryId = v);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Error loading categories'),
          ),
          const SizedBox(height: 16),

          // Amount & Currency
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount *'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(v);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                    DropdownMenuItem(value: 'CAD', child: Text('CAD')),
                    DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                    DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Billing Cycle
          const Text('Billing Cycle *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BillingCycle.values.map((cycle) {
              return ChoiceChip(
                label: Text(cycle.displayName),
                selected: _billingCycle == cycle,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _billingCycle = cycle);
                  }
                },
              );
            }).toList(),
          ),

          // Custom days
          if (_billingCycle == BillingCycle.custom) ...[
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Custom interval (days)',
              ),
              keyboardType: TextInputType.number,
              initialValue: _customDays?.toString(),
              validator: (v) {
                if (_billingCycle == BillingCycle.custom) {
                  if (v == null || v.isEmpty) {
                    return 'Required for custom cycle';
                  }
                  final days = int.tryParse(v);
                  if (days == null || days <= 0) return 'Enter valid days';
                }
                return null;
              },
              onChanged: (v) => _customDays = int.tryParse(v),
            ),
          ],
          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start Date',
                  value: _startDate,
                  onChanged: (d) => setState(() => _startDate = d),
                  allowClear: true,
                  onClear: () => setState(() => _startDate = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'End Date',
                  value: _endDate,
                  onChanged: (d) => setState(() => _endDate = d),
                  allowClear: true,
                  onClear: () => setState(() => _endDate = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Payment Method picker
          _PaymentMethodField(
            selectedMethod: _selectedPaymentMethod,
            onTap: () async {
              final selected = await showPaymentMethodPicker(
                context,
                ref,
                currentId: _paymentMethodId,
              );
              // null return means "clear" only when explicitly clearing
              // (the picker returns null for both close and clear — we
              //  distinguish by checking if currently set)
              if (mounted) {
                setState(() {
                  _selectedPaymentMethod = selected;
                  _paymentMethodId = selected?.id;
                });
              }
            },
            onClear: () => setState(() {
              _selectedPaymentMethod = null;
              _paymentMethodId = null;
            }),
          ),
          const SizedBox(height: 16),

          // Tags
          Wrap(
            spacing: 8,
            children: [
              ..._tags.map(
                (tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Add tag',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    final tag = value.trim().toLowerCase();
                    if (tag.isNotEmpty && !_tags.contains(tag)) {
                      setState(() {
                        _tags.add(tag);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Save button
          FilledButton(
            onPressed: _saving ? null : _onSave,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Expense'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.onSave(
        ExpenseFormData(
          name: _nameController.text.trim(),
          provider: _providerController.text.trim().isEmpty
              ? null
              : _providerController.text.trim(),
          categoryId: _categoryId,
          amount: double.parse(_amountController.text.trim()),
          currency: _currency,
          billingCycle: _billingCycle,
          customDays: _customDays,
          startDate: _startDate,
          endDate: _endDate,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          tags: _tags,
          paymentMethodId: _paymentMethodId,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PaymentMethodField extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _PaymentMethodField({
    required this.selectedMethod,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Payment Method',
          hintText: 'Optional',
          suffixIcon: selectedMethod != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.chevron_right),
        ),
        child: selectedMethod != null
            ? Row(
                children: [
                  ExcludeSemantics(
                    child: PaymentMethodAvatar(
                      paymentMethod: selectedMethod!,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedMethod!.fullLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            : Text(
                'None selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool allowClear;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: allowClear && value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          value != null
              ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
              : 'Optional',
          style: value == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }
}
