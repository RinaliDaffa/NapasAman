import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/aqi_model.dart';

/// Service for fetching air quality data from Open-Meteo API.
/// Free, no API key required. 10,000 calls/day limit.
class AirQualityApiService {
  static const String _airQualityBase =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _geocodingBase =
      'https://geocoding-api.open-meteo.com/v1/search';

  /// Get current AQI by coordinates
  Future<AqiReading?> getAqiByCoords(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_airQualityBase?latitude=$lat&longitude=$lon'
        '&current=us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,ozone'
        '&hourly=us_aqi,pm2_5,pm10'
        '&forecast_days=1',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['current'] != null) {
          return AqiReading.fromOpenMeteo(json, lat, lon);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current AQI by city name (geocodes first, then fetches AQI)
  Future<AqiReading?> getAqiByCityName(String cityName) async {
    try {
      // Step 1: Geocode the city name
      final geoResult = await searchCity(cityName);
      if (geoResult.isEmpty) return null;

      final city = geoResult.first;
      final lat = city['latitude'] as double;
      final lon = city['longitude'] as double;

      // Step 2: Get AQI for those coordinates
      final reading = await getAqiByCoords(lat, lon);
      if (reading != null) {
        // Override the city name with the searched city
        return reading.copyWith(
          city: city['name'] as String? ?? cityName,
          country: city['country'] as String? ?? '',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search cities using Open-Meteo Geocoding API
  Future<List<Map<String, dynamic>>> searchCity(String query) async {
    if (query.length < 2) return [];

    try {
      final url = Uri.parse(
        '$_geocodingBase?name=$query&count=10&language=en&format=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List<dynamic>?;
        if (results == null) return [];

        return results.map((item) {
          return <String, dynamic>{
            'name': item['name'] ?? '',
            'country': item['country'] ?? '',
            'admin1': item['admin1'] ?? '', // State/Province
            'latitude': (item['latitude'] as num?)?.toDouble() ?? 0.0,
            'longitude': (item['longitude'] as num?)?.toDouble() ?? 0.0,
            'population': item['population'] ?? 0,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get AQI for multiple coordinates at once
  Future<List<AqiReading>> getAqiForMultipleLocations(
    List<Map<String, double>> locations,
  ) async {
    final results = <AqiReading>[];

    for (final loc in locations) {
      final reading = await getAqiByCoords(loc['latitude']!, loc['longitude']!);
      if (reading != null) {
        results.add(reading);
      }
    }

    return results;
  }
}
