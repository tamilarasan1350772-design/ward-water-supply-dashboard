import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/water_reading.dart';

void main() {
  test('WaterReading local faultiness detection', () {
    final reading1 = WaterReading(
      readingId: '1',
      ward: 'Ward A',
      flowLitres: 450.5,
      valveState: 'OPEN',
      recordedAt: DateTime.now(),
      deviceId: 'DEV-1',
    );
    expect(reading1.isFaulty, false);

    final reading2 = WaterReading(
      readingId: '2',
      ward: 'Ward A',
      flowLitres: null, // missing value
      valveState: 'OPEN',
      recordedAt: DateTime.now(),
      deviceId: 'DEV-1',
    );
    expect(reading2.isFaulty, true);

    final reading3 = WaterReading(
      readingId: '3',
      ward: 'Ward A',
      flowLitres: 15000.0, // extreme high value
      valveState: 'OPEN',
      recordedAt: DateTime.now(),
      deviceId: 'DEV-1',
    );
    expect(reading3.isFaulty, true);
  });
}
