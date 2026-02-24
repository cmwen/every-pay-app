class PairedDevice {
  final String id;
  final String deviceName;
  final String deviceId;
  final DateTime pairedAt;
  final DateTime? lastSeen;
  final String? publicKey;
  final bool isActive;

  const PairedDevice({
    required this.id,
    required this.deviceName,
    required this.deviceId,
    required this.pairedAt,
    this.lastSeen,
    this.publicKey,
    this.isActive = true,
  });

  PairedDevice copyWith({
    String? id,
    String? deviceName,
    String? deviceId,
    DateTime? pairedAt,
    DateTime? lastSeen,
    String? publicKey,
    bool? isActive,
  }) {
    return PairedDevice(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      pairedAt: pairedAt ?? this.pairedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      publicKey: publicKey ?? this.publicKey,
      isActive: isActive ?? this.isActive,
    );
  }
}
