import 'dart:math';
import '../models/water_reading.dart';

class MockApiService {
  static final List<Map<String, dynamic>> _serverDb = [];

  bool forceNetworkError = false;
  double failureRate = 0.0;

  final _random = Random();

  void resetServerDb() {
    _serverDb.clear();
  }

  int getServerRecordCount() => _serverDb.length;

  List<Map<String, dynamic>> getServerRecords() => List.unmodifiable(_serverDb);

  Future<bool> uploadReading(WaterReading reading) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(300)));

    if (forceNetworkError) {
      throw Exception("Simulated service offline / network unreachable.");
    }

    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw Exception("Simulated sporadic server or connection gateway timeout.");
    }

    final exists = _serverDb.any((element) => element['reading_id'] == reading.readingId);
    if (!exists) {
      _serverDb.add(reading.toMap());
    }

    return true;
  }

  Future<List<String>> uploadMultipleReadings(List<WaterReading> readings) async {
    List<String> successfullyUploadedIds = [];

    for (var reading in readings) {
      try {
        final success = await uploadReading(reading);
        if (success) {
          successfullyUploadedIds.add(reading.readingId);
        }
      } catch (e) {
        break;
      }
    }
    return successfullyUploadedIds;
  }
}
