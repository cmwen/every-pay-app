import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/core/constants/app_constants.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class ExpenseFormData {
  final String name;
  final String? provider;
  final String categoryId;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final int? customDays;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final List<String> tags;

  const ExpenseFormData({
    required this.name,
    this.provider,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    this.customDays,
    required this.startDate,
    this.endDate,
    this.notes,
    this.tags = const [],
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
  late DateTime _startDate;
  DateTime? _endDate;
  late List<String> _tags;
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
    _startDate = e?.startDate ?? DateTime.now();
    _endDate = e?.endDate;
    _tags = e?.tags.toList() ?? [];
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
    final categoriesAsync = ref.watch(
      StreamProvider<List<Category>>(
        (ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
      ),
    );

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
                  if (v == null || v.isEmpty)
                    return 'Required for custom cycle';
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
                  label: 'Start Date *',
                  value: _startDate,
                  onChanged: (d) => setState(() => _startDate = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'End Date',
                  value: _endDate,
                  onChanged: (d) => setState(() => _endDate = d),
                  allowClear: true,
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
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool allowClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = false,
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
        decoration: InputDecoration(labelText: label),
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
