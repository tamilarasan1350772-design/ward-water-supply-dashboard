enum SyncStatus {
  pending,
  synced,
  failed,
}

class WaterReading {
  final String readingId;
  final String ward;
  final double? flowLitres; // Nullable for "missing value" simulation
  final String valveState; // e.g., "OPEN", "CLOSED", "HALF-OPEN"
  final DateTime recordedAt;
  final String deviceId;
  final SyncStatus syncStatus;

  WaterReading({
    required this.readingId,
    required this.ward,
    this.flowLitres,
    required this.valveState,
    required this.recordedAt,
    required this.deviceId,
    this.syncStatus = SyncStatus.pending,
  });

  // Determines if this reading is faulty.
  // Faulty criteria:
  // - Flow litres is missing (null)
  // - Flow litres is extremely high (e.g., > 5000 litres)
  // - Valve closed but flow exists or stuck telemetry
  bool get isFaulty {
    if (flowLitres == null) return true;
    if (flowLitres! > 5000) return true; // Extreme high threshold
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'reading_id': readingId,
      'ward': ward,
      'flow_litres': flowLitres,
      'valve_state': valveState,
      'recorded_at': recordedAt.toIso8601String(),
      'device_id': deviceId,
      'sync_status': syncStatus.name,
    };
  }

  factory WaterReading.fromMap(Map<String, dynamic> map) {
    return WaterReading(
      readingId: map['reading_id'] as String,
      ward: map['ward'] as String,
      flowLitres: map['flow_litres'] != null ? (map['flow_litres'] as num).toDouble() : null,
      valveState: map['valve_state'] as String,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      deviceId: map['device_id'] as String,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['sync_status'] as String? ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
    );
  }

  WaterReading copyWith({
    String? readingId,
    String? ward,
    double? flowLitres,
    String? valveState,
    DateTime? recordedAt,
    String? deviceId,
    SyncStatus? syncStatus,
  }) {
    return WaterReading(
      readingId: readingId ?? this.readingId,
      ward: ward ?? this.ward,
      flowLitres: flowLitres ?? this.flowLitres,
      valveState: valveState ?? this.valveState,
      recordedAt: recordedAt ?? this.recordedAt,
      deviceId: deviceId ?? this.deviceId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
