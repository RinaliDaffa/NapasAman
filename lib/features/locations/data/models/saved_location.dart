import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a saved monitoring location
class SavedLocation {
  final String id;
  final String userId;
  final String cityName;
  final String country;
  final String? label; // Custom label: "Kampus", "Kos", "Rumah"
  final String? notes;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedLocation({
    required this.id,
    required this.userId,
    required this.cityName,
    this.country = '',
    this.label,
    this.notes,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cityName': cityName,
      'country': country,
      'label': label,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory SavedLocation.fromFirestore(String docId, Map<String, dynamic> data) {
    return SavedLocation(
      id: docId,
      userId: data['userId'] as String? ?? '',
      cityName: data['cityName'] as String? ?? '',
      country: data['country'] as String? ?? '',
      label: data['label'] as String?,
      notes: data['notes'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Copy with method for updates
  SavedLocation copyWith({
    String? id,
    String? userId,
    String? cityName,
    String? country,
    String? label,
    String? notes,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      label: label ?? this.label,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Display name: label or city name
  String get displayName => label ?? cityName;
}
