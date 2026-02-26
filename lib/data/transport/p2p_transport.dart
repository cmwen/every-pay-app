import 'dart:typed_data';

/// Represents a discovered device during P2P scanning.
class DiscoveredDevice {
  /// The platform-specific identifier for the device.
  ///
  /// On Android this is the MAC address; on iOS it is the MCPeerID.
  final String id;

  /// The human-readable name of the device on the P2P network.
  final String name;

  const DiscoveredDevice({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DiscoveredDevice(id: $id, name: $name)';
}

/// Represents an active P2P connection to a remote device.
class P2PConnection {
  /// The platform-specific identifier of the connected remote device.
  final String remoteDeviceId;

  /// The human-readable name of the connected remote device.
  final String remoteName;

  const P2PConnection({required this.remoteDeviceId, required this.remoteName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is P2PConnection &&
          runtimeType == other.runtimeType &&
          remoteDeviceId == other.remoteDeviceId;

  @override
  int get hashCode => remoteDeviceId.hashCode;

  @override
  String toString() =>
      'P2PConnection(remoteDeviceId: $remoteDeviceId, remoteName: $remoteName)';
}

/// Abstract P2P transport layer.
///
/// Provides a platform-agnostic interface for discovering nearby devices,
/// establishing connections, and exchanging binary data over a P2P network.
///
/// Implementations include [NearbyTransport] for real device communication
/// and [MockP2PTransport] for testing without physical devices.
abstract class P2PTransport {
  /// Initialize the transport (request permissions, set up platform service).
  ///
  /// Returns `true` if initialization was successful, `false` otherwise.
  Future<bool> initialize();

  /// Start advertising this device so it is discoverable by nearby peers.
  ///
  /// [deviceName] is the human-readable name shown to other devices.
  Future<void> startAdvertising(String deviceName);

  /// Stop advertising this device.
  Future<void> stopAdvertising();

  /// Start discovering nearby devices that are advertising.
  Future<void> startDiscovery();

  /// Stop the discovery process.
  Future<void> stopDiscovery();

  /// A continuously-updating stream of discovered devices.
  ///
  /// Emits a new list each time the set of visible devices changes.
  /// Emits an empty list when no devices are found or after discovery stops.
  Stream<List<DiscoveredDevice>> get discoveredDevices;

  /// Stream of incoming connection requests from remote devices.
  ///
  /// Each event represents a new connection request that can be accepted
  /// via [acceptConnection].
  Stream<P2PConnection> get incomingConnections;

  /// Initiate a connection to a [device] that was found during discovery.
  ///
  /// Returns `true` if the connection request was sent successfully.
  Future<bool> connect(DiscoveredDevice device);

  /// Accept an incoming [connection] request from a remote device.
  ///
  /// Returns `true` if the connection was accepted successfully.
  Future<bool> acceptConnection(P2PConnection connection);

  /// Send binary [data] to the device identified by [deviceId].
  ///
  /// The device must already be connected and have an active communication
  /// channel.
  Future<void> sendData(String deviceId, Uint8List data);

  /// Stream of binary data received from connected devices.
  ///
  /// Each event contains the [deviceId] of the sender and the raw [data].
  Stream<({String deviceId, Uint8List data})> get receivedData;

  /// Disconnect from the device identified by [deviceId].
  Future<void> disconnect(String deviceId);

  /// Disconnect from all devices and release all resources.
  ///
  /// After calling dispose, the transport must be re-initialized before use.
  Future<void> dispose();

  /// Whether [initialize] has been called successfully.
  bool get isInitialized;
}
