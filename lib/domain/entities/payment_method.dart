import 'package:flutter/material.dart';

enum PaymentMethodType {
  creditCard,
  debitCard,
  directDebit,
  bankTransfer,
  paypal,
  applePay,
  googlePay,
  cash,
  other;

  String get displayName => switch (this) {
    PaymentMethodType.creditCard => 'Credit Card',
    PaymentMethodType.debitCard => 'Debit Card',
    PaymentMethodType.directDebit => 'Direct Debit',
    PaymentMethodType.bankTransfer => 'Bank Transfer',
    PaymentMethodType.paypal => 'PayPal',
    PaymentMethodType.applePay => 'Apple Pay',
    PaymentMethodType.googlePay => 'Google Pay',
    PaymentMethodType.cash => 'Cash',
    PaymentMethodType.other => 'Other',
  };

  IconData get icon => switch (this) {
    PaymentMethodType.creditCard => Icons.credit_card,
    PaymentMethodType.debitCard => Icons.payment,
    PaymentMethodType.directDebit => Icons.account_balance,
    PaymentMethodType.bankTransfer => Icons.swap_horiz,
    PaymentMethodType.paypal => Icons.payments,
    PaymentMethodType.applePay => Icons.phone_iphone,
    PaymentMethodType.googlePay => Icons.g_mobiledata,
    PaymentMethodType.cash => Icons.money,
    PaymentMethodType.other => Icons.wallet,
  };

  /// Default colour hex for each type.
  String get defaultColourHex => switch (this) {
    PaymentMethodType.creditCard => '#1565C0',
    PaymentMethodType.debitCard => '#00897B',
    PaymentMethodType.directDebit => '#6D4C41',
    PaymentMethodType.bankTransfer => '#283593',
    PaymentMethodType.paypal => '#0070BA',
    PaymentMethodType.applePay => '#1C1C1E',
    PaymentMethodType.googlePay => '#4285F4',
    PaymentMethodType.cash => '#2E7D32',
    PaymentMethodType.other => '#546E7A',
  };

  /// Whether this type can have last 4 digits.
  bool get supportsLast4 => switch (this) {
    PaymentMethodType.creditCard || PaymentMethodType.debitCard => true,
    _ => false,
  };
}

/// Preset swatchable colours for payment methods.
const paymentMethodColourPresets = [
  '#1565C0', // Blue
  '#00897B', // Teal
  '#E53935', // Red
  '#43A047', // Green
  '#FB8C00', // Orange
  '#8E24AA', // Purple
  '#6D4C41', // Brown
  '#546E7A', // Blue-grey
];

class PaymentMethod {
  final String id;
  final String name;
  final PaymentMethodType type;
  final String? last4Digits;
  final String? bankName;
  final String colourHex;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.last4Digits,
    this.bankName,
    required this.colourHex,
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Short label: "••4242" or bankName or type display name.
  String get compactLabel {
    if (last4Digits != null && last4Digits!.isNotEmpty) {
      return '••$last4Digits';
    }
    if (bankName != null && bankName!.isNotEmpty) return bankName!;
    return type.displayName;
  }

  /// Full label: "ANZ Visa ••4242" or just name.
  String get fullLabel {
    if (last4Digits != null && last4Digits!.isNotEmpty) {
      return '$name  ••$last4Digits';
    }
    return name;
  }

  PaymentMethod copyWith({
    String? id,
    String? name,
    PaymentMethodType? type,
    String? last4Digits,
    String? bankName,
    String? colourHex,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearLast4 = false,
    bool clearBank = false,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      last4Digits: clearLast4 ? null : (last4Digits ?? this.last4Digits),
      bankName: clearBank ? null : (bankName ?? this.bankName),
      colourHex: colourHex ?? this.colourHex,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
