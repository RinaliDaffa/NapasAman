import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../locations/presentation/providers/location_provider.dart';
import '../../../locations/data/models/saved_location.dart';

/// Dialog for adding/editing alert thresholds — picks from saved locations
class AddEditThresholdDialog extends StatefulWidget {
  final String? city; // If editing, city is locked
  final int? initialAqi;
  final String? initialLabel;
  final Function(String city, int aqi, String? label) onSubmit;

  const AddEditThresholdDialog({
    super.key,
    this.city,
    this.initialAqi,
    this.initialLabel,
    required this.onSubmit,
  });

  @override
  State<AddEditThresholdDialog> createState() => _AddEditThresholdDialogState();
}

class _AddEditThresholdDialogState extends State<AddEditThresholdDialog> {
  late TextEditingController _aqiController;
  late TextEditingController _labelController;
  SavedLocation? _selectedLocation;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.city != null;
    _aqiController =
        TextEditingController(text: widget.initialAqi?.toString() ?? '');
    _labelController = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _aqiController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _submit() {
    final cityName =
        _isEditing ? widget.city! : _selectedLocation?.cityName;

    if (cityName == null || cityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih lokasi terlebih dahulu')),
      );
      return;
    }

    if (_aqiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi batas AQI')),
      );
      return;
    }

    final aqi = int.tryParse(_aqiController.text);
    if (aqi == null || aqi < 0 || aqi > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AQI harus antara 0-500')),
      );
      return;
    }

    setState(() => _isLoading = true);

    widget.onSubmit(
      cityName,
      aqi,
      _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Threshold' : 'Tambah Threshold'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location picker (only when adding new)
            if (!_isEditing) ...[
              _buildLocationPicker(),
              const SizedBox(height: 12),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.city!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            // AQI threshold
            TextField(
              controller: _aqiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Batas AQI *',
                hintText: '0-500',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Label
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Label (Opsional)',
                hintText: 'contoh: Batas bahaya, Batas aman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // AQI guide
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panduan AQI:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  SizedBox(height: 4),
                  Text('0-50: Baik   •   51-100: Sedang',
                      style: TextStyle(fontSize: 11, color: Colors.blue)),
                  Text('101-150: Tidak sehat (sensitif)',
                      style: TextStyle(fontSize: 11, color: Colors.blue)),
                  Text('151-200: Tidak sehat   •   201+: Berbahaya',
                      style: TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final locations = locationProvider.locations;

        if (locations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada lokasi tersimpan. Tambahkan lokasi di tab Lokasi terlebih dahulu.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<SavedLocation>(
          initialValue: _selectedLocation,
          decoration: InputDecoration(
            labelText: 'Pilih Lokasi *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          hint: const Text('Pilih dari lokasi tersimpan'),
          isExpanded: true,
          items: locations.map((location) {
            final aqi = locationProvider.getAqiForLocation(location.id);
            return DropdownMenuItem<SavedLocation>(
              value: location,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      location.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (aqi != null)
                    Text(
                      'AQI: ${aqi.aqi}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (location) {
            setState(() {
              _selectedLocation = location;
            });
          },
        );
      },
    );
  }
}
