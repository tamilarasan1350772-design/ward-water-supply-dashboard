import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/water_reading.dart';
import '../constants/app_constants.dart';

class WaterReadingListTile extends StatelessWidget {
  final WaterReading reading;
  final VoidCallback? onTap;

  const WaterReadingListTile({
    super.key,
    required this.reading,
    this.onTap,
  });

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return AppColors.successGreen;
      case SyncStatus.pending:
        return AppColors.warningOrange;
      case SyncStatus.failed:
        return AppColors.errorRed;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.pending:
        return Icons.cloud_queue;
      case SyncStatus.failed:
        return Icons.cloud_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedDate = DateFormat('MMM dd, hh:mm a').format(reading.recordedAt);
    final flowText = reading.flowLitres != null
        ? '${reading.flowLitres!.toStringAsFixed(1)} L'
        : 'Missing';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: reading.isFaulty
            ? BorderSide(color: AppColors.errorRed.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      color: reading.isFaulty
          ? (isDark ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.04))
          : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Tooltip(
          message: reading.isFaulty ? 'Anomalous/Faulty Reading' : 'Healthy flow telemetry',
          child: CircleAvatar(
            backgroundColor: reading.isFaulty
                ? AppColors.errorRed.withOpacity(0.15)
                : AppColors.primaryBlue.withOpacity(0.15),
            child: Icon(
              reading.isFaulty ? Icons.warning_amber_rounded : Icons.water_drop,
              color: reading.isFaulty ? AppColors.errorRed : AppColors.primaryBlue,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reading.ward,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reading.valveState == 'OPEN'
                    ? Colors.green.withOpacity(0.15)
                    : (reading.valveState == 'CLOSED' ? Colors.red.withOpacity(0.15) : Colors.orange.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                reading.valveState,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: reading.valveState == 'OPEN'
                      ? Colors.green
                      : (reading.valveState == 'CLOSED' ? Colors.red : Colors.orange),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.top(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.developer_board, size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(reading.deviceId, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(formattedDate, style: theme.textTheme.bodySmall),
                ],
              ),
              if (reading.isFaulty) ...[
                const SizedBox(height: 4),
                Text(
                  reading.flowLitres == null
                      ? '• Reading completely missing'
                      : '• Critical high/anomaly flow rate detected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              flowText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: reading.flowLitres == null ? AppColors.errorRed : null,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(reading.syncStatus),
                  size: 14,
                  color: _getStatusColor(reading.syncStatus),
                ),
                const SizedBox(width: 4),
                Text(
                  reading.syncStatus.name.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(reading.syncStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
