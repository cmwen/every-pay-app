import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/utils/id_generator.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/colour_swatch.dart';
import 'package:everypay/shared/widgets/payment_method_avatar.dart';

class PaymentMethodFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const PaymentMethodFormScreen({super.key, this.id});

  @override
  ConsumerState<PaymentMethodFormScreen> createState() =>
      _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState
    extends ConsumerState<PaymentMethodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bankNameController;
  late TextEditingController _last4Controller;

  PaymentMethodType _type = PaymentMethodType.creditCard;
  String _colourHex = PaymentMethodType.creditCard.defaultColourHex;
  bool _isDefault = false;
  bool _saving = false;
  bool _loaded = false;
  PaymentMethod? _existing;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bankNameController = TextEditingController();
    _last4Controller = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (_loaded || widget.id == null) {
      _loaded = true;
      return;
    }
    _loaded = true;
    final pm = await ref
        .read(paymentMethodRepositoryProvider)
        .getPaymentMethodById(widget.id!);
    if (pm != null && mounted) {
      setState(() {
        _existing = pm;
        _nameController.text = pm.name;
        _bankNameController.text = pm.bankName ?? '';
        _last4Controller.text = pm.last4Digits ?? '';
        _type = pm.type;
        _colourHex = pm.colourHex;
        _isDefault = pm.isDefault;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadExisting(),
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final isEdit = widget.id != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Payment Method' : 'Add Payment Method'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Live preview card
            _PreviewCard(
              name: _nameController.text.isEmpty
                  ? 'Card Name'
                  : _nameController.text,
              type: _type,
              colourHex: _colourHex,
              last4: _last4Controller.text.isEmpty
                  ? null
                  : _last4Controller.text,
              bankName: _bankNameController.text.isEmpty
                  ? null
                  : _bankNameController.text,
            ),
            const SizedBox(height: 24),

            // Type selector
            const Text('Type *', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethodType.values.map((t) {
                return ChoiceChip(
                  avatar: Icon(t.icon, size: 16),
                  label: Text(t.displayName),
                  selected: _type == t,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _type = t;
                        // Auto-suggest colour from type default if not already customised
                        _colourHex = t.defaultColourHex;
                        // Clear last4 if new type doesn't support it
                        if (!t.supportsLast4) {
                          _last4Controller.clear();
                        }
                        // Auto-suggest name if empty
                        if (_nameController.text.isEmpty) {
                          _nameController.text = t.displayName;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g. ANZ Visa Credit',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Bank name (optional)
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank / Provider',
                hintText: 'e.g. ANZ, PayPal',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Last 4 digits (conditionally shown)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _type.supportsLast4
                  ? Column(
                      children: [
                        TextFormField(
                          controller: _last4Controller,
                          decoration: const InputDecoration(
                            labelText: 'Last 4 Digits',
                            hintText: 'e.g. 4242',
                            helperText:
                                'Display only — we never store full card numbers.',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length != 4) {
                              return 'Enter exactly 4 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Colour swatches
            const Text('Colour', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: paymentMethodColourPresets.map((hex) {
                return ColourSwatch(
                  hexColour: hex,
                  selected: _colourHex == hex,
                  onTap: () => setState(() => _colourHex = hex),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Default toggle
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Set as default'),
              subtitle: const Text(
                'Auto-select this method when adding new expenses',
              ),
              contentPadding: EdgeInsets.zero,
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
                    : Text(isEdit ? 'Save Changes' : 'Save Payment Method'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final pm = PaymentMethod(
        id: _existing?.id ?? generateId(),
        name: _nameController.text.trim(),
        type: _type,
        last4Digits: _type.supportsLast4 && _last4Controller.text.isNotEmpty
            ? _last4Controller.text.trim()
            : null,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        colourHex: _colourHex,
        isDefault: _isDefault,
        sortOrder: _existing?.sortOrder ?? 0,
        createdAt: _existing?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(paymentMethodRepositoryProvider).upsertPaymentMethod(pm);

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Live preview card shown at the top of the form.
class _PreviewCard extends StatelessWidget {
  final String name;
  final PaymentMethodType type;
  final String colourHex;
  final String? last4;
  final String? bankName;

  const _PreviewCard({
    required this.name,
    required this.type,
    required this.colourHex,
    this.last4,
    this.bankName,
  });

  @override
  Widget build(BuildContext context) {
    final colour = _hexToColor(colourHex);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Card(
        key: ValueKey('$colourHex-$type-$last4'),
        color: colour,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PaymentMethodAvatar(
                    paymentMethod: PaymentMethod(
                      id: '',
                      name: name,
                      type: type,
                      colourHex: colourHex,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bankName ?? type.displayName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (last4 != null)
                    Text(
                      '•••• •••• •••• $last4',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final code = hex.replaceAll('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}
