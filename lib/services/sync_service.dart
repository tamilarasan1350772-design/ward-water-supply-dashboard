import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/water_reading.dart';
import '../repositories/water_reading_repository.dart';
import '../services/connection_service.dart';
import '../services/mock_api_service.dart';

class SyncService extends ChangeNotifier {
  final WaterReadingRepository _repository;
  final MockApiService _apiService;
  final ConnectionService _connectionService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _lastError;
  String? get lastError => _lastError;

  SyncService({
    required WaterReadingRepository repository,
    required MockApiService apiService,
    required ConnectionService connectionService,
  })  : _repository = repository,
        _apiService = apiService,
        _connectionService = connectionService {
    _connectionService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncPendingReadings();
      }
    });
  }

  Future<void> syncPendingReadings() async {
    if (_isSyncing) return;

    final online = await _connectionService.isConnected();
    if (!online) {
      _lastError = "Sync skipped: App is simulated offline.";
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final pendingReadings = await _repository.getPendingSyncReadings();
      if (pendingReadings.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }

      for (var reading in pendingReadings) {
        try {
          final success = await _apiService.uploadReading(reading);
          if (success) {
            await _repository.updateReading(reading.copyWith(syncStatus: SyncStatus.synced));
          }
        } catch (e) {
          await _repository.updateReading(reading.copyWith(syncStatus: SyncStatus.failed));
          _lastError = "Failed to sync: ${e.toString()}";
        }
      }
    } catch (generalError) {
      _lastError = generalError.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
