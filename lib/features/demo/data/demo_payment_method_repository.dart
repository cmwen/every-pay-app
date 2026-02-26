import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/domain/repositories/payment_method_repository.dart';
import 'package:everypay/features/demo/data/demo_data.dart';

/// In-memory, read-only payment method repository for demo mode.
class DemoPaymentMethodRepository implements PaymentMethodRepository {
  @override
  Stream<List<PaymentMethod>> watchPaymentMethods() {
    return Stream.value(List.from(demoPaymentMethods));
  }

  @override
  Future<PaymentMethod?> getPaymentMethodById(String id) async {
    try {
      return demoPaymentMethods.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertPaymentMethod(PaymentMethod paymentMethod) async {
    // No-op in demo mode
  }

  @override
  Future<void> deletePaymentMethod(String id) async {
    // No-op in demo mode
  }

  @override
  Future<List<PaymentMethod>> getAllPaymentMethods() async =>
      List.from(demoPaymentMethods);

  @override
  Future<int> countExpensesUsingPaymentMethod(String id) async {
    return demoExpenses.where((e) => e.paymentMethodId == id).length;
  }

  @override
  Future<void> clearPaymentMethodFromExpenses(String id) async {
    // No-op in demo mode
  }

  @override
  void dispose() {
    // No-op
  }
}
