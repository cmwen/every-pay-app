import 'package:everypay/domain/entities/paired_device.dart';

abstract class PairedDevicesRepository {
  Stream<List<PairedDevice>> watchPairedDevices();
  Future<PairedDevice?> getByDeviceId(String deviceId);
  Future<void> upsertPairedDevice(PairedDevice device);
  Future<void> deletePairedDevice(String id);
  Future<List<PairedDevice>> getActivePairedDevices();
  Future<void> updateLastSeen(String deviceId, DateTime lastSeen);
}
