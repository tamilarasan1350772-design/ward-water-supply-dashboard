import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class WardWaterSupplyChart extends StatelessWidget {
  final Map<String, double> wardSupply;

  const WardWaterSupplyChart({super.key, required this.wardSupply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (wardSupply.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No water supply data available to chart.'),
        ),
      );
    }

    final List<String> wardsList = AppConstants.wards;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < wardsList.length; i++) {
      final wardName = wardsList[i];
      final val = wardSupply[wardName] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: AppColors.primaryBlue,
              width: 18,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: wardSupply.values.isEmpty
                    ? 100
                    : wardSupply.values.reduce((curr, next) => curr > next ? curr : next) * 1.1,
                color: isDark ? Colors.blueGrey[800] : Colors.grey[200],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Supply Volume distribution per Ward (Litres)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: wardSupply.values.isEmpty
                    ? 100
                    : wardSupply.values.reduce((curr, next) => curr > next ? curr : next) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDarkBlue,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final wardName = wardsList[group.x];
                      return BarTooltipItem(
                        '$wardName\n${rod.toY.toStringAsFixed(1)} Litres',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < wardsList.length) {
                          final label = wardsList[idx]
                              .replaceAll('Ward ', '')
                              .replaceAll(' (Central)', '')
                              .replaceAll(' (North)', '')
                              .replaceAll(' (East)', '')
                              .replaceAll(' (South)', '')
                              .replaceAll(' (West)', '');
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                groupsSpace: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
