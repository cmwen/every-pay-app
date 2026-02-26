import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:everypay/data/transport/p2p_transport.dart';
import 'package:everypay/domain/entities/paired_device.dart';
import 'package:everypay/features/sync/providers/sync_providers.dart';

enum _PairingPhase {
  initial,
  discovering,
  connecting,
  verification,
  paired,
  error,
}

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  _PairingPhase _phase = _PairingPhase.initial;
  DiscoveredDevice? _selectedDevice;
  String? _verificationCode;
  String? _error;

  String _generateVerificationCode(String localId, String remoteId) {
    final combined = '$localId:$remoteId';
    final hash = sha256.convert(utf8.encode(combined));
    final digits = hash.bytes.take(3).map((b) => (b % 10).toString()).join();
    return digits.padLeft(6, '0');
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _phase = _PairingPhase.discovering;
      _error = null;
    });

    final deviceIdAsync = ref.read(deviceIdProvider);
    final deviceId = switch (deviceIdAsync) {
      AsyncData(:final value) => value,
      _ => 'EveryPay',
    };
    await ref.read(discoveryProvider.notifier).startDiscovery(deviceId);
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _phase = _PairingPhase.connecting;
      _selectedDevice = device;
      _error = null;
    });

    try {
      final transport = ref.read(p2pTransportProvider);

      if (!transport.isInitialized) {
        final ok = await transport.initialize();
        if (!ok) {
          setState(() {
            _phase = _PairingPhase.error;
            _error = 'Failed to initialize transport';
          });
          return;
        }
      }

      final connected = await transport.connect(device);
      if (!connected) {
        setState(() {
          _phase = _PairingPhase.error;
          _error = 'Could not connect to ${device.name}';
        });
        return;
      }

      // Generate verification code
      final localIdAsync = ref.read(deviceIdProvider);
      final localId = switch (localIdAsync) {
        AsyncData(:final value) => value,
        _ => '',
      };
      final code = _generateVerificationCode(localId, device.id);

      setState(() {
        _phase = _PairingPhase.verification;
        _verificationCode = code;
      });
    } catch (e) {
      setState(() {
        _phase = _PairingPhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmPairing() async {
    if (_selectedDevice == null) return;

    try {
      await ref
          .read(pairedDevicesRepositoryProvider)
          .upsertPairedDevice(
            PairedDevice(
              id: const Uuid().v4(),
              deviceName: _selectedDevice!.name,
              deviceId: _selectedDevice!.id,
              pairedAt: DateTime.now(),
              isActive: true,
            ),
          );

      // Stop discovery after successful pairing.
      await ref.read(discoveryProvider.notifier).stopDiscovery();

      if (mounted) {
        setState(() => _phase = _PairingPhase.paired);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _PairingPhase.error;
          _error = 'Failed to save pairing: $e';
        });
      }
    }
  }

  Future<void> _cancelPairing() async {
    if (_selectedDevice != null) {
      try {
        final transport = ref.read(p2pTransportProvider);
        await transport.disconnect(_selectedDevice!.id);
      } catch (_) {
        // Best-effort disconnect.
      }
    }
    await ref.read(discoveryProvider.notifier).stopDiscovery();

    if (mounted) {
      setState(() {
        _phase = _PairingPhase.initial;
        _selectedDevice = null;
        _verificationCode = null;
        _error = null;
      });
    }
  }

  void _tryAgain() {
    setState(() {
      _phase = _PairingPhase.initial;
      _selectedDevice = null;
      _verificationCode = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    ref.read(discoveryProvider.notifier).stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair New Device'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await _cancelPairing();
            if (context.mounted) context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_phase) {
            _PairingPhase.initial => _buildInitialPhase(context),
            _PairingPhase.discovering => _buildDiscoveringPhase(context),
            _PairingPhase.connecting => _buildConnectingPhase(context),
            _PairingPhase.verification => _buildVerificationPhase(context),
            _PairingPhase.paired => _buildPairedPhase(context),
            _PairingPhase.error => _buildErrorPhase(context),
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase: Initial
  // ---------------------------------------------------------------------------
  Widget _buildInitialPhase(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('initial'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_tethering,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Pair a Nearby Device',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure both devices are on the same Wi-Fi network '
              'and have Every-Pay open.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _startDiscovery,
              icon: const Icon(Icons.search),
              label: const Text('Start Discovery'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase: Discovering
  // ---------------------------------------------------------------------------
  Widget _buildDiscoveringPhase(BuildContext context) {
    final theme = Theme.of(context);
    final discoveryState = ref.watch(discoveryProvider);
    final devices = discoveryState.devices;

    return Column(
      key: const ValueKey('discovering'),
      children: [
        const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.radar, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Scanning for nearby devices…',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(onPressed: _cancelPairing, child: const Text('Stop')),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: devices.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.device_unknown,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Looking for devices…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make sure the other device is also discovering.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.phone_android,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _connectToDevice(device),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phase: Connecting
  // ---------------------------------------------------------------------------
  Widget _buildConnectingPhase(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('connecting'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting to ${_selectedDevice?.name ?? "device"}…',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while a secure connection is established.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _cancelPairing,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase: Verification
  // ---------------------------------------------------------------------------
  Widget _buildVerificationPhase(BuildContext context) {
    final theme = Theme.of(context);
    final code = _verificationCode ?? '------';
    // Format as XXX-XXX for readability.
    final formattedCode = '${code.substring(0, 3)} ${code.substring(3)}';

    return Center(
      key: const ValueKey('verification'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Verify Pairing Code',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Confirm this code matches on both devices:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                formattedCode,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _confirmPairing,
              icon: const Icon(Icons.check),
              label: const Text('Codes Match'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cancelPairing,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase: Paired
  // ---------------------------------------------------------------------------
  Widget _buildPairedPhase(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('paired'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Device Paired!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '"${_selectedDevice?.name ?? "Device"}" has been paired '
              'successfully. You can now sync data between devices.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase: Error
  // ---------------------------------------------------------------------------
  Widget _buildErrorPhase(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 80, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'Pairing Failed',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'An unknown error occurred.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _tryAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
