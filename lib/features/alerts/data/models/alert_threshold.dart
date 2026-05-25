class AlertThreshold {
  final String id;
  final String userId;
  final String city;
  final int aqi;
  final String? label; // Custom label seperti "Kampus", "Kos", dll
  final DateTime createdAt;

  AlertThreshold({
    required this.id,
    required this.userId,
    required this.city,
    required this.aqi,
    this.label,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'city': city,
      'aqi': aqi,
      'label': label,
      'createdAt': createdAt,
    };
  }

  /// Create from Firestore document
  factory AlertThreshold.fromFirestore(String docId, Map<String, dynamic> data) {
    return AlertThreshold(
      id: docId,
      userId: data['userId'] as String? ?? '',
      city: data['city'] as String? ?? '',
      aqi: (data['aqi'] as num?)?.toInt() ?? 0,
      label: data['label'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Copy with method
  AlertThreshold copyWith({
    String? id,
    String? userId,
    String? city,
    int? aqi,
    String? label,
    DateTime? createdAt,
  }) {
    return AlertThreshold(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      city: city ?? this.city,
      aqi: aqi ?? this.aqi,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
