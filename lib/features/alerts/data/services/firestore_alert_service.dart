import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/alert_threshold.dart';
import '../models/alert_history.dart';

class FirestoreAlertService {
  static final FirestoreAlertService _instance =
      FirestoreAlertService._internal();

  factory FirestoreAlertService() {
    return _instance;
  }

  FirestoreAlertService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _thresholdsCollection = 'alert_thresholds';
  static const String _historyCollection = 'alert_history';

  /// CREATE - Tambah threshold baru
  Future<AlertThreshold> createThreshold(
    String userId,
    String city,
    int aqi, {
    String? label,
  }) async {
    try {
      final docRef = await _firestore.collection(_thresholdsCollection).add({
        'userId': userId,
        'city': city,
        'aqi': aqi,
        'label': label,
        'createdAt': DateTime.now(),
      });

      return AlertThreshold(
        id: docRef.id,
        userId: userId,
        city: city,
        aqi: aqi,
        label: label,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating threshold: $e');
      rethrow;
    }
  }

  /// READ - Ambil semua threshold user
  Future<List<AlertThreshold>> getThresholds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_thresholdsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AlertThreshold.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting thresholds: $e');
      rethrow;
    }
  }

  /// READ - Get threshold by city
  Future<AlertThreshold?> getThresholdByCity(String userId, String city) async {
    try {
      final snapshot = await _firestore
          .collection(_thresholdsCollection)
          .where('userId', isEqualTo: userId)
          .where('city', isEqualTo: city)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return AlertThreshold.fromFirestore(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      debugPrint('Error getting threshold by city: $e');
      rethrow;
    }
  }

  /// UPDATE - Ubah threshold AQI
  Future<void> updateThreshold(
    String thresholdId,
    int newAqi, {
    String? newLabel,
  }) async {
    try {
      final updates = <String, dynamic>{'aqi': newAqi};

      if (newLabel != null) {
        updates['label'] = newLabel;
      }

      await _firestore
          .collection(_thresholdsCollection)
          .doc(thresholdId)
          .update(updates);
    } catch (e) {
      debugPrint('Error updating threshold: $e');
      rethrow;
    }
  }

  /// DELETE - Hapus threshold
  Future<void> deleteThreshold(String thresholdId) async {
    try {
      await _firestore
          .collection(_thresholdsCollection)
          .doc(thresholdId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting threshold: $e');
      rethrow;
    }
  }

  // ============ ALERT HISTORY ============

  /// CREATE - Tambah alert history
  Future<AlertHistory> createAlertHistory(AlertHistory history) async {
    try {
      final docRef = await _firestore
          .collection(_historyCollection)
          .add(history.toFirestore());

      return history.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating alert history: $e');
      rethrow;
    }
  }

  /// READ - Ambil history alert user
  Future<List<AlertHistory>> getAlertHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_historyCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('triggeredAt', descending: true)
          .limit(50) // Limit 50 history terbaru
          .get();

      return snapshot.docs
          .map((doc) => AlertHistory.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting alert history: $e');
      rethrow;
    }
  }

  /// READ - Get history for specific city
  Future<List<AlertHistory>> getAlertHistoryByCity(
    String userId,
    String city,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_historyCollection)
          .where('userId', isEqualTo: userId)
          .where('city', isEqualTo: city)
          .orderBy('triggeredAt', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => AlertHistory.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting alert history by city: $e');
      rethrow;
    }
  }

  /// DELETE - Hapus alert history
  Future<void> deleteAlertHistory(String historyId) async {
    try {
      await _firestore.collection(_historyCollection).doc(historyId).delete();
    } catch (e) {
      debugPrint('Error deleting alert history: $e');
      rethrow;
    }
  }

  /// DELETE - Clear semua history untuk user
  Future<void> clearAlertHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_historyCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing alert history: $e');
      rethrow;
    }
  }

  /// Stream - Watch threshold changes
  Stream<List<AlertThreshold>> watchThresholds(String userId) {
    return _firestore
        .collection(_thresholdsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AlertThreshold.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Stream - Watch alert history
  Stream<List<AlertHistory>> watchAlertHistory(String userId) {
    return _firestore
        .collection(_historyCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('triggeredAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AlertHistory.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}
