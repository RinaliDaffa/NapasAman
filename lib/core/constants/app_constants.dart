class AppConstants {
  // AQI level thresholds (US EPA standard)
  static const int aqiGood = 50;
  static const int aqiModerate = 100;
  static const int aqiUnhealthySensitive = 150;
  static const int aqiUnhealthy = 200;
  static const int aqiVeryUnhealthy = 300;
  static const int defaultAqiThreshold = 100;

  // Indonesian city coordinates for quick access
  static const Map<String, Map<String, double>> popularCities = {
    'Jakarta': {'latitude': -6.2088, 'longitude': 106.8456},
    'Surabaya': {'latitude': -7.2575, 'longitude': 112.7521},
    'Bandung': {'latitude': -6.9175, 'longitude': 107.6191},
    'Yogyakarta': {'latitude': -7.7956, 'longitude': 110.3695},
    'Semarang': {'latitude': -6.9666, 'longitude': 110.4196},
    'Makassar': {'latitude': -5.1477, 'longitude': 119.4327},
    'Medan': {'latitude': 3.5952, 'longitude': 98.6722},
    'Denpasar': {'latitude': -8.6705, 'longitude': 115.2126},
    'Palembang': {'latitude': -2.9761, 'longitude': 104.7754},
    'Malang': {'latitude': -7.9666, 'longitude': 112.6326},
  };

  // Firestore collection names
  static const String alertThresholdsCollection = 'alert_thresholds';
  static const String alertHistoryCollection = 'alert_history';
  static const String savedLocationsCollection = 'saved_locations';
}