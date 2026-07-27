import '../models/water_reading.dart';

class DashboardStats {
  final int totalReadings;
  final int pendingSyncCount;
  final int todayReadings;
  final double averageFlow;
  final Map<String, double> wardWiseTotalSupply;
  final Map<String, double> wardWiseAverageSupply;
  final String highestFlowWard;
  final String lowestFlowWard;
  final int faultyCount;
  final List<WaterReading> recentReadings;

  DashboardStats({
    required this.totalReadings,
    required this.pendingSyncCount,
    required this.todayReadings,
    required this.averageFlow,
    required this.wardWiseTotalSupply,
    required this.wardWiseAverageSupply,
    required this.highestFlowWard,
    required this.lowestFlowWard,
    required this.faultyCount,
    required this.recentReadings,
  });

  factory DashboardStats.fromList(List<WaterReading> readings) {
    if (readings.isEmpty) {
      return DashboardStats(
        totalReadings: 0,
        pendingSyncCount: 0,
        todayReadings: 0,
        averageFlow: 0.0,
        wardWiseTotalSupply: {},
        wardWiseAverageSupply: {},
        highestFlowWard: 'N/A',
        lowestFlowWard: 'N/A',
        faultyCount: 0,
        recentReadings: [],
      );
    }

    final today = DateTime.now();
    int todayCount = 0;
    int pendingCount = 0;
    int faulty = 0;
    double totalFlowSum = 0.0;
    int validFlowCount = 0;

    Map<String, List<double>> wardFlows = {};

    for (var r in readings) {
      if (r.syncStatus == SyncStatus.pending || r.syncStatus == SyncStatus.failed) {
        pendingCount++;
      }

      if (r.recordedAt.year == today.year &&
          r.recordedAt.month == today.month &&
          r.recordedAt.day == today.day) {
        todayCount++;
      }

      if (r.isFaulty) {
        faulty++;
      }

      if (r.flowLitres != null) {
        validFlowCount++;
        totalFlowSum += r.flowLitres!;
        wardFlows.putIfAbsent(r.ward, () => []).add(r.flowLitres!);
      }
    }

    Map<String, double> totals = {};
    Map<String, double> averages = {};
    String maxWard = 'N/A';
    double maxWardAvg = -1.0;
    String minWard = 'N/A';
    double minWardAvg = double.maxFinite;

    wardFlows.forEach((ward, flows) {
      final sum = flows.fold(0.0, (prev, element) => prev + element);
      final avg = sum / flows.length;
      totals[ward] = sum;
      averages[ward] = avg;

      if (avg > maxWardAvg) {
        maxWardAvg = avg;
        maxWard = ward;
      }
      if (avg < minWardAvg) {
        minWardAvg = avg;
        minWard = ward;
      }
    });

    return DashboardStats(
      totalReadings: readings.length,
      pendingSyncCount: pendingCount,
      todayReadings: todayCount,
      averageFlow: validFlowCount > 0 ? totalFlowSum / validFlowCount : 0.0,
      wardWiseTotalSupply: totals,
      wardWiseAverageSupply: averages,
      highestFlowWard: maxWard,
      lowestFlowWard: minWard == double.maxFinite.toString() ? 'N/A' : minWard,
      faultyCount: faulty,
      recentReadings: readings.take(10).toList(),
    );
  }
}
