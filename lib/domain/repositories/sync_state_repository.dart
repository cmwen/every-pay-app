import 'package:everypay/domain/entities/sync_state.dart';

abstract class SyncStateRepository {
  Future<SyncState?> getSyncState(String deviceId);
  Future<void> upsertSyncState(SyncState state);
  Future<void> deleteSyncState(String deviceId);
}
