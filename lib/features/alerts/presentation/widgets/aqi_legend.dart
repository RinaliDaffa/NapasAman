import 'package:flutter/material.dart';

class AqiLegend extends StatelessWidget {
  const AqiLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori AQI',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.green, '0-50', 'Baik'),
            _buildLegendItem(Colors.yellow, '51-100', 'Sedang'),
            _buildLegendItem(
              Colors.orange,
              '101-150',
              'Tidak Sehat Bagi Kelompok Sensitif',
            ),
            _buildLegendItem(Colors.red, '151-200', 'Tidak Sehat'),
            _buildLegendItem(Colors.purple, '201-300', 'Sangat Tidak Sehat'),
            _buildLegendItem(Colors.brown, '>300', 'Berbahaya'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String range, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$range - $label', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
