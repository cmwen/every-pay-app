import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/domain/entities/paired_device.dart';
import 'package:everypay/domain/repositories/paired_devices_repository.dart';

class SqlitePairedDevicesRepository implements PairedDevicesRepository {
  final _changeController = StreamController<void>.broadcast();

  Map<String, dynamic> _toMap(PairedDevice d) => {
    'id': d.id,
    'device_name': d.deviceName,
    'device_id': d.deviceId,
    'paired_at': d.pairedAt.toIso8601String(),
    'last_seen': d.lastSeen?.toIso8601String(),
    'public_key': d.publicKey,
    'is_active': d.isActive ? 1 : 0,
  };

  PairedDevice _fromMap(Map<String, dynamic> m) => PairedDevice(
    id: m['id'] as String,
    deviceName: m['device_name'] as String,
    deviceId: m['device_id'] as String,
    pairedAt: DateTime.parse(m['paired_at'] as String),
    lastSeen: m['last_seen'] != null
        ? DateTime.parse(m['last_seen'] as String)
        : null,
    publicKey: m['public_key'] as String?,
    isActive: m['is_active'] == 1,
  );

  @override
  Stream<List<PairedDevice>> watchPairedDevices() async* {
    yield await _queryAll();
    await for (final _ in _changeController.stream) {
      yield await _queryAll();
    }
  }

  Future<List<PairedDevice>> _queryAll() async {
    final db = await DatabaseHelper.database;
    final results = await db.query('paired_devices', orderBy: 'paired_at DESC');
    return results.map(_fromMap).toList();
  }

  @override
  Future<PairedDevice?> getByDeviceId(String deviceId) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'paired_devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  @override
  Future<void> upsertPairedDevice(PairedDevice device) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'paired_devices',
      _toMap(device),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  @override
  Future<void> deletePairedDevice(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('paired_devices', where: 'id = ?', whereArgs: [id]);
    _changeController.add(null);
  }

  @override
  Future<List<PairedDevice>> getActivePairedDevices() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'paired_devices',
      where: 'is_active = 1',
      orderBy: 'paired_at DESC',
    );
    return results.map(_fromMap).toList();
  }

  @override
  Future<void> updateLastSeen(String deviceId, DateTime lastSeen) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'paired_devices',
      {'last_seen': lastSeen.toIso8601String()},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    _changeController.add(null);
  }

  void dispose() {
    _changeController.close();
  }
}
