import 'package:uuid/uuid.dart';
import '../models/water_reading.dart';

class SampleDataSeeder {
  static List<WaterReading> generateSampleReadings() {
    final uuid = const Uuid();
    final now = DateTime.now();
    List<WaterReading> readings = [];

    WaterReading buildReading(
      String ward,
      double? flow,
      String valve,
      DateTime time,
      String device,
      SyncStatus status,
    ) {
      return WaterReading(
        readingId: uuid.v4(),
        ward: ward,
        flowLitres: flow,
        valveState: valve,
        recordedAt: time,
        deviceId: device,
        syncStatus: status,
      );
    }

    final normalWards = [
      'Ward A (Central)',
      'Ward B (North)',
      'Ward C (East)',
      'Ward D (South)',
      'Ward E (West)'
    ];

    // 1. Normal Cases (approx 25 records spread across last few days and various wards)
    for (int i = 0; i < 25; i++) {
      final ward = normalWards[i % normalWards.length];
      final flow = 200.0 + (i * 15) % 350;
      final valve = (i % 5 == 0) ? 'HALF-OPEN' : 'OPEN';
      final time = now.subtract(Duration(hours: i * 4));
      final device = 'DEV-${1000 + (i % 4)}';
      final status = (i % 3 == 0) ? SyncStatus.synced : SyncStatus.pending;
      readings.add(buildReading(ward, flow, valve, time, device, status));
    }

    // 2. Missing Value Simulation (approx 5 records with null flow_litres)
    for (int i = 0; i < 5; i++) {
      final ward = normalWards[i % normalWards.length];
      final time = now.subtract(Duration(hours: i * 11 + 2));
      final device = 'DEV-MISS-${i + 1}';
      final status = SyncStatus.pending;
      readings.add(buildReading(ward, null, 'OPEN', time, device, status));
    }

    // 3. Extreme High Value Simulation (approx 5 records representing bursts, high flow anomalies)
    for (int i = 0; i < 5; i++) {
      final ward = normalWards[(i + 2) % normalWards.length];
      final flow = 12000.0 + (i * 1250);
      final valve = 'OPEN';
      final time = now.subtract(Duration(hours: i * 15 + 1));
      final device = 'DEV-EXT-${i + 1}';
      final status = SyncStatus.failed;
      readings.add(buildReading(ward, flow, valve, time, device, status));
    }

    // 4. Faulty / Stuck Reading / Duplicate Value Simulation (approx 5 records with same stuck readings)
    final stuckTimeBase = now.subtract(const Duration(days: 1));
    for (int i = 0; i < 5; i++) {
      final ward = 'Ward C (East)';
      const flow = 888.88;
      final valve = 'OPEN';
      final time = stuckTimeBase.add(Duration(minutes: i * 5));
      const device = 'DEV-STUCK-99';
      final status = SyncStatus.pending;
      readings.add(buildReading(ward, flow, valve, time, device, status));
    }

    return readings;
  }
}
