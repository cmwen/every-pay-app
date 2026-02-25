import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

class Expense {
  final String id;
  final String name;
  final String? provider;
  final String categoryId;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final int? customDays;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextDueDate;
  final ExpenseStatus status;
  final String? notes;
  final String? logoAsset;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final String? paymentMethodId;

  const Expense({
    required this.id,
    required this.name,
    this.provider,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    this.customDays,
    required this.startDate,
    this.endDate,
    this.nextDueDate,
    required this.status,
    this.notes,
    this.logoAsset,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.paymentMethodId,
  });

  double get monthlyCost => amount * billingCycle.monthlyMultiplier(customDays);
  double get yearlyCost => monthlyCost * 12;

  bool get isExpiringSoon =>
      endDate != null &&
      endDate!.difference(DateTime.now()).inDays <= 30 &&
      endDate!.isAfter(DateTime.now());

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  bool get isActive => status == ExpenseStatus.active && !isExpired;

  int get daysUntilDue {
    if (nextDueDate == null) return -1;
    return nextDueDate!.difference(DateTime.now()).inDays;
  }

  Expense copyWith({
    String? id,
    String? name,
    String? provider,
    String? categoryId,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    int? customDays,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    ExpenseStatus? status,
    String? notes,
    String? logoAsset,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    String? paymentMethodId,
    bool clearPaymentMethod = false,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      customDays: customDays ?? this.customDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      logoAsset: logoAsset ?? this.logoAsset,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      paymentMethodId: clearPaymentMethod
          ? null
          : (paymentMethodId ?? this.paymentMethodId),
    );
  }
}
