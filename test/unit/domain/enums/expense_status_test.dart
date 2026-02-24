import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  group('ExpenseStatus', () {
    test('displayName returns correct values', () {
      expect(ExpenseStatus.active.displayName, 'Active');
      expect(ExpenseStatus.paused.displayName, 'Paused');
      expect(ExpenseStatus.cancelled.displayName, 'Cancelled');
    });

    test('has exactly 3 values', () {
      expect(ExpenseStatus.values.length, 3);
    });
  });
}
