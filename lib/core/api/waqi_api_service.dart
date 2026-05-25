import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/aqi_model.dart';

class WaqiApiService {
  static const String _baseUrl = 'https://api.waqi.info';

  Future<AqiReading?> getAqiByCity(String cityToken) async {
    try {
      final url = Uri.parse('$_baseUrl/feed/$cityToken/?token=demo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'ok') {
          return AqiReading.fromWAQI(json);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<AqiReading?> getAqiByCoords(double lat, double lon) async {
    try {
      final url = Uri.parse('$_baseUrl/feed/geo:$lat;$lon/?token=demo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'ok') {
          return AqiReading.fromWAQI(json);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> searchCity(String query) async {
    try {
      final url = Uri.parse('$_baseUrl/search/?token=demo&keyword=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'ok') {
          final data = json['data'] as List;
          return data
              .map((item) => item['station']?['name'] ?? item['uid']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}