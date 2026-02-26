import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/core/services/sync_service.dart';
import 'package:everypay/features/sync/providers/sync_providers.dart';

void main() {
  group('DiscoveryStatus enum', () {
    test('has exactly three values', () {
      expect(DiscoveryStatus.values.length, 3);
    });

    test('values are idle, discovering, error', () {
      expect(DiscoveryStatus.values, [
        DiscoveryStatus.idle,
        DiscoveryStatus.discovering,
        DiscoveryStatus.error,
      ]);
    });
  });

  group('DiscoveryState', () {
    test('default constructor has idle status and empty devices', () {
      const state = DiscoveryState();

      expect(state.status, DiscoveryStatus.idle);
      expect(state.devices, isEmpty);
      expect(state.error, isNull);
    });

    test('constructor with discovering status and devices', () {
      const state = DiscoveryState(
        status: DiscoveryStatus.discovering,
        devices: [],
      );

      expect(state.status, DiscoveryStatus.discovering);
      expect(state.devices, isEmpty);
      expect(state.error, isNull);
    });

    test('constructor with error status and error message', () {
      const state = DiscoveryState(
        status: DiscoveryStatus.error,
        error: 'Bluetooth not available',
      );

      expect(state.status, DiscoveryStatus.error);
      expect(state.error, 'Bluetooth not available');
      expect(state.devices, isEmpty);
    });
  });

  group('SyncPhase enum', () {
    test('has exactly five values', () {
      expect(SyncPhase.values.length, 5);
    });

    test('values are idle, connecting, syncing, complete, error', () {
      expect(SyncPhase.values, [
        SyncPhase.idle,
        SyncPhase.connecting,
        SyncPhase.syncing,
        SyncPhase.complete,
        SyncPhase.error,
      ]);
    });
  });

  group('SyncStatus', () {
    test('default constructor has idle phase and no details', () {
      const status = SyncStatus();

      expect(status.phase, SyncPhase.idle);
      expect(status.deviceName, isNull);
      expect(status.result, isNull);
      expect(status.error, isNull);
    });

    test('connecting status carries device name', () {
      const status = SyncStatus(
        phase: SyncPhase.connecting,
        deviceName: "Alice's Phone",
      );

      expect(status.phase, SyncPhase.connecting);
      expect(status.deviceName, "Alice's Phone");
      expect(status.result, isNull);
      expect(status.error, isNull);
    });

    test('complete status carries SyncResult', () {
      const result = SyncResult(
        deviceId: 'device-123',
        success: true,
        expensesSynced: 10,
        categoriesSynced: 3,
        conflicts: 1,
      );
      const status = SyncStatus(
        phase: SyncPhase.complete,
        deviceName: "Bob's Tablet",
        result: result,
      );

      expect(status.phase, SyncPhase.complete);
      expect(status.deviceName, "Bob's Tablet");
      expect(status.result, isNotNull);
      expect(status.result!.success, isTrue);
      expect(status.result!.expensesSynced, 10);
    });

    test('error status carries error message', () {
      const status = SyncStatus(
        phase: SyncPhase.error,
        deviceName: 'Remote Device',
        error: 'Connection refused',
      );

      expect(status.phase, SyncPhase.error);
      expect(status.deviceName, 'Remote Device');
      expect(status.error, 'Connection refused');
      expect(status.result, isNull);
    });
  });

  group('SyncResult', () {
    test('success result defaults to zero counts', () {
      const result = SyncResult(deviceId: 'd1', success: true);

      expect(result.deviceId, 'd1');
      expect(result.success, isTrue);
      expect(result.expensesSynced, 0);
      expect(result.categoriesSynced, 0);
      expect(result.conflicts, 0);
      expect(result.error, isNull);
    });

    test('failure result with error string', () {
      const result = SyncResult(
        deviceId: 'd2',
        success: false,
        error: 'Timeout after 30s',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Timeout after 30s');
    });

    test('result carries all sync counts', () {
      const result = SyncResult(
        deviceId: 'd3',
        success: true,
        expensesSynced: 42,
        categoriesSynced: 7,
        conflicts: 3,
      );

      expect(result.expensesSynced, 42);
      expect(result.categoriesSynced, 7);
      expect(result.conflicts, 3);
    });
  });
}
