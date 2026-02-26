import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nearby_service/nearby_service.dart';

import 'package:everypay/data/transport/p2p_transport.dart';

/// [P2PTransport] implementation backed by the `nearby_service` package.
///
/// Uses Wi-Fi Direct on Android and Multipeer Connectivity on iOS/macOS.
///
/// ## Lifecycle
/// 1. Call [initialize] to set up the platform service and request permissions.
/// 2. Call [startAdvertising] **or** [startDiscovery] (or both, if the
///    platform supports it).
/// 3. Use [connect] / [acceptConnection] to establish a link.
/// 4. Exchange data with [sendData] and [receivedData].
/// 5. Call [disconnect] or [dispose] to tear down.
class NearbyTransport implements P2PTransport {
  /// Create a [NearbyTransport].
  ///
  /// An optional [nearbyService] can be injected for testing; if omitted the
  /// platform-appropriate service is obtained via [NearbyService.getInstance].
  NearbyTransport({NearbyService? nearbyService})
    : _nearbyService = nearbyService;

  NearbyService? _nearbyService;
  bool _initialized = false;
  String _deviceName = '';

  /// The ID of the device we are currently connected to (if any).
  String? _connectedDeviceId;

  /// Subscription to the peers stream from nearby_service.
  StreamSubscription<List<NearbyDevice>>? _peersSubscription;

  /// Subscription to the communication channel state stream.
  StreamSubscription<CommunicationChannelState>? _channelStateSubscription;

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
  // P2PTransport interface
  // ---------------------------------------------------------------------------

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      _nearbyService ??= NearbyService.getInstance();

      // Android requires explicit permission requests and a Wi-Fi check.
      if (Platform.isAndroid) {
        final android = _nearbyService!.android;
        if (android != null) {
          final permGranted = await android.requestPermissions();
          if (!permGranted) return false;

          final wifiOk = await android.checkWifiService();
          if (!wifiOk) return false;
        }
      }

      final result = await _nearbyService!.initialize(
        data: NearbyInitializeData(darwinDeviceName: _deviceName),
      );

      if (result) {
        _initialized = true;
        _startListeningForPeers();
      }

      return result;
    } catch (e) {
      _initialized = false;
      return false;
    }
  }

  @override
  Future<void> startAdvertising(String deviceName) async {
    _deviceName = deviceName;

    if (!_initialized) return;

    try {
      // On iOS/macOS, advertising is done by setting isBrowser=false then
      // calling discover(). On Android, discover() finds all peers and
      // any device in the network is implicitly visible.
      final darwin = _nearbyService!.darwin;
      if (darwin != null) {
        darwin.setIsBrowser(value: false);
        await darwin.discover();
      }
      // On Android the device is visible once discover() is called.
      // We start discovery in startDiscovery(); advertising is implicit.
    } catch (_) {
      // Swallow — real device issues should not crash the app.
    }
  }

  @override
  Future<void> stopAdvertising() async {
    if (!_initialized) return;

    try {
      final darwin = _nearbyService!.darwin;
      if (darwin != null && !darwin.isBrowserValue) {
        await darwin.stopDiscovery();
      }
    } catch (_) {}
  }

  @override
  Future<void> startDiscovery() async {
    if (!_initialized) return;

    try {
      final darwin = _nearbyService!.darwin;
      if (darwin != null) {
        darwin.setIsBrowser(value: true);
      }

      await _nearbyService!.discover();
    } catch (_) {}
  }

  @override
  Future<void> stopDiscovery() async {
    if (!_initialized) return;

    try {
      await _nearbyService!.stopDiscovery();
    } catch (_) {}
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

    try {
      final result = await _nearbyService!.connectById(device.id);

      if (result) {
        _connectedDeviceId = device.id;
        _startCommunicationChannel(device.id);
      }

      return result;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> acceptConnection(P2PConnection connection) async {
    if (!_initialized) return false;

    try {
      final result = await _nearbyService!.connectById(
        connection.remoteDeviceId,
      );

      if (result) {
        _connectedDeviceId = connection.remoteDeviceId;
        _startCommunicationChannel(connection.remoteDeviceId);
      }

      return result;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendData(String deviceId, Uint8List data) async {
    if (!_initialized) return;

    try {
      final base64Data = base64Encode(data);
      final message = OutgoingNearbyMessage(
        content: NearbyMessageTextRequest.create(value: base64Data),
        receiver: NearbyDeviceInfo(displayName: '', id: deviceId),
      );
      await _nearbyService!.send(message);
    } catch (_) {}
  }

  @override
  Stream<({String deviceId, Uint8List data})> get receivedData =>
      _receivedDataController.stream;

  @override
  Future<void> disconnect(String deviceId) async {
    if (!_initialized) return;

    try {
      await _nearbyService!.endCommunicationChannel();
      await _nearbyService!.disconnectById(deviceId);
      _connectedDeviceId = null;
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    try {
      await _channelStateSubscription?.cancel();
      _channelStateSubscription = null;

      await _peersSubscription?.cancel();
      _peersSubscription = null;

      if (_initialized && _connectedDeviceId != null) {
        await _nearbyService!.endCommunicationChannel();
        await _nearbyService!.disconnectById(_connectedDeviceId);
        _connectedDeviceId = null;
      }

      if (_initialized) {
        await _nearbyService!.stopDiscovery();
      }
    } catch (_) {}

    _initialized = false;

    await _discoveredDevicesController.close();
    await _incomingConnectionsController.close();
    await _receivedDataController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Start listening to the peer-list stream from [NearbyService] and map
  /// the platform [NearbyDevice] objects to our [DiscoveredDevice] model.
  void _startListeningForPeers() {
    _peersSubscription?.cancel();
    _peersSubscription = _nearbyService!.getPeersStream().listen(
      (peers) {
        final devices = <DiscoveredDevice>[];

        for (final peer in peers) {
          final device = DiscoveredDevice(
            id: peer.info.id,
            name: peer.info.displayName,
          );

          devices.add(device);

          // Emit incoming-connection events for devices that are connecting
          // to us (i.e. we are the advertiser / group owner).
          if (peer.status == NearbyDeviceStatus.connecting) {
            _incomingConnectionsController.add(
              P2PConnection(
                remoteDeviceId: peer.info.id,
                remoteName: peer.info.displayName,
              ),
            );
          }
        }

        if (!_discoveredDevicesController.isClosed) {
          _discoveredDevicesController.add(devices);
        }
      },
      onError: (_) {
        // Emit empty list on error so UI doesn't freeze.
        if (!_discoveredDevicesController.isClosed) {
          _discoveredDevicesController.add(const []);
        }
      },
    );
  }

  /// Open the communication channel for the connected [deviceId] and begin
  /// forwarding received messages to [_receivedDataController].
  void _startCommunicationChannel(String deviceId) {
    try {
      _channelStateSubscription?.cancel();
      _channelStateSubscription = _nearbyService!
          .getCommunicationChannelStateStream()
          .listen((_) {});

      _nearbyService!.startCommunicationChannel(
        NearbyCommunicationChannelData(
          deviceId,
          messagesListener: NearbyServiceMessagesListener(
            onData: (ReceivedNearbyMessage message) {
              _handleReceivedMessage(message);
            },
          ),
        ),
      );
    } catch (_) {}
  }

  /// Decode incoming text messages (base64-encoded binary) and push them
  /// onto the [receivedData] stream.
  void _handleReceivedMessage(ReceivedNearbyMessage message) {
    try {
      final content = message.content;
      if (content is NearbyMessageTextRequest) {
        final bytes = base64Decode(content.value);
        if (!_receivedDataController.isClosed) {
          _receivedDataController.add((
            deviceId: message.sender.id,
            data: Uint8List.fromList(bytes),
          ));
        }
      }
    } catch (_) {
      // Ignore malformed messages.
    }
  }
}
