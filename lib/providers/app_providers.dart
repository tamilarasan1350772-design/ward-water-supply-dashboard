import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_reading.dart';
import '../models/dashboard_stats.dart';
import '../repositories/water_reading_repository.dart';
import '../services/connection_service.dart';
import '../services/mock_api_service.dart';
import '../services/sync_service.dart';

final waterReadingRepositoryProvider = Provider<WaterReadingRepository>((ref) {
  return WaterReadingRepository();
});

final mockApiServiceProvider = Provider<MockApiService>((ref) {
  return MockApiService();
});

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return ConnectionService();
});

final connectionStateProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectionServiceProvider);
  return service.onConnectivityChanged;
});

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final repository = ref.watch(waterReadingRepositoryProvider);
  final apiService = ref.watch(mockApiServiceProvider);
  final connectionService = ref.watch(connectionServiceProvider);
  return SyncService(
    repository: repository,
    apiService: apiService,
    connectionService: connectionService,
  );
});

final darkModeProvider = StateProvider<bool>((ref) => false);

class WaterReadingsNotifier extends StateNotifier<AsyncValue<List<WaterReading>>> {
  final WaterReadingRepository _repository;
  final SyncService _syncService;

  WaterReadingsNotifier(this._repository, this._syncService) : super(const AsyncValue.loading()) {
    loadReadings();
  }

  Future<void> loadReadings() async {
    state = const AsyncValue.loading();
    try {
      final readings = await _repository.getAllReadings();
      state = AsyncValue.data(readings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    try {
      await _syncService.syncPendingReadings();
      final readings = await _repository.getAllReadings();
      state = AsyncValue.data(readings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addReading(WaterReading reading) async {
    try {
      await _repository.insertReading(reading);
      await loadReadings();

      await _syncService.syncPendingReadings();
      await loadReadings();
    } catch (e) {
      // Keep state
    }
  }

  Future<void> addReadingsBulk(List<WaterReading> readings) async {
    try {
      await _repository.insertMultipleReadings(readings);
      await loadReadings();

      await _syncService.syncPendingReadings();
      await loadReadings();
    } catch (e) {
      // Keep state
    }
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadReadings();
  }
}

final waterReadingsProvider = StateNotifierProvider<WaterReadingsNotifier, AsyncValue<List<WaterReading>>>((ref) {
  final repo = ref.watch(waterReadingRepositoryProvider);
  final sync = ref.watch(syncServiceProvider);
  return WaterReadingsNotifier(repo, sync);
});

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final readingsAsyncValue = ref.watch(waterReadingsProvider);
  return readingsAsyncValue.maybeWhen(
    data: (readings) => DashboardStats.fromList(readings),
    orElse: () => DashboardStats.fromList([]),
  );
});
