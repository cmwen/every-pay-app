class SyncState {
  final String deviceId;
  final DateTime lastSyncAt;
  final DateTime? lastExpenseSync;
  final DateTime? lastCategorySync;

  const SyncState({
    required this.deviceId,
    required this.lastSyncAt,
    this.lastExpenseSync,
    this.lastCategorySync,
  });

  SyncState copyWith({
    String? deviceId,
    DateTime? lastSyncAt,
    DateTime? lastExpenseSync,
    DateTime? lastCategorySync,
  }) {
    return SyncState(
      deviceId: deviceId ?? this.deviceId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastExpenseSync: lastExpenseSync ?? this.lastExpenseSync,
      lastCategorySync: lastCategorySync ?? this.lastCategorySync,
    );
  }
}
