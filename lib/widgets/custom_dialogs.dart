import 'package:flutter/material.dart';

class CustomDialogs {
  static void showReadingDetails({
    required BuildContext context,
    required String ward,
    required String? flow,
    required String valveState,
    required String deviceId,
    required String recordedAt,
    required String syncStatus,
    required bool isFaulty,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isFaulty ? Icons.warning_amber_rounded : Icons.water_drop,
                color: isFaulty ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reading Telemetry Detail',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow(context, 'Ward', ward),
                _buildRow(context, 'Flow Litres', flow ?? 'Missing (NULL)', isRed: flow == null),
                _buildRow(context, 'Valve State', valveState),
                _buildRow(context, 'Device ID', deviceId),
                _buildRow(context, 'Recorded At', recordedAt),
                _buildRow(context, 'Sync Status', syncStatus.toUpperCase(),
                    isGreen: syncStatus == 'synced', isOrange: syncStatus == 'pending', isRed: syncStatus == 'failed'),
                if (isFaulty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: Anomaly parameters detected on this node.',
                            style: textTheme.bodySmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildRow(
    BuildContext context,
    String label,
    String val, {
    bool isRed = false,
    bool isGreen = false,
    bool isOrange = false,
  }) {
    Color? txtColor;
    if (isRed) txtColor = Colors.red;
    if (isGreen) txtColor = Colors.green;
    if (isOrange) txtColor = Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: txtColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
