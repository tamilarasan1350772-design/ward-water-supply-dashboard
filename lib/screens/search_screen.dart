import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/water_reading.dart';
import '../providers/app_providers.dart';
import '../widgets/water_reading_tile.dart';
import '../widgets/custom_dialogs.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchWard = '';
  String _searchDeviceId = '';
  String _searchValveState = '';
  String _selectedDateFilter = 'All';

  List<WaterReading> _filteredReadings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(waterReadingRepositoryProvider);

    DateTime? startDate;
    final now = DateTime.now();

    if (_selectedDateFilter == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedDateFilter == 'Last 7 Days') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedDateFilter == 'Last 30 Days') {
      startDate = now.subtract(const Duration(days: 30));
    }

    final results = await repo.queryReadings(
      ward: _searchWard.isEmpty ? null : _searchWard,
      deviceId: _searchDeviceId.trim().isEmpty ? null : _searchDeviceId.trim(),
      valveState: _searchValveState.isEmpty ? null : _searchValveState,
      startDate: startDate,
    );

    setState(() {
      _filteredReadings = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filters'),
      ),
      body: Column(
        children: [
          Card(
            elevation: 3,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.filter_alt, color: AppColors.primaryBlue),
              title: const Text('Filter Parameters Panel', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Filter Ward',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        value: _searchWard.isEmpty ? null : _searchWard,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All Wards')),
                          ...AppConstants.wards.map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        ],
                        onChanged: (val) {
                          _searchWard = val ?? '';
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Device ID Node',
                          isDense: true,
                          prefixIcon: Icon(Icons.developer_board, size: 18),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          _searchDeviceId = val;
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Filter Valve State',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        value: _searchValveState.isEmpty ? null : _searchValveState,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All Valve States')),
                          ...AppConstants.valveStates.map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        ],
                        onChanged: (val) {
                          _searchValveState = val ?? '';
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['All', 'Today', 'Last 7 Days', 'Last 30 Days'].map((filter) {
                          final isSelected = _selectedDateFilter == filter;
                          return ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedDateFilter = filter;
                                });
                                _applyFilters();
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReadings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: theme.disabledColor),
                            const SizedBox(height: 12),
                            Text(
                              'No Matching Telemetry Records',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Try updating your filter options above.', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredReadings.length,
                        itemBuilder: (context, index) {
                          final r = _filteredReadings[index];
                          return WaterReadingListTile(
                            reading: r,
                            onTap: () {
                              CustomDialogs.showReadingDetails(
                                context: context,
                                ward: r.ward,
                                flow: r.flowLitres != null ? r.flowLitres!.toStringAsFixed(2) : null,
                                valveState: r.valveState,
                                deviceId: r.deviceId,
                                recordedAt: r.recordedAt.toLocal().toString(),
                                syncStatus: r.syncStatus.name,
                                isFaulty: r.isFaulty,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
