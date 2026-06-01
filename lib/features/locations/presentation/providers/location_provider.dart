import 'package:flutter/material.dart';
import '../../data/models/saved_location.dart';
import '../../data/services/firestore_location_service.dart';
import '../../../../core/api/air_quality_api_service.dart';
import '../../../../models/aqi_model.dart';

/// Provider for managing saved locations and their live AQI data
class LocationProvider extends ChangeNotifier {
  final FirestoreLocationService _firestoreService =
      FirestoreLocationService();
  final AirQualityApiService _apiService = AirQualityApiService();

  List<SavedLocation> _locations = [];
  final Map<String, AqiReading?> _locationAqi = {}; // locationId → AQI data
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SavedLocation> get locations => _locations;
  Map<String, AqiReading?> get locationAqi => _locationAqi;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all saved locations for user
  Future<void> loadLocations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _locations = await _firestoreService.getSavedLocations(userId);
      _isLoading = false;
      notifyListeners();

      // Fetch AQI for all locations in background
      await refreshAllAqi();
    } catch (e) {
      _error = 'Gagal memuat lokasi: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Save a new location
  Future<bool> saveLocation({
    required String userId,
    required String cityName,
    required String country,
    required double latitude,
    required double longitude,
    String? label,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check duplicate
      final exists = await _firestoreService.locationExists(userId, cityName);
      if (exists) {
        _error = 'Lokasi "$cityName" sudah tersimpan';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final location = await _firestoreService.saveLocation(
        userId: userId,
        cityName: cityName,
        country: country,
        latitude: latitude,
        longitude: longitude,
        label: label,
        notes: notes,
      );

      _locations.insert(0, location);
      _isLoading = false;
      notifyListeners();

      // Fetch AQI for new location
      _fetchAqiForLocation(location);

      return true;
    } catch (e) {
      _error = 'Gagal menyimpan lokasi: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Update location label and notes
  Future<bool> updateLocation(
    String locationId, {
    String? label,
    String? notes,
  }) async {
    _error = null;

    try {
      await _firestoreService.updateLocation(
        locationId,
        label: label,
        notes: notes,
      );

      // Update local list
      final index = _locations.indexWhere((l) => l.id == locationId);
      if (index != -1) {
        _locations[index] = _locations[index].copyWith(
          label: label ?? _locations[index].label,
          notes: notes ?? _locations[index].notes,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Gagal memperbarui lokasi: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Delete a saved location
  Future<bool> deleteLocation(String locationId) async {
    _error = null;

    try {
      await _firestoreService.deleteLocation(locationId);
      _locations.removeWhere((l) => l.id == locationId);
      _locationAqi.remove(locationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus lokasi: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Refresh AQI for all saved locations
  Future<void> refreshAllAqi() async {
    for (final location in _locations) {
      await _fetchAqiForLocation(location);
    }
  }

  /// Fetch AQI for a single location
  Future<void> _fetchAqiForLocation(SavedLocation location) async {
    try {
      final reading = await _apiService.getAqiByCoords(
        location.latitude,
        location.longitude,
      );

      if (reading != null) {
        _locationAqi[location.id] = reading.copyWith(
          city: location.cityName,
          country: location.country,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching AQI for ${location.cityName}: $e');
    }
  }

  /// Get AQI reading for a specific location
  AqiReading? getAqiForLocation(String locationId) {
    return _locationAqi[locationId];
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
