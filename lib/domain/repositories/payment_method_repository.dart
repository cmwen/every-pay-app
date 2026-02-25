import 'package:everypay/domain/entities/payment_method.dart';

abstract class PaymentMethodRepository {
  Stream<List<PaymentMethod>> watchPaymentMethods();
  Future<PaymentMethod?> getPaymentMethodById(String id);
  Future<void> upsertPaymentMethod(PaymentMethod paymentMethod);
  Future<void> deletePaymentMethod(String id);
  Future<List<PaymentMethod>> getAllPaymentMethods();
  Future<int> countExpensesUsingPaymentMethod(String id);
  Future<void> clearPaymentMethodFromExpenses(String id);
  void dispose();
}
