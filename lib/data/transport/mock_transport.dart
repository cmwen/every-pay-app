import 'dart:async';
import 'dart:typed_data';

import 'package:everypay/data/transport/p2p_transport.dart';

/// A fake [P2PTransport] for unit / widget testing.
///
/// Simulates the full P2P lifecycle (discovery, connection, data exchange)
/// without requiring physical devices or platform services.
///
/// ```dart
/// final transport = MockP2PTransport();
/// await transport.initialize();
///
/// // Inject fake nearby devices.
/// transport.injectDiscoveredDevices([
///   const DiscoveredDevice(id: 'peer-1', name: 'Alice's Phone'),
/// ]);
///
/// // Simulate receiving data from a connected peer.
/// transport.injectReceivedData('peer-1', Uint8List.fromList([1, 2, 3]));
/// ```
class MockP2PTransport implements P2PTransport {
  bool _initialized = false;
  bool _advertising = false;
  bool _discovering = false;

  /// The set of currently connected device IDs.
  final Set<String> _connectedDevices = {};

  /// History of all data that was sent via [sendData], useful for assertions.
  final List<({String deviceId, Uint8List data})> sentDataLog = [];

  // ---------------------------------------------------------------------------
  // Stream controllers
  // ---------------------------------------------------------------------------

  final _discoveredDevicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  final _incomingConnectionsController =
      StreamController<P2PConnection>.broadcast();

  final _receivedDataController =
      StreamController<({String deviceId, Uint8List data})>.broadcast();

  // ---------------------------------------------------------------------------
  // Test helpers — inject events from the "outside"
  // ---------------------------------------------------------------------------

  /// Push a list of [devices] as if they were discovered on the network.
  void injectDiscoveredDevices(List<DiscoveredDevice> devices) {
    if (!_discoveredDevicesController.isClosed) {
      _discoveredDevicesController.add(devices);
    }
  }

  /// Push an incoming connection request as if a remote device wants to pair.
  void injectIncomingConnection(P2PConnection connection) {
    if (!_incomingConnectionsController.isClosed) {
      _incomingConnectionsController.add(connection);
    }
  }

  /// Push received binary [data] as if it came from [deviceId].
  void injectReceivedData(String deviceId, Uint8List data) {
    if (!_receivedDataController.isClosed) {
      _receivedDataController.add((deviceId: deviceId, data: data));
    }
  }

  /// Whether [startAdvertising] was called (and not yet stopped).
  bool get isAdvertising => _advertising;

  /// Whether [startDiscovery] was called (and not yet stopped).
  bool get isDiscovering => _discovering;

  /// The set of device IDs that are currently connected.
  Set<String> get connectedDeviceIds => Set.unmodifiable(_connectedDevices);

  // ---------------------------------------------------------------------------
  // P2PTransport interface
  // ---------------------------------------------------------------------------

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<void> startAdvertising(String deviceName) async {
    _advertising = true;
  }

  @override
  Future<void> stopAdvertising() async {
    _advertising = false;
  }

  @override
  Future<void> startDiscovery() async {
    _discovering = true;
    // Immediately emit an empty list so listeners get an initial value.
    if (!_discoveredDevicesController.isClosed) {
      _discoveredDevicesController.add(const []);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _discovering = false;
    if (!_discoveredDevicesController.isClosed) {
      _discoveredDevicesController.add(const []);
    }
  }

  @override
  Stream<List<DiscoveredDevice>> get discoveredDevices =>
      _discoveredDevicesController.stream;

  @override
  Stream<P2PConnection> get incomingConnections =>
      _incomingConnectionsController.stream;

  @override
  Future<bool> connect(DiscoveredDevice device) async {
    if (!_initialized) return false;
    _connectedDevices.add(device.id);
    return true;
  }

  @override
  Future<bool> acceptConnection(P2PConnection connection) async {
    if (!_initialized) return false;
    _connectedDevices.add(connection.remoteDeviceId);
    return true;
  }

  @override
  Future<void> sendData(String deviceId, Uint8List data) async {
    sentDataLog.add((deviceId: deviceId, data: data));
  }

  @override
  Stream<({String deviceId, Uint8List data})> get receivedData =>
      _receivedDataController.stream;

  @override
  Future<void> disconnect(String deviceId) async {
    _connectedDevices.remove(deviceId);
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    _advertising = false;
    _discovering = false;
    _connectedDevices.clear();
    sentDataLog.clear();

    await _discoveredDevicesController.close();
    await _incomingConnectionsController.close();
    await _receivedDataController.close();
  }
}
