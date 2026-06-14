import 'package:flutter/material.dart';
import '../../data/models/saved_location.dart';
import '../../../../models/aqi_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Detail screen for a single saved location with full AQI breakdown
class LocationDetailScreen extends StatelessWidget {
  final SavedLocation location;
  final AqiReading? aqiReading;

  const LocationDetailScreen({
    super.key,
    required this.location,
    this.aqiReading,
  });

  @override
  Widget build(BuildContext context) {
    final aqi = aqiReading?.aqi ?? 0;
    final color = AppTheme.getAqiColor(aqi);
    final hasData = aqiReading != null;

    return Scaffold(
      appBar: AppBar(title: Text(location.displayName)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero AQI Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasData
                      ? [color.withValues(alpha: 0.8), color]
                      : [Colors.grey[400]!, Colors.grey[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    location.cityName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (location.country.isNotEmpty)
                    Text(
                      location.country,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        hasData ? aqi.toString() : '--',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasData ? aqiReading!.category : 'Memuat...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (hasData) ...[
                    const SizedBox(height: 8),
                    Text(
                      aqiReading!.healthRecommendation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Pollutant Breakdown
            if (hasData) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Detail Polutan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _buildPollutantGrid(aqiReading!),
            ],

            // Location Info
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Info Lokasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.location_on, 'Kota', location.cityName),
                    if (location.label != null)
                      _buildInfoRow(Icons.label, 'Label', location.label!),
                    if (location.notes != null && location.notes!.isNotEmpty)
                      _buildInfoRow(Icons.notes, 'Catatan', location.notes!),
                    _buildInfoRow(
                      Icons.my_location,
                      'Koordinat',
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPollutantGrid(AqiReading reading) {
    final pollutants = <Map<String, dynamic>>[
      if (reading.pm25 != null)
        {
          'name': 'PM2.5',
          'value': reading.pm25!,
          'unit': 'μg/m³',
          'icon': Icons.grain,
        },
      if (reading.pm10 != null)
        {
          'name': 'PM10',
          'value': reading.pm10!,
          'unit': 'μg/m³',
          'icon': Icons.blur_on,
        },
      if (reading.co != null)
        {
          'name': 'CO',
          'value': reading.co!,
          'unit': 'μg/m³',
          'icon': Icons.cloud,
        },
      if (reading.no2 != null)
        {
          'name': 'NO₂',
          'value': reading.no2!,
          'unit': 'μg/m³',
          'icon': Icons.factory,
        },
      if (reading.o3 != null)
        {
          'name': 'O₃',
          'value': reading.o3!,
          'unit': 'μg/m³',
          'icon': Icons.wb_sunny,
        },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemCount: pollutants.length,
        itemBuilder: (context, index) {
          final p = pollutants[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    p['icon'] as IconData,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (p['value'] as double).toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    p['unit'] as String,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
