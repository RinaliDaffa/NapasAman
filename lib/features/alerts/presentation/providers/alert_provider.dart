import 'package:flutter/material.dart';
import '../../data/models/alert_threshold.dart';
import '../../data/models/alert_history.dart';
import '../../data/services/firestore_alert_service.dart';
import '../../data/services/notification_service.dart';

class AlertProvider extends ChangeNotifier {
  final FirestoreAlertService _firestoreService = FirestoreAlertService();
  final NotificationService _notificationService = NotificationService();

  List<AlertThreshold> _thresholds = [];
  List<AlertHistory> _alertHistory = [];
  bool _isLoading = false;
  String? _error;

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
    notifyListeners();

    try {
      _thresholds = await _firestoreService.getThresholds(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load thresholds: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Load alert history
  Future<void> loadAlertHistory(String userId) async {
    try {
      _alertHistory = await _firestoreService.getAlertHistory(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load alert history: $e';
      debugPrint(_error);
      notifyListeners();
    }
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

  /// Check AQI dan trigger alert jika melebihi threshold
  Future<void> checkAndTriggerAlert(
    String userId,
    String thresholdId,
    String city,
    int currentAqi,
  ) async {
    try {
      AlertThreshold? threshold;
      try {
        threshold = _thresholds.firstWhere((t) => t.id == thresholdId);
      } catch (e) {
        threshold = null;
      }

      if (threshold == null) {
        debugPrint('Threshold not found: $thresholdId');
        return;
      }

      // Jika AQI melebihi threshold
      if (currentAqi >= threshold.aqi) {
        // Create alert history
        final alertHistory = AlertHistory.fromThreshold(
          thresholdId: thresholdId,
          userId: userId,
          city: city,
          currentAqi: currentAqi,
          threshold: threshold.aqi,
        );

        await _firestoreService.createAlertHistory(alertHistory);

        // Send notification
        await _notificationService.sendAlertNotification(
          city: city,
          currentAqi: currentAqi,
          threshold: threshold.aqi,
          message: alertHistory.message,
          thresholdId: thresholdId,
        );

        // Reload history
        await loadAlertHistory(userId);
      }
    } catch (e) {
      debugPrint('Error checking and triggering alert: $e');
    }
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
}
