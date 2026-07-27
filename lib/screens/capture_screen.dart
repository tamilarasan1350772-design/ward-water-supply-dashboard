import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../models/water_reading.dart';
import '../providers/app_providers.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedWard;
  String? _selectedValveState;
  final _flowController = TextEditingController();
  final _deviceIdController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  bool _isMissingFlow = false;

  @override
  void initState() {
    super.initState();
    _deviceIdController.text = 'DEV-MAN-99';
  }

  @override
  void dispose() {
    _flowController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? flowVal = _isMissingFlow
        ? null
        : double.tryParse(_flowController.text.trim());

    final reading = WaterReading(
      readingId: const Uuid().v4(),
      ward: _selectedWard!,
      flowLitres: flowVal,
      valveState: _selectedValveState!,
      recordedAt: _selectedDateTime,
      deviceId: _deviceIdController.text.trim(),
      syncStatus: SyncStatus.pending,
    );

    await ref.read(waterReadingsProvider.notifier).addReading(reading);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading recorded locally. Automatically queuing for synchronization.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Water Telemetry'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Manual Telemetry Input',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Ward',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedWard,
                      items: AppConstants.wards.map((ward) {
                        return DropdownMenuItem(
                          value: ward,
                          child: Text(ward),
                        );
                      }).toList(),
                      validator: (value) => value == null ? 'Please select a ward' : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedWard = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Valve Operational State',
                        prefixIcon: Icon(Icons.settings_input_component),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedValveState,
                      items: AppConstants.valveStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      validator: (value) => value == null ? 'Please select valve state' : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedValveState = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _deviceIdController,
                      decoration: const InputDecoration(
                        labelText: 'Device Node Identifier',
                        prefixIcon: Icon(Icons.developer_board),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a unique device ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      title: const Text('Simulate Missing / Nil Reading'),
                      subtitle: const Text('Marks water flow (Litres) value as NULL in storage.'),
                      value: _isMissingFlow,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          _isMissingFlow = val ?? false;
                          if (_isMissingFlow) {
                            _flowController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    if (!_isMissingFlow)
                      TextFormField(
                        controller: _flowController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Water Flow rate (Litres)',
                          prefixIcon: Icon(Icons.water),
                          suffixText: 'L',
                          border: OutlineInputBorder(),
                          helperText: 'Accepts numeric decimals. Extremely high is > 5000L.',
                        ),
                        validator: (value) {
                          if (_isMissingFlow) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter water flow amount in litres';
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null) {
                            return 'Enter a valid decimal number';
                          }
                          if (parsed < 0) {
                            return 'Flow rate cannot be negative';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),

                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Observation Date & Time'),
                      subtitle: Text(_selectedDateTime.toLocal().toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: _pickDateTime,
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Save Local Telemetry Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
