import 'package:everypay/domain/entities/paired_device.dart';

/// Abstract sync service interface.
/// Full P2P networking (mDNS, TCP, TLS) requires real device testing.
/// This provides the interface contract for future implementation.
abstract class SyncService {
  /// Start discovering nearby devices via mDNS.
  Future<void> startDiscovery();

  /// Stop device discovery.
  Future<void> stopDiscovery();

  /// Stream of discovered devices on the local network.
  Stream<List<PairedDevice>> get discoveredDevices;

  /// Initiate pairing with a device using a shared secret (from QR code).
  Future<bool> pairDevice(String deviceId, String sharedSecret);

  /// Unpair a device.
  Future<void> unpairDevice(String deviceId);

  /// Get list of paired devices.
  Future<List<PairedDevice>> getPairedDevices();

  /// Perform a delta sync with a specific device.
  Future<SyncResult> syncWithDevice(String deviceId);

  /// Perform sync with all paired devices.
  Future<List<SyncResult>> syncAll();
}

class SyncResult {
  final String deviceId;
  final bool success;
  final int expensesSynced;
  final int categoriesSynced;
  final int conflicts;
  final String? error;

  const SyncResult({
    required this.deviceId,
    required this.success,
    this.expensesSynced = 0,
    this.categoriesSynced = 0,
    this.conflicts = 0,
    this.error,
  });
}
