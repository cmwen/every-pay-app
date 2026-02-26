import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/core/services/conflict_resolver.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/enums/billing_cycle.dart';
import 'package:everypay/domain/enums/expense_status.dart';

void main() {
  final resolver = const ConflictResolver();

  Expense makeExpense({
    String id = 'e1',
    String deviceId = 'device-a',
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id,
      name: 'Test',
      categoryId: 'cat-entertainment',
      amount: 10.0,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 1, 1),
      status: ExpenseStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 6, 1),
      deviceId: deviceId,
    );
  }

  Category makeCategory({String id = 'c1', DateTime? updatedAt}) {
    return Category(
      id: id,
      name: 'Test',
      icon: 'category',
      colour: '#000000',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 6, 1),
    );
  }

  group('ConflictResolver - Expenses', () {
    test('edit beats delete — local active wins over remote deleted', () {
      final local = makeExpense();
      final remote = makeExpense(updatedAt: DateTime(2026, 7, 1));
      final result = resolver.resolveExpense(
        local: local,
        remote: remote,
        localDeleted: false,
        remoteDeleted: true,
      );
      expect(result.action, ConflictAction.keepLocal);
      expect(result.winner, local);
    });

    test('edit beats delete — remote active wins over local deleted', () {
      final local = makeExpense(updatedAt: DateTime(2026, 7, 1));
      final remote = makeExpense();
      final result = resolver.resolveExpense(
        local: local,
        remote: remote,
        localDeleted: true,
        remoteDeleted: false,
      );
      expect(result.action, ConflictAction.keepRemote);
      expect(result.winner, remote);
    });

    test('last-write-wins — newer updatedAt wins', () {
      final local = makeExpense(updatedAt: DateTime(2026, 6, 1));
      final remote = makeExpense(updatedAt: DateTime(2026, 7, 1));
      final result = resolver.resolveExpense(local: local, remote: remote);
      expect(result.action, ConflictAction.keepRemote);
      expect(result.winner, remote);
    });

    test('last-write-wins — local wins when newer', () {
      final local = makeExpense(updatedAt: DateTime(2026, 7, 1));
      final remote = makeExpense(updatedAt: DateTime(2026, 6, 1));
      final result = resolver.resolveExpense(local: local, remote: remote);
      expect(result.action, ConflictAction.keepLocal);
    });

    test('device ID tiebreaker when timestamps equal', () {
      final local = makeExpense(deviceId: 'device-b');
      final remote = makeExpense(deviceId: 'device-a');
      final result = resolver.resolveExpense(local: local, remote: remote);
      // 'device-b' > 'device-a', so local wins
      expect(result.action, ConflictAction.keepLocal);
    });

    test('device ID tiebreaker — remote wins when higher', () {
      final local = makeExpense(deviceId: 'device-a');
      final remote = makeExpense(deviceId: 'device-b');
      final result = resolver.resolveExpense(local: local, remote: remote);
      expect(result.action, ConflictAction.keepRemote);
    });
  });

  group('ConflictResolver - Categories', () {
    test('edit beats delete', () {
      final local = makeCategory();
      final remote = makeCategory(updatedAt: DateTime(2026, 7, 1));
      final result = resolver.resolveCategory(
        local: local,
        remote: remote,
        localDeleted: false,
        remoteDeleted: true,
      );
      expect(result.action, ConflictAction.keepLocal);
    });

    test('last-write-wins', () {
      final local = makeCategory(updatedAt: DateTime(2026, 6, 1));
      final remote = makeCategory(updatedAt: DateTime(2026, 7, 1));
      final result = resolver.resolveCategory(local: local, remote: remote);
      expect(result.action, ConflictAction.keepRemote);
    });

    test('id tiebreaker when timestamps equal', () {
      final local = makeCategory(id: 'cat-b');
      final remote = makeCategory(id: 'cat-a');
      final result = resolver.resolveCategory(local: local, remote: remote);
      expect(result.action, ConflictAction.keepLocal);
    });
  });
}
