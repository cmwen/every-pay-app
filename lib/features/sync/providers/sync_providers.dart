import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:everypay/core/services/conflict_resolver.dart';
import 'package:everypay/core/services/sync_service.dart';
import 'package:everypay/data/database/sqlite_paired_devices_repository.dart';
import 'package:everypay/data/database/sqlite_sync_state_repository.dart';
import 'package:everypay/data/transport/nearby_transport.dart';
import 'package:everypay/data/transport/p2p_transport.dart';
import 'package:everypay/domain/entities/paired_device.dart';
import 'package:everypay/domain/repositories/paired_devices_repository.dart';
import 'package:everypay/domain/repositories/sync_state_repository.dart';
import 'package:everypay/features/sync/services/payload_serializer.dart';
import 'package:everypay/features/sync/services/sync_engine.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

// ---------------------------------------------------------------------------
// SharedPreferences key for the fallback device ID
// ---------------------------------------------------------------------------

const _kDeviceIdKey = 'device_id';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final pairedDevicesRepositoryProvider = Provider<PairedDevicesRepository>((
  ref,
) {
  final repo = SqlitePairedDevicesRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final syncStateRepositoryProvider = Provider<SyncStateRepository>((_) {
  return SqliteSyncStateRepository();
});

// ---------------------------------------------------------------------------
// Transport provider
// ---------------------------------------------------------------------------

final p2pTransportProvider = Provider<P2PTransport>((ref) {
  final transport = NearbyTransport();
  ref.onDispose(() => transport.dispose());
  return transport;
});

// ---------------------------------------------------------------------------
// Device ID provider
// ---------------------------------------------------------------------------

/// Provides a stable device identifier.
///
/// On Android the hardware-level [AndroidBuildInfo.id] is used when available.
/// On iOS the [IosDeviceInfo.identifierForVendor] is used.
/// Falls back to a randomly generated UUID persisted in [SharedPreferences].
final deviceIdProvider = FutureProvider<String>((ref) async {
  final info = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final android = await info.androidInfo;
    final id = android.id;
    if (id.isNotEmpty) return id;
  } else if (Platform.isIOS) {
    final ios = await info.iosInfo;
    final id = ios.identifierForVendor;
    if (id != null && id.isNotEmpty) return id;
  }

  // Fallback: generate and persist a UUID.
  final prefs = await SharedPreferences.getInstance();
  var stored = prefs.getString(_kDeviceIdKey);
  if (stored == null) {
    stored = const Uuid().v4();
    await prefs.setString(_kDeviceIdKey, stored);
  }
  return stored;
});

// ---------------------------------------------------------------------------
// Sync engine provider
// ---------------------------------------------------------------------------

/// Provides the [SyncEngine] wired to all required repositories and services.
///
/// The sync screens should await [deviceIdProvider] before using the engine
/// to ensure the local device ID is loaded.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final deviceIdAsync = ref.watch(deviceIdProvider);
  final deviceId = switch (deviceIdAsync) {
    AsyncData(:final value) => value,
    _ => '',
  };

  return SyncEngine(
    transport: ref.watch(p2pTransportProvider),
    syncStateRepo: ref.watch(syncStateRepositoryProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    paymentMethodRepo: ref.watch(paymentMethodRepositoryProvider),
    serializer: PayloadSerializer(),
    conflictResolver: const ConflictResolver(),
    localDeviceId: deviceId,
  );
});

// ---------------------------------------------------------------------------
// Paired devices stream
// ---------------------------------------------------------------------------

/// Watches the list of paired devices from the database.
final pairedDevicesProvider = StreamProvider<List<PairedDevice>>((ref) {
  return ref.watch(pairedDevicesRepositoryProvider).watchPairedDevices();
});

// ---------------------------------------------------------------------------
// Discovery state
// ---------------------------------------------------------------------------

/// The current phase of device discovery.
enum DiscoveryStatus {
  /// Not currently discovering.
  idle,

  /// Actively scanning for nearby devices.
  discovering,

  /// An error occurred during discovery.
  error,
}

/// Immutable snapshot of the discovery state.
class DiscoveryState {
  final DiscoveryStatus status;
  final List<DiscoveredDevice> devices;
  final String? error;

  const DiscoveryState({
    this.status = DiscoveryStatus.idle,
    this.devices = const [],
    this.error,
  });
}

/// Manages P2P device discovery lifecycle.
///
/// Call [startDiscovery] to begin advertising and scanning, and
/// [stopDiscovery] to tear everything down.
final discoveryProvider = NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);

class DiscoveryNotifier extends Notifier<DiscoveryState> {
  StreamSubscription<List<DiscoveredDevice>>? _sub;

  @override
  DiscoveryState build() => const DiscoveryState();

  /// Begin advertising this device and scanning for nearby peers.
  Future<void> startDiscovery(String localDeviceName) async {
    final transport = ref.read(p2pTransportProvider);

    if (!transport.isInitialized) {
      final ok = await transport.initialize();
      if (!ok) {
        state = const DiscoveryState(
          status: DiscoveryStatus.error,
          error: 'Failed to initialize transport',
        );
        return;
      }
    }

    await transport.startAdvertising(localDeviceName);
    await transport.startDiscovery();

    state = const DiscoveryState(status: DiscoveryStatus.discovering);

    _sub?.cancel();
    _sub = transport.discoveredDevices.listen(
      (devices) {
        state = DiscoveryState(
          status: DiscoveryStatus.discovering,
          devices: devices,
        );
      },
      onError: (Object e) {
        state = DiscoveryState(
          status: DiscoveryStatus.error,
          error: e.toString(),
        );
      },
    );
  }

  /// Stop advertising, scanning, and clear discovered devices.
  Future<void> stopDiscovery() async {
    _sub?.cancel();
    _sub = null;

    final transport = ref.read(p2pTransportProvider);
    await transport.stopDiscovery();
    await transport.stopAdvertising();

    state = const DiscoveryState();
  }
}

// ---------------------------------------------------------------------------
// Sync status
// ---------------------------------------------------------------------------

/// The current phase of a sync operation.
enum SyncPhase {
  /// No sync in progress.
  idle,

  /// Establishing a connection to the remote device.
  connecting,

  /// Actively syncing data.
  syncing,

  /// Sync completed successfully.
  complete,

  /// An error occurred during sync.
  error,
}

/// Immutable snapshot of the current sync operation status.
class SyncStatus {
  final SyncPhase phase;
  final String? deviceName;
  final SyncResult? result;
  final String? error;

  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.deviceName,
    this.result,
    this.error,
  });
}

/// Manages the lifecycle of a sync operation with a paired device.
final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  /// Start a full sync cycle with the given [device].
  ///
  /// Transitions through [SyncPhase.connecting] → [SyncPhase.syncing] →
  /// [SyncPhase.complete] (or [SyncPhase.error] on failure).
  Future<void> syncWithDevice(PairedDevice device) async {
    state = SyncStatus(
      phase: SyncPhase.connecting,
      deviceName: device.deviceName,
    );

    try {
      final transport = ref.read(p2pTransportProvider);

      if (!transport.isInitialized) {
        final ok = await transport.initialize();
        if (!ok) {
          state = const SyncStatus(
            phase: SyncPhase.error,
            error: 'Failed to initialize transport',
          );
          return;
        }
      }

      // Establish connection
      final connected = await transport.connect(
        DiscoveredDevice(id: device.deviceId, name: device.deviceName),
      );

      if (!connected) {
        state = SyncStatus(
          phase: SyncPhase.error,
          deviceName: device.deviceName,
          error: 'Failed to connect to ${device.deviceName}',
        );
        return;
      }

      state = SyncStatus(
        phase: SyncPhase.syncing,
        deviceName: device.deviceName,
      );

      // Run the sync engine
      final engine = ref.read(syncEngineProvider);
      final result = await engine.syncWithDevice(device.deviceId);

      // Update last-seen timestamp
      await ref
          .read(pairedDevicesRepositoryProvider)
          .updateLastSeen(device.deviceId, DateTime.now());

      if (result.success) {
        state = SyncStatus(
          phase: SyncPhase.complete,
          deviceName: device.deviceName,
          result: result,
        );
      } else {
        state = SyncStatus(
          phase: SyncPhase.error,
          deviceName: device.deviceName,
          error: result.error,
        );
      }
    } catch (e) {
      state = SyncStatus(
        phase: SyncPhase.error,
        deviceName: device.deviceName,
        error: e.toString(),
      );
    }
  }

  /// Reset the status back to idle.
  void reset() => state = const SyncStatus();
}
