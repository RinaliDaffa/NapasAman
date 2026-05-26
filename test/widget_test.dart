import 'package:flutter_test/flutter_test.dart';
import 'package:napas_aman/features/alerts/data/models/alert_threshold.dart';

void main() {
  test('AlertThreshold stores configured AQI threshold', () {
    final threshold = AlertThreshold(
      id: 'threshold-1',
      userId: 'user-1',
      city: 'Surabaya',
      aqi: 100,
      label: 'Kampus',
      createdAt: DateTime(2026),
    );

    expect(threshold.city, 'Surabaya');
    expect(threshold.aqi, 100);
    expect(threshold.label, 'Kampus');
  });
}
