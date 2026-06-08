class AqiReading {
  final String city;
  final String country;
  final int aqi;
  final String category;
  final double? pm25;
  final double? pm10;
  final double? co;
  final double? no2;
  final double? o3;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final List<int>? hourlyAqi; // For chart/trend display

  AqiReading({
    required this.city,
    this.country = '',
    required this.aqi,
    required this.category,
    this.pm25,
    this.pm10,
    this.co,
    this.no2,
    this.o3,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.hourlyAqi,
  });

  /// Parse Open-Meteo Air Quality API response
  factory AqiReading.fromOpenMeteo(
    Map<String, dynamic> json,
    double lat,
    double lon,
  ) {
    final current = json['current'] ?? {};
    final hourly = json['hourly'];

    int aqi = _toInt(current['us_aqi']) ?? 0;
    String category = getCategory(aqi);

    // Extract hourly AQI for trend display
    List<int>? hourlyAqiList;
    if (hourly != null && hourly['us_aqi'] != null) {
      final rawList = hourly['us_aqi'] as List<dynamic>;
      hourlyAqiList = rawList
          .where((v) => v != null)
          .map((v) => (v as num).toInt())
          .toList();
    }

    return AqiReading(
      city: 'Current Location',
      country: '',
      aqi: aqi,
      category: category,
      pm25: _toDouble(current['pm2_5']),
      pm10: _toDouble(current['pm10']),
      co: _toDouble(current['carbon_monoxide']),
      no2: _toDouble(current['nitrogen_dioxide']),
      o3: _toDouble(current['ozone']),
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      hourlyAqi: hourlyAqiList,
    );
  }

  /// Create a copy with updated fields
  AqiReading copyWith({
    String? city,
    String? country,
    int? aqi,
    String? category,
    double? pm25,
    double? pm10,
    double? co,
    double? no2,
    double? o3,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    List<int>? hourlyAqi,
  }) {
    return AqiReading(
      city: city ?? this.city,
      country: country ?? this.country,
      aqi: aqi ?? this.aqi,
      category: category ?? this.category,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      co: co ?? this.co,
      no2: no2 ?? this.no2,
      o3: o3 ?? this.o3,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      hourlyAqi: hourlyAqi ?? this.hourlyAqi,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String getCategory(int aqi) {
    if (aqi <= 50) return 'Baik';
    if (aqi <= 100) return 'Sedang';
    if (aqi <= 150) return 'Tidak Sehat (Kelompok Sensitif)';
    if (aqi <= 200) return 'Tidak Sehat';
    if (aqi <= 300) return 'Sangat Tidak Sehat';
    return 'Berbahaya';
  }

  /// Get health recommendation based on AQI
  String get healthRecommendation {
    if (aqi <= 50) return 'Kualitas udara baik. Aman untuk aktivitas luar ruangan.';
    if (aqi <= 100) return 'Kualitas udara cukup. Orang sensitif sebaiknya membatasi aktivitas luar.';
    if (aqi <= 150) return 'Tidak sehat bagi kelompok sensitif. Kurangi aktivitas luar ruangan yang berkepanjangan.';
    if (aqi <= 200) return 'Tidak sehat. Semua orang sebaiknya membatasi aktivitas luar ruangan.';
    if (aqi <= 300) return 'Sangat tidak sehat. Hindari aktivitas luar ruangan. Gunakan masker.';
    return 'Berbahaya! Tetap di dalam ruangan. Gunakan air purifier jika tersedia.';
  }
}