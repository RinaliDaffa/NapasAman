class AlertHistory {
  final String id;
  final String userId;
  final String thresholdId;
  final String city;
  final int currentAqi;
  final int threshold;
  final String status; // "triggered" atau "resolved"
  final String message;
  final DateTime triggeredAt;

  AlertHistory({
    required this.id,
    required this.userId,
    required this.thresholdId,
    required this.city,
    required this.currentAqi,
    required this.threshold,
    required this.status,
    required this.message,
    required this.triggeredAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'thresholdId': thresholdId,
      'city': city,
      'currentAqi': currentAqi,
      'threshold': threshold,
      'status': status,
      'message': message,
      'triggeredAt': triggeredAt,
    };
  }

  /// Create from Firestore document
  factory AlertHistory.fromFirestore(String docId, Map<String, dynamic> data) {
    return AlertHistory(
      id: docId,
      userId: data['userId'] as String? ?? '',
      thresholdId: data['thresholdId'] as String? ?? '',
      city: data['city'] as String? ?? '',
      currentAqi: (data['currentAqi'] as num?)?.toInt() ?? 0,
      threshold: (data['threshold'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'triggered',
      message: data['message'] as String? ?? '',
      triggeredAt: (data['triggeredAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create alert history from threshold
  factory AlertHistory.fromThreshold({
    required String thresholdId,
    required String userId,
    required String city,
    required int currentAqi,
    required int threshold,
  }) {
    final exceedBy = currentAqi - threshold;
    final advice = _getHealthAdvice(currentAqi);
    final message =
        'AQI $currentAqi telah melebihi batas aman ($threshold) sebesar $exceedBy poin. $advice';

    return AlertHistory(
      id: '',
      userId: userId,
      thresholdId: thresholdId,
      city: city,
      currentAqi: currentAqi,
      threshold: threshold,
      status: 'triggered',
      message: message,
      triggeredAt: DateTime.now(),
    );
  }

  static String _getHealthAdvice(int aqi) {
    if (aqi <= 100) {
      return 'Kualitas udara masih relatif aman, tetap pantau kondisi sekitar.';
    }

    if (aqi <= 150) {
      return 'Kelompok sensitif disarankan mengurangi aktivitas luar ruangan.';
    }

    if (aqi <= 200) {
      return 'Gunakan masker dan kurangi aktivitas luar ruangan.';
    }

    if (aqi <= 300) {
      return 'Hindari aktivitas luar ruangan dan gunakan masker jika harus keluar.';
    }

    return 'Kondisi udara berbahaya. Tetap di dalam ruangan dan gunakan perlindungan ekstra.';
  }

  /// Copy with method
  AlertHistory copyWith({
    String? id,
    String? userId,
    String? thresholdId,
    String? city,
    int? currentAqi,
    int? threshold,
    String? status,
    String? message,
    DateTime? triggeredAt,
  }) {
    return AlertHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      thresholdId: thresholdId ?? this.thresholdId,
      city: city ?? this.city,
      currentAqi: currentAqi ?? this.currentAqi,
      threshold: threshold ?? this.threshold,
      status: status ?? this.status,
      message: message ?? this.message,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }
}
