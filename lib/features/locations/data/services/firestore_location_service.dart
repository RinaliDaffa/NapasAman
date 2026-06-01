import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/saved_location.dart';

/// Firestore service for saved locations CRUD operations
class FirestoreLocationService {
  static final FirestoreLocationService _instance =
      FirestoreLocationService._internal();

  factory FirestoreLocationService() => _instance;

  FirestoreLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'saved_locations';

  // ============ CREATE ============

  /// Save a new location for the user
  Future<SavedLocation> saveLocation({
    required String userId,
    required String cityName,
    required String country,
    required double latitude,
    required double longitude,
    String? label,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final location = SavedLocation(
        id: '',
        userId: userId,
        cityName: cityName,
        country: country,
        label: label,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection(_collection).add(
            location.toFirestore(),
          );

      return location.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error saving location: $e');
      rethrow;
    }
  }

  // ============ READ ============

  /// Get all saved locations for a user
  Future<List<SavedLocation>> getSavedLocations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SavedLocation.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting saved locations: $e');
      rethrow;
    }
  }

  /// Get a single location by ID
  Future<SavedLocation?> getLocationById(String locationId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(locationId).get();
      if (!doc.exists || doc.data() == null) return null;
      return SavedLocation.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('Error getting location: $e');
      rethrow;
    }
  }

  /// Check if a location already exists for this user
  Future<bool> locationExists(String userId, String cityName) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('cityName', isEqualTo: cityName)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking location existence: $e');
      return false;
    }
  }

  // ============ UPDATE ============

  /// Update a location's label and notes
  Future<void> updateLocation(
    String locationId, {
    String? label,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (label != null) updates['label'] = label;
      if (notes != null) updates['notes'] = notes;

      await _firestore.collection(_collection).doc(locationId).update(updates);
    } catch (e) {
      debugPrint('Error updating location: $e');
      rethrow;
    }
  }

  // ============ DELETE ============

  /// Delete a saved location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore.collection(_collection).doc(locationId).delete();
    } catch (e) {
      debugPrint('Error deleting location: $e');
      rethrow;
    }
  }

  // ============ STREAMS ============

  /// Watch saved locations in real-time
  Stream<List<SavedLocation>> watchLocations(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedLocation.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
