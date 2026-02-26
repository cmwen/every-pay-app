import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/data/transport/mock_transport.dart';
import 'package:everypay/data/transport/p2p_transport.dart';

void main() {
  late MockP2PTransport transport;

  setUp(() {
    transport = MockP2PTransport();
  });

  tearDown(() async {
    await transport.dispose();
  });

  group('MockP2PTransport', () {
    group('initialization', () {
      test('is not initialized before calling initialize()', () {
        expect(transport.isInitialized, isFalse);
      });

      test('initialize() returns true and sets isInitialized', () async {
        final result = await transport.initialize();
        expect(result, isTrue);
        expect(transport.isInitialized, isTrue);
      });
    });

    group('advertising', () {
      test('startAdvertising sets isAdvertising', () async {
        await transport.initialize();
        await transport.startAdvertising('TestDevice');
        expect(transport.isAdvertising, isTrue);
      });

      test('stopAdvertising clears isAdvertising', () async {
        await transport.initialize();
        await transport.startAdvertising('TestDevice');
        await transport.stopAdvertising();
        expect(transport.isAdvertising, isFalse);
      });
    });

    group('discovery', () {
      test('startDiscovery sets isDiscovering and emits empty list', () async {
        await transport.initialize();

        final future = transport.discoveredDevices.first;
        await transport.startDiscovery();

        final devices = await future;
        expect(devices, isEmpty);
        expect(transport.isDiscovering, isTrue);
      });

      test('stopDiscovery clears isDiscovering and emits empty list', () async {
        await transport.initialize();
        await transport.startDiscovery();

        final future = transport.discoveredDevices.first;
        await transport.stopDiscovery();

        final devices = await future;
        expect(devices, isEmpty);
        expect(transport.isDiscovering, isFalse);
      });

      test('injectDiscoveredDevices emits devices on stream', () async {
        await transport.initialize();

        const fakeDevices = [
          DiscoveredDevice(id: 'dev-1', name: 'Alice'),
          DiscoveredDevice(id: 'dev-2', name: 'Bob'),
        ];

        final future = transport.discoveredDevices.first;
        transport.injectDiscoveredDevices(fakeDevices);

        final devices = await future;
        expect(devices, hasLength(2));
        expect(devices.first.id, 'dev-1');
        expect(devices.last.name, 'Bob');
      });
    });

    group('connections', () {
      test('connect adds device to connectedDeviceIds', () async {
        await transport.initialize();

        const device = DiscoveredDevice(id: 'dev-1', name: 'Alice');
        final result = await transport.connect(device);

        expect(result, isTrue);
        expect(transport.connectedDeviceIds, contains('dev-1'));
      });

      test('connect returns false when not initialized', () async {
        const device = DiscoveredDevice(id: 'dev-1', name: 'Alice');
        final result = await transport.connect(device);
        expect(result, isFalse);
      });

      test('acceptConnection adds device to connectedDeviceIds', () async {
        await transport.initialize();

        const conn = P2PConnection(remoteDeviceId: 'dev-2', remoteName: 'Bob');
        final result = await transport.acceptConnection(conn);

        expect(result, isTrue);
        expect(transport.connectedDeviceIds, contains('dev-2'));
      });

      test('disconnect removes device from connectedDeviceIds', () async {
        await transport.initialize();

        const device = DiscoveredDevice(id: 'dev-1', name: 'Alice');
        await transport.connect(device);
        await transport.disconnect('dev-1');

        expect(transport.connectedDeviceIds, isEmpty);
      });
    });

    group('data exchange', () {
      test('sendData logs sent data', () async {
        await transport.initialize();

        final data = Uint8List.fromList([1, 2, 3, 4]);
        await transport.sendData('dev-1', data);

        expect(transport.sentDataLog, hasLength(1));
        expect(transport.sentDataLog.first.deviceId, 'dev-1');
        expect(transport.sentDataLog.first.data, data);
      });

      test('injectReceivedData emits data on receivedData stream', () async {
        await transport.initialize();

        final payload = Uint8List.fromList([10, 20, 30]);

        final future = transport.receivedData.first;
        transport.injectReceivedData('dev-1', payload);

        final received = await future;
        expect(received.deviceId, 'dev-1');
        expect(received.data, payload);
      });
    });

    group('incoming connections', () {
      test('injectIncomingConnection emits on stream', () async {
        await transport.initialize();

        const conn = P2PConnection(
          remoteDeviceId: 'dev-3',
          remoteName: 'Charlie',
        );

        final future = transport.incomingConnections.first;
        transport.injectIncomingConnection(conn);

        final incoming = await future;
        expect(incoming.remoteDeviceId, 'dev-3');
        expect(incoming.remoteName, 'Charlie');
      });
    });

    group('dispose', () {
      test('dispose resets all state', () async {
        await transport.initialize();
        await transport.startAdvertising('Test');
        await transport.startDiscovery();
        await transport.connect(
          const DiscoveredDevice(id: 'dev-1', name: 'Alice'),
        );
        await transport.sendData('dev-1', Uint8List.fromList([1]));

        await transport.dispose();

        expect(transport.isInitialized, isFalse);
        expect(transport.isAdvertising, isFalse);
        expect(transport.isDiscovering, isFalse);
        expect(transport.connectedDeviceIds, isEmpty);
        expect(transport.sentDataLog, isEmpty);
      });
    });
  });

  group('DiscoveredDevice', () {
    test('equality is based on id', () {
      const a = DiscoveredDevice(id: 'x', name: 'Alice');
      const b = DiscoveredDevice(id: 'x', name: 'Bob');
      const c = DiscoveredDevice(id: 'y', name: 'Alice');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString includes id and name', () {
      const device = DiscoveredDevice(id: 'x', name: 'Alice');
      expect(device.toString(), contains('x'));
      expect(device.toString(), contains('Alice'));
    });
  });

  group('P2PConnection', () {
    test('equality is based on remoteDeviceId', () {
      const a = P2PConnection(remoteDeviceId: 'x', remoteName: 'Alice');
      const b = P2PConnection(remoteDeviceId: 'x', remoteName: 'Bob');
      const c = P2PConnection(remoteDeviceId: 'y', remoteName: 'Alice');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString includes remoteDeviceId and remoteName', () {
      const conn = P2PConnection(remoteDeviceId: 'x', remoteName: 'Alice');
      expect(conn.toString(), contains('x'));
      expect(conn.toString(), contains('Alice'));
    });
  });
}
