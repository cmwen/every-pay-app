class SyncPayload {
  final String deviceId;
  final String syncTimestamp;
  final int schemaVersion;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> paymentMethods;

  const SyncPayload({
    required this.deviceId,
    required this.syncTimestamp,
    required this.schemaVersion,
    this.expenses = const [],
    this.categories = const [],
    this.paymentMethods = const [],
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'sync_timestamp': syncTimestamp,
    'schema_version': schemaVersion,
    'expenses': expenses,
    'categories': categories,
    'payment_methods': paymentMethods,
  };

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
    deviceId: json['device_id'] as String,
    syncTimestamp: json['sync_timestamp'] as String,
    schemaVersion: json['schema_version'] as int,
    expenses: (json['expenses'] as List<dynamic>).cast<Map<String, dynamic>>(),
    categories: (json['categories'] as List<dynamic>)
        .cast<Map<String, dynamic>>(),
    paymentMethods: (json['payment_methods'] as List<dynamic>)
        .cast<Map<String, dynamic>>(),
  );
}
