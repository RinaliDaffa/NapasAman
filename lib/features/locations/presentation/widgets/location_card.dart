import 'package:flutter/material.dart';
import '../../data/models/saved_location.dart';
import '../../../../models/aqi_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Card widget showing a saved location with live AQI data
class LocationCard extends StatelessWidget {
  final SavedLocation location;
  final AqiReading? aqiReading;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LocationCard({
    super.key,
    required this.location,
    this.aqiReading,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final aqi = aqiReading?.aqi ?? 0;
    final color = AppTheme.getAqiColor(aqi);
    final hasData = aqiReading != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // AQI Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: hasData
                      ? color.withValues(alpha: 0.15)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasData ? color : Colors.grey[400]!,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: hasData
                      ? Text(
                          aqi.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        )
                      : const Icon(Icons.hourglass_empty,
                          size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),

              // Location Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (location.label != null)
                      Text(
                        location.cityName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (hasData)
                      Text(
                        aqiReading!.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'Memuat data...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (location.notes != null && location.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          location.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Actions Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
