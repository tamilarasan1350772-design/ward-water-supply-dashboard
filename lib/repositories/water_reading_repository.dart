import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/water_reading.dart';

class WaterReadingRepository {
  final DatabaseHelper _dbHelper;

  WaterReadingRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertReading(WaterReading reading) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'water_readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMultipleReadings(List<WaterReading> readings) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var reading in readings) {
      batch.insert(
        'water_readings',
        reading.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<WaterReading>> getAllReadings() async {
    final db = await _dbHelper.database;
    final maps = await db.query('water_readings', orderBy: 'recorded_at DESC');
    return maps.map((map) => WaterReading.fromMap(map)).toList();
  }

  Future<List<WaterReading>> queryReadings({
    String? ward,
    String? deviceId,
    String? valveState,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (ward != null && ward.isNotEmpty) {
      whereClause += 'ward = ?';
      whereArgs.add(ward);
    }

    if (deviceId != null && deviceId.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'device_id LIKE ?';
      whereArgs.add('%$deviceId%');
    }

    if (valveState != null && valveState.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'valve_state = ?';
      whereArgs.add(valveState);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'datetime(recorded_at) >= datetime(?)';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'datetime(recorded_at) <= datetime(?)';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'water_readings',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'recorded_at DESC',
    );

    return maps.map((map) => WaterReading.fromMap(map)).toList();
  }

  Future<int> updateReading(WaterReading reading) async {
    final db = await _dbHelper.database;
    return await db.update(
      'water_readings',
      reading.toMap(),
      where: 'reading_id = ?',
      whereArgs: [reading.readingId],
    );
  }

  Future<void> updateSyncStatusBulk(List<String> ids, SyncStatus status) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var id in ids) {
      batch.update(
        'water_readings',
        {'sync_status': status.name},
        where: 'reading_id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<WaterReading>> getPendingSyncReadings() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'water_readings',
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: [SyncStatus.pending.name, SyncStatus.failed.name],
    );
    return maps.map((map) => WaterReading.fromMap(map)).toList();
  }

  Future<Map<String, int>> getCounts() async {
    final db = await _dbHelper.database;

    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM water_readings');
    final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM water_readings WHERE sync_status = ?', [SyncStatus.pending.name]);
    final failedResult = await db.rawQuery('SELECT COUNT(*) as count FROM water_readings WHERE sync_status = ?', [SyncStatus.failed.name]);
    final syncedResult = await db.rawQuery('SELECT COUNT(*) as count FROM water_readings WHERE sync_status = ?', [SyncStatus.synced.name]);

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'pending': Sqflite.firstIntValue(pendingResult) ?? 0,
      'failed': Sqflite.firstIntValue(failedResult) ?? 0,
      'synced': Sqflite.firstIntValue(syncedResult) ?? 0,
    };
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('water_readings');
  }
}
