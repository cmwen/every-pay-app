import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/features/sync/services/payload_serializer.dart';
import 'package:everypay/domain/entities/sync_payload.dart';

void main() {
  final serializer = PayloadSerializer();

  group('PayloadSerializer', () {
    test(
      'round-trip: serialize then deserialize produces identical payload',
      () {
        final payload = SyncPayload(
          deviceId: 'device-abc',
          syncTimestamp: '2026-06-15T12:00:00.000Z',
          schemaVersion: 3,
          expenses: [
            {
              'id': 'e1',
              'name': 'Netflix',
              'provider': 'Netflix Inc.',
              'category_id': 'cat-entertainment',
              'amount': 15.99,
              'currency': 'USD',
              'billing_cycle': 'monthly',
              'custom_days': null,
              'start_date': '2026-01-01T00:00:00.000',
              'end_date': null,
              'next_due_date': '2026-07-01T00:00:00.000',
              'status': 'active',
              'notes': 'Premium plan',
              'logo_asset': null,
              'tags': 'streaming,entertainment',
              'created_at': '2026-01-01T00:00:00.000',
              'updated_at': '2026-06-15T12:00:00.000',
              'device_id': 'device-abc',
              'payment_method_id': 'pm-1',
              'is_deleted': 0,
            },
          ],
          categories: [
            {
              'id': 'cat-entertainment',
              'name': 'Entertainment',
              'icon': 'movie',
              'colour': '#E91E63',
              'is_default': 1,
              'sort_order': 0,
              'created_at': '2026-01-01T00:00:00.000',
              'updated_at': '2026-06-15T12:00:00.000',
              'is_deleted': 0,
            },
          ],
          paymentMethods: [
            {
              'id': 'pm-1',
              'name': 'Visa',
              'type': 'creditCard',
              'last4_digits': '4242',
              'bank_name': 'ANZ',
              'colour_hex': '#1565C0',
              'is_default': 1,
              'sort_order': 0,
              'created_at': '2026-01-01T00:00:00.000',
              'updated_at': '2026-06-15T12:00:00.000',
              'is_deleted': 0,
            },
          ],
        );

        final bytes = serializer.serialize(payload);
        final restored = serializer.deserialize(bytes);

        expect(restored.deviceId, payload.deviceId);
        expect(restored.syncTimestamp, payload.syncTimestamp);
        expect(restored.schemaVersion, payload.schemaVersion);
        expect(restored.expenses.length, payload.expenses.length);
        expect(restored.categories.length, payload.categories.length);
        expect(restored.paymentMethods.length, payload.paymentMethods.length);

        // Deep-check the expense fields
        final originalExp = payload.expenses.first;
        final restoredExp = restored.expenses.first;
        expect(restoredExp['id'], originalExp['id']);
        expect(restoredExp['name'], originalExp['name']);
        expect(restoredExp['amount'], originalExp['amount']);
        expect(restoredExp['currency'], originalExp['currency']);
        expect(restoredExp['billing_cycle'], originalExp['billing_cycle']);
        expect(restoredExp['tags'], originalExp['tags']);
        expect(restoredExp['is_deleted'], originalExp['is_deleted']);
      },
    );

    test('empty payload round-trips correctly', () {
      const payload = SyncPayload(
        deviceId: 'device-empty',
        syncTimestamp: '2026-06-15T00:00:00.000Z',
        schemaVersion: 3,
        expenses: [],
        categories: [],
        paymentMethods: [],
      );

      final bytes = serializer.serialize(payload);
      final restored = serializer.deserialize(bytes);

      expect(restored.deviceId, 'device-empty');
      expect(restored.syncTimestamp, '2026-06-15T00:00:00.000Z');
      expect(restored.schemaVersion, 3);
      expect(restored.expenses, isEmpty);
      expect(restored.categories, isEmpty);
      expect(restored.paymentMethods, isEmpty);
    });

    test('payload with all entity types populated round-trips correctly', () {
      final payload = SyncPayload(
        deviceId: 'device-full',
        syncTimestamp: '2026-07-01T08:30:00.000Z',
        schemaVersion: 5,
        expenses: [
          {
            'id': 'e1',
            'name': 'Spotify',
            'provider': null,
            'category_id': 'cat-music',
            'amount': 9.99,
            'currency': 'NZD',
            'billing_cycle': 'monthly',
            'custom_days': null,
            'start_date': '2026-02-01T00:00:00.000',
            'end_date': null,
            'next_due_date': null,
            'status': 'active',
            'notes': null,
            'logo_asset': null,
            'tags': '',
            'created_at': '2026-02-01T00:00:00.000',
            'updated_at': '2026-06-01T00:00:00.000',
            'device_id': 'device-full',
            'payment_method_id': null,
            'is_deleted': 0,
          },
          {
            'id': 'e2',
            'name': 'Gym',
            'provider': 'Anytime Fitness',
            'category_id': 'cat-health',
            'amount': 25.0,
            'currency': 'NZD',
            'billing_cycle': 'fortnightly',
            'custom_days': null,
            'start_date': '2026-03-01T00:00:00.000',
            'end_date': '2026-12-31T00:00:00.000',
            'next_due_date': '2026-07-15T00:00:00.000',
            'status': 'active',
            'notes': 'Discount rate',
            'logo_asset': null,
            'tags': 'health,fitness',
            'created_at': '2026-03-01T00:00:00.000',
            'updated_at': '2026-07-01T08:00:00.000',
            'device_id': 'device-full',
            'payment_method_id': 'pm-2',
            'is_deleted': 0,
          },
        ],
        categories: [
          {
            'id': 'cat-music',
            'name': 'Music',
            'icon': 'music_note',
            'colour': '#9C27B0',
            'is_default': 0,
            'sort_order': 1,
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-01-01T00:00:00.000',
            'is_deleted': 0,
          },
          {
            'id': 'cat-health',
            'name': 'Health',
            'icon': 'fitness_center',
            'colour': '#4CAF50',
            'is_default': 0,
            'sort_order': 2,
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-05-01T00:00:00.000',
            'is_deleted': 0,
          },
        ],
        paymentMethods: [
          {
            'id': 'pm-2',
            'name': 'Mastercard',
            'type': 'debitCard',
            'last4_digits': '1234',
            'bank_name': 'Kiwibank',
            'colour_hex': '#00897B',
            'is_default': 0,
            'sort_order': 1,
            'created_at': '2026-01-15T00:00:00.000',
            'updated_at': '2026-06-01T00:00:00.000',
            'is_deleted': 0,
          },
        ],
      );

      final bytes = serializer.serialize(payload);
      final restored = serializer.deserialize(bytes);

      expect(restored.deviceId, 'device-full');
      expect(restored.schemaVersion, 5);
      expect(restored.expenses.length, 2);
      expect(restored.categories.length, 2);
      expect(restored.paymentMethods.length, 1);

      // Verify second expense preserved all fields
      final restoredGym = restored.expenses[1];
      expect(restoredGym['id'], 'e2');
      expect(restoredGym['name'], 'Gym');
      expect(restoredGym['provider'], 'Anytime Fitness');
      expect(restoredGym['amount'], 25.0);
      expect(restoredGym['billing_cycle'], 'fortnightly');
      expect(restoredGym['end_date'], '2026-12-31T00:00:00.000');
      expect(restoredGym['notes'], 'Discount rate');
      expect(restoredGym['tags'], 'health,fitness');
      expect(restoredGym['payment_method_id'], 'pm-2');

      // Verify category preserved
      final restoredHealth = restored.categories[1];
      expect(restoredHealth['id'], 'cat-health');
      expect(restoredHealth['name'], 'Health');
      expect(restoredHealth['colour'], '#4CAF50');

      // Verify payment method preserved
      final restoredPm = restored.paymentMethods.first;
      expect(restoredPm['id'], 'pm-2');
      expect(restoredPm['type'], 'debitCard');
      expect(restoredPm['last4_digits'], '1234');
      expect(restoredPm['bank_name'], 'Kiwibank');
    });

    test('preserves schema version and device ID across serialization', () {
      const payload = SyncPayload(
        deviceId: 'unique-device-id-12345',
        syncTimestamp: '2026-01-01T00:00:00.000Z',
        schemaVersion: 42,
      );

      final bytes = serializer.serialize(payload);
      final restored = serializer.deserialize(bytes);

      expect(restored.deviceId, 'unique-device-id-12345');
      expect(restored.schemaVersion, 42);
    });

    test('serialized bytes are gzip-compressed (smaller than raw JSON)', () {
      final payload = SyncPayload(
        deviceId: 'device-compress-test',
        syncTimestamp: '2026-06-15T12:00:00.000Z',
        schemaVersion: 3,
        expenses: List.generate(
          20,
          (i) => {
            'id': 'e$i',
            'name': 'Expense $i',
            'provider': null,
            'category_id': 'cat-default',
            'amount': 10.0 + i,
            'currency': 'USD',
            'billing_cycle': 'monthly',
            'custom_days': null,
            'start_date': '2026-01-01T00:00:00.000',
            'end_date': null,
            'next_due_date': null,
            'status': 'active',
            'notes': null,
            'logo_asset': null,
            'tags': '',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-06-15T00:00:00.000',
            'device_id': 'device-compress-test',
            'payment_method_id': null,
            'is_deleted': 0,
          },
        ),
      );

      final bytes = serializer.serialize(payload);
      // Gzip should compress repetitive JSON significantly
      // The raw JSON for 20 similar expenses is well over 2000 bytes
      expect(bytes.length, lessThan(2000));
      // But still produces valid output
      final restored = serializer.deserialize(bytes);
      expect(restored.expenses.length, 20);
    });

    test('handles special characters in strings', () {
      final payload = SyncPayload(
        deviceId: 'device-special',
        syncTimestamp: '2026-06-15T12:00:00.000Z',
        schemaVersion: 3,
        expenses: [
          {
            'id': 'e-special',
            'name': 'Café & Résumé — 日本語テスト',
            'provider': 'Provider with "quotes" & <angles>',
            'category_id': 'cat-food',
            'amount': 5.5,
            'currency': 'EUR',
            'billing_cycle': 'monthly',
            'custom_days': null,
            'start_date': '2026-01-01T00:00:00.000',
            'end_date': null,
            'next_due_date': null,
            'status': 'active',
            'notes': 'Line1\nLine2\ttab',
            'logo_asset': null,
            'tags': 'café,日本語',
            'created_at': '2026-01-01T00:00:00.000',
            'updated_at': '2026-06-15T00:00:00.000',
            'device_id': 'device-special',
            'payment_method_id': null,
            'is_deleted': 0,
          },
        ],
      );

      final bytes = serializer.serialize(payload);
      final restored = serializer.deserialize(bytes);

      final exp = restored.expenses.first;
      expect(exp['name'], 'Café & Résumé — 日本語テスト');
      expect(exp['provider'], 'Provider with "quotes" & <angles>');
      expect(exp['notes'], 'Line1\nLine2\ttab');
      expect(exp['tags'], 'café,日本語');
    });
  });
}
