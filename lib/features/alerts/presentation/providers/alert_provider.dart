import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/alert_threshold.dart';
import '../../data/models/alert_history.dart';
import '../../data/services/firestore_alert_service.dart';
import '../../data/services/notification_service.dart';
import '../../../../core/api/air_quality_api_service.dart';

class AlertProvider extends ChangeNotifier {
  static const Duration _alertCooldown = Duration(hours: 1);

  final FirestoreAlertService _firestoreService = FirestoreAlertService();
  final NotificationService _notificationService = NotificationService();
  final AirQualityApiService _apiService = AirQualityApiService();

  List<AlertThreshold> _thresholds = [];
  List<AlertHistory> _alertHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  Timer? _monitoringTimer;

  AlertProvider() {
    initialize();
  }

  // Getters
  List<AlertThreshold> get thresholds => _thresholds;
  List<AlertHistory> get alertHistory => _alertHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize provider
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      debugPrint(_error);
    }
  }

  /// Load thresholds untuk user tertentu
  Future<void> loadThresholds(String userId) async {
    _isLoading = true;
    _error = null;
    _userId = userId;
    notifyListeners();

    try {
      _thresholds = await _firestoreService.getThresholds(userId);
      _isLoading = false;
      notifyListeners();

      // Auto-check AQI against thresholds after loading
      await checkAllThresholds();

      // Start periodic monitoring (every 15 minutes)
      _startMonitoring();
    } catch (e) {
      _error = 'Failed to load thresholds: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Load alert history
  Future<void> loadAlertHistory(String userId) async {
    _userId = userId;
    try {
      _alertHistory = await _firestoreService.getAlertHistory(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load alert history: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Start periodic AQI monitoring
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => checkAllThresholds(),
    );
  }

  /// Check AQI for ALL thresholds and trigger alerts if exceeded
  Future<void> checkAllThresholds() async {
    if (_thresholds.isEmpty || _userId == null) return;

    debugPrint('Checking ${_thresholds.length} thresholds...');

    for (final threshold in _thresholds) {
      try {
        final reading = await _apiService.getAqiByCityName(threshold.city);
        if (reading == null) {
          debugPrint('Could not get AQI for ${threshold.city}');
          continue;
        }

        debugPrint(
          '${threshold.city}: AQI=${reading.aqi}, Threshold=${threshold.aqi}',
        );

        // Check if AQI exceeds threshold
        if (reading.aqi >= threshold.aqi) {
          await _triggerAlert(
            userId: _userId!,
            threshold: threshold,
            currentAqi: reading.aqi,
          );
        }
      } catch (e) {
        debugPrint('Error checking ${threshold.city}: $e');
      }
    }
  }

  /// Trigger an alert — save to history + send notification
  Future<void> _triggerAlert({
    required String userId,
    required AlertThreshold threshold,
    required int currentAqi,
  }) async {
    try {
      if (_isWithinCooldown(threshold.id)) {
        debugPrint(
          'Alert for ${threshold.city} skipped because it is still in cooldown',
        );
        return;
      }

      // Create alert history record
      final alertHistory = AlertHistory.fromThreshold(
        thresholdId: threshold.id,
        userId: userId,
        city: threshold.city,
        currentAqi: currentAqi,
        threshold: threshold.aqi,
      );

      final saved = await _firestoreService.createAlertHistory(alertHistory);

      // Send local notification
      await _notificationService.sendAlertNotification(
        city: threshold.city,
        currentAqi: currentAqi,
        threshold: threshold.aqi,
        message: saved.message,
        thresholdId: threshold.id,
      );

      // Add to local list
      _alertHistory.insert(0, saved);
      notifyListeners();

      debugPrint(
        'Alert triggered for ${threshold.city}: AQI $currentAqi >= ${threshold.aqi}',
      );
    } catch (e) {
      debugPrint('Error triggering alert: $e');
    }
  }

  bool _isWithinCooldown(String thresholdId) {
    final now = DateTime.now();
    return _alertHistory.any((history) {
      final isSameThreshold = history.thresholdId == thresholdId;
      final elapsed = now.difference(history.triggeredAt);
      return isSameThreshold && elapsed < _alertCooldown;
    });
  }

  /// Create threshold baru
  Future<bool> createThreshold(
    String userId,
    String city,
    int aqi, {
    String? label,
  }) async {
    _isLoading = true;
    _error = null;
    _userId = userId;
    notifyListeners();

    try {
      final threshold = await _firestoreService.createThreshold(
        userId,
        city,
        aqi,
        label: label,
      );

      // Subscribe to notification topic
      await _notificationService.subscribeToThresholdTopic(threshold);

      _thresholds.add(threshold);
      _isLoading = false;
      notifyListeners();

      // Immediately check this new threshold
      final reading = await _apiService.getAqiByCityName(city);
      if (reading != null && reading.aqi >= aqi) {
        await _triggerAlert(
          userId: userId,
          threshold: threshold,
          currentAqi: reading.aqi,
        );
      }

      return true;
    } catch (e) {
      _error = 'Failed to create threshold: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Update threshold
  Future<bool> updateThreshold(
    String thresholdId,
    int newAqi, {
    String? newLabel,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateThreshold(
        thresholdId,
        newAqi,
        newLabel: newLabel,
      );

      // Update local list
      final index = _thresholds.indexWhere((t) => t.id == thresholdId);
      if (index != -1) {
        _thresholds[index] = _thresholds[index].copyWith(
          aqi: newAqi,
          label: newLabel ?? _thresholds[index].label,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update threshold: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete threshold
  Future<bool> deleteThreshold(String thresholdId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Unsubscribe from notification topic
      await _notificationService.unsubscribeFromThresholdTopic(thresholdId);

      await _firestoreService.deleteThreshold(thresholdId);

      _thresholds.removeWhere((t) => t.id == thresholdId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete threshold: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Manually trigger a check (e.g. from a "Check Now" button)
  Future<void> manualCheck() async {
    if (_userId == null) return;
    await checkAllThresholds();
  }

  /// Delete alert history
  Future<bool> deleteAlertHistory(String historyId) async {
    try {
      await _firestoreService.deleteAlertHistory(historyId);
      _alertHistory.removeWhere((h) => h.id == historyId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete alert: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Clear all alert history
  Future<bool> clearAlertHistory(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.clearAlertHistory(userId);
      _alertHistory.clear();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to clear alert history: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Get threshold by city
  Future<AlertThreshold?> getThresholdByCity(String userId, String city) async {
    try {
      return await _firestoreService.getThresholdByCity(userId, city);
    } catch (e) {
      debugPrint('Error getting threshold by city: $e');
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}
