class AppConstants {
  static const int aqiGood = 50;
  static const int aqiModerate = 100;
  static const int aqiUnhealthySensitive = 150;
  static const int aqiUnhealthy = 200;
  static const int aqiVeryUnhealthy = 300;
  static const int defaultAqiThreshold = 100;

  static const Map<String, String> popularCities = {
    'Jakarta': '@Jakarta',
    'Surabaya': '@Surabaya',
    'Bandung': '@Bandung',
    'Yogyakarta': '@Yogyakarta',
    'Semarang': '@Semarang',
    'Makassar': '@Makassar',
    'Medan': '@Medan',
    'Denpasar': '@Denpasar',
  };
}