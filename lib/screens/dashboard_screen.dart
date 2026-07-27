import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_reading.dart';
import '../providers/app_providers.dart';
import '../widgets/stat_card.dart';
import '../widgets/water_reading_tile.dart';
import '../widgets/water_supply_chart.dart';
import '../widgets/custom_dialogs.dart';
import '../constants/app_constants.dart';
import '../utils/sample_data_seeder.dart';
import 'capture_screen.dart';
import 'search_screen.dart';
import 'simulator_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(darkModeProvider);
    final isConnected = ref.watch(connectionStateProvider).value ?? true;

    final readingsAsync = ref.watch(waterReadingsProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final syncState = ref.watch(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Equity Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Search & Filters',
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(darkModeProvider.notifier).state = !isDark;
            },
          ),
          IconButton(
            tooltip: 'Simulator Module',
            icon: const Icon(Icons.speed),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SimulatorScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(waterReadingsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: isConnected
                    ? AppColors.successGreen.withOpacity(0.9)
                    : AppColors.errorRed.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected
                          ? "Online Mode: Auto-sync telemetry active"
                          : "Offline Mode: Telemetry queued locally",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isConnected,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green[800],
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.red[800],
                      onChanged: (val) async {
                        await ref.read(connectionServiceProvider).setConnected(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'Switched to simulated ONLINE network state.'
                                : 'Switched to simulated OFFLINE network state.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              readingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    color: AppColors.errorRed.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: AppColors.errorRed, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Database/Loading Error',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(err.toString(), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (readings) {
                  if (readings.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers_clear, size: 80, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text(
                            'No Water Telemetry Loaded',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Local database is empty. You can generate sample data or add a record to begin monitoring.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final samples = SampleDataSeeder.generateSampleReadings();
                              await ref.read(waterReadingsProvider.notifier).addReadingsBulk(samples);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Seeded database with 40 diverse sample records.')),
                              );
                            },
                            icon: const Icon(Icons.grid_view),
                            label: const Text('Seed 40 Sample Records'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Key Telemetry KPI Overview',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (syncState.isSyncing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GridView.count(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.6,
                          children: [
                            StatCard(
                              title: 'Total Readings',
                              value: '${stats.totalReadings}',
                              icon: Icons.assignment,
                              color: AppColors.primaryBlue,
                            ),
                            StatCard(
                              title: 'Pending Sync',
                              value: '${stats.pendingSyncCount}',
                              icon: Icons.cloud_upload,
                              color: AppColors.warningOrange,
                              onTap: () async {
                                if (stats.pendingSyncCount > 0) {
                                  await ref.read(syncServiceProvider).syncPendingReadings();
                                  await ref.read(waterReadingsProvider.notifier).loadReadings();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Triggered immediate sync. Pending now: ${stats.pendingSyncCount}')),
                                  );
                                }
                              },
                            ),
                            StatCard(
                              title: "Today's Telemetry",
                              value: '${stats.todayReadings}',
                              icon: Icons.today,
                              color: AppColors.accentCyan,
                            ),
                            StatCard(
                              title: "Average Flow Rate",
                              value: '${stats.averageFlow.toStringAsFixed(1)} L',
                              icon: Icons.speed,
                              color: AppColors.primaryDarkBlue,
                            ),
                            StatCard(
                              title: "Highest Flow",
                              value: stats.highestFlowWard.replaceAll('Ward ', ''),
                              icon: Icons.trending_up,
                              color: AppColors.successGreen,
                            ),
                            StatCard(
                              title: "Faulty / Anomaly",
                              value: '${stats.faultyCount}',
                              icon: Icons.gpp_maybe,
                              color: AppColors.errorRed,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: WardWaterSupplyChart(wardSupply: stats.wardWiseTotalSupply),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await ref.read(waterReadingsProvider.notifier).clearAll();
                                ref.read(mockApiServiceProvider).resetServerDb();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Database and Mock server records successfully cleared.')),
                                );
                              },
                              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                              icon: const Icon(Icons.delete_sweep),
                              label: const Text('Reset DB'),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final samples = SampleDataSeeder.generateSampleReadings();
                                await ref.read(waterReadingsProvider.notifier).addReadingsBulk(samples);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Seeded additional 40 records.')),
                                );
                              },
                              icon: const Icon(Icons.add_to_photos),
                              label: const Text('Add 40 Sample Records'),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Flow Readings (${stats.recentReadings.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Pull down to Sync',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.recentReadings.length,
                        itemBuilder: (context, index) {
                          final reading = stats.recentReadings[index];
                          return WaterReadingListTile(
                            reading: reading,
                            onTap: () {
                              CustomDialogs.showReadingDetails(
                                context: context,
                                ward: reading.ward,
                                flow: reading.flowLitres != null ? reading.flowLitres!.toStringAsFixed(2) : null,
                                valveState: reading.valveState,
                                deviceId: reading.deviceId,
                                recordedAt: reading.recordedAt.toLocal().toString(),
                                syncStatus: reading.syncStatus.name,
                                isFaulty: reading.isFaulty,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Reading'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CaptureScreen()),
          );
        },
      ),
    );
  }
}
