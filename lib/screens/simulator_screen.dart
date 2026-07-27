import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../models/water_reading.dart';
import '../providers/app_providers.dart';

class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  Timer? _simulationTimer;
  bool _isSimulating = false;
  int _ticks = 0;
  final List<String> _simulatedLogs = [];
  final Random _random = Random();

  void _toggleSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() {
        _isSimulating = false;
      });
      _addLog("Simulation Stopped.");
    } else {
      setState(() {
        _isSimulating = true;
        _ticks = 0;
      });
      _addLog("Simulation Started. Generating telemetry every 4 seconds...");

      _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        _generateTelemetry();
      });
    }
  }

  void _generateTelemetry() async {
    _ticks++;
    final uuid = const Uuid();
    final now = DateTime.now();

    final ward = AppConstants.wards[_random.nextInt(AppConstants.wards.length)];
    final deviceId = 'DEV-SIM-${_random.nextInt(10) + 200}';

    double? flow;
    String valveState = 'OPEN';
    final roll = _random.nextDouble();

    if (roll < 0.75) {
      flow = 150.0 + _random.nextDouble() * 350.0;
      valveState = _random.nextBool() ? 'OPEN' : 'HALF-OPEN';
      _addLog("Tick #$_ticks: Normal reading ($ward -> ${flow.toStringAsFixed(1)}L).");
    } else if (roll < 0.85) {
      flow = null;
      valveState = 'OPEN';
      _addLog("Tick #$_ticks: Missing value reading generated for $ward (NULL L).");
    } else if (roll < 0.95) {
      flow = 12000.0 + _random.nextDouble() * 4000;
      valveState = 'OPEN';
      _addLog("Tick #$_ticks: WARNING! Extreme high flow anomaly ($ward -> ${flow.toStringAsFixed(1)}L).");
    } else {
      flow = 777.77;
      valveState = 'CLOSED';
      _addLog("Tick #$_ticks: Anomaly stuck reading ($ward -> 777.77L but Valve is CLOSED).");
    }

    final reading = WaterReading(
      readingId: uuid.v4(),
      ward: ward,
      flowLitres: flow,
      valveState: valveState,
      recordedAt: now,
      deviceId: deviceId,
      syncStatus: SyncStatus.pending,
    );

    await ref.read(waterReadingsProvider.notifier).addReading(reading);
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _simulatedLogs.insert(0, "[${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8)}] $msg");
      if (_simulatedLogs.length > 50) {
        _simulatedLogs.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Telemetry Simulator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: _isSimulating
                  ? AppColors.primaryBlue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _isSimulating ? Icons.autorenew_rounded : Icons.pause_circle_outline,
                      size: 64,
                      color: _isSimulating ? AppColors.primaryBlue : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSimulating ? 'SIMULATOR ACTIVE' : 'SIMULATOR IDLE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isSimulating ? AppColors.primaryBlue : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This simulator issues simulated water telemetry directly into local storage to mimic field sensor transmissions.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSimulating ? AppColors.errorRed : AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _toggleSimulation,
                      icon: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
                      label: Text(_isSimulating ? 'Stop Simulator' : 'Start Simulator'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Real-time Simulator Logs',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: _simulatedLogs.isEmpty
                    ? const Center(
                        child: Text('No telemetry simulated yet. Press Start above.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _simulatedLogs.length,
                        itemBuilder: (context, index) {
                          final log = _simulatedLogs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              log,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
