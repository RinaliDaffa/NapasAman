import 'package:flutter/material.dart';
import 'package:napas_aman/core/api/air_quality_api_service.dart';
import '../models/alert_threshold.dart';
import '../models/alert_history.dart';
import 'firestore_alert_service.dart';
import 'notification_service.dart';

class AqiMonitoringService {
  static final AqiMonitoringService _instance = AqiMonitoringService._internal();

  factory AqiMonitoringService() {
    return _instance;
  }

  AqiMonitoringService._internal();

  final AirQualityApiService _apiService = AirQualityApiService();
  final FirestoreAlertService _firestoreService = FirestoreAlertService();
  final NotificationService _notificationService = NotificationService();

  /// Check AQI for all thresholds dan trigger alerts jika needed
  Future<void> checkAllThresholds(String userId, List<AlertThreshold> thresholds) async {
    try {
      for (var threshold in thresholds) {
        await _checkThreshold(userId, threshold);
      }
    } catch (e) {
      debugPrint('Error checking thresholds: $e');
    }
  }

  /// Check single threshold
  Future<void> _checkThreshold(String userId, AlertThreshold threshold) async {
    try {
      // Get current AQI from Open-Meteo
      final aqi = await _apiService.getAqiByCityName(threshold.city);

      if (aqi == null) {
        debugPrint('Failed to get AQI for ${threshold.city}');
        return;
      }

      debugPrint(
        'Checking threshold for ${threshold.city}: Current AQI=${aqi.aqi}, Threshold=${threshold.aqi}',
      );

      // Check if AQI exceeds threshold
      if (aqi.aqi >= threshold.aqi) {
        // Create alert history
        final alertHistory = AlertHistory.fromThreshold(
          thresholdId: threshold.id,
          userId: userId,
          city: threshold.city,
          currentAqi: aqi.aqi,
          threshold: threshold.aqi,
        );

        final saved = await _firestoreService.createAlertHistory(alertHistory);

        // Send notification
        await _notificationService.sendAlertNotification(
          city: threshold.city,
          currentAqi: aqi.aqi,
          threshold: threshold.aqi,
          message: saved.message,
          thresholdId: threshold.id,
        );

        debugPrint('Alert triggered for ${threshold.city}');
      }
    } catch (e) {
      debugPrint('Error checking threshold for ${threshold.city}: $e');
    }
  }

  /// Check specific city AQI
  Future<int?> checkCityAqi(String city) async {
    try {
      final aqi = await _apiService.getAqiByCityName(city);
      return aqi?.aqi;
    } catch (e) {
      debugPrint('Error checking city AQI: $e');
      return null;
    }
  }
}
