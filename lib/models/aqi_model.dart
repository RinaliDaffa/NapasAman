class AqiReading {
  final String city;
  final String station;
  final int aqi;
  final String category;
  final double? pm25;
  final double? pm10;
  final DateTime timestamp;

  AqiReading({
    required this.city,
    required this.station,
    required this.aqi,
    required this.category,
    this.pm25,
    this.pm10,
    required this.timestamp,
  });

  factory AqiReading.fromWAQI(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final current = data['current'] ?? {};

    int aqi = current['aqi'] ?? 0;
    String category = _getCategory(aqi);

    return AqiReading(
      city: data['city']?['name'] ?? 'Unknown',
      station: data['city']?['location'] ?? 'Unknown',
      aqi: aqi,
      category: category,
      pm25: _toDouble(current['iaqi']?['pm25']?['v']),
      pm10: _toDouble(current['iaqi']?['pm10']?['v']),
      timestamp: DateTime.now(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _getCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}