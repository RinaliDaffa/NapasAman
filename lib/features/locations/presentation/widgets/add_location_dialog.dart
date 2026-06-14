import 'package:flutter/material.dart';
import '../../../../core/api/air_quality_api_service.dart';
import '../../../../core/constants/app_constants.dart';

/// Dialog for adding a new location — search by city name or pick from popular cities
class AddLocationDialog extends StatefulWidget {
  final Function(
    String cityName,
    String country,
    double latitude,
    double longitude,
    String? label,
    String? notes,
  )
  onSubmit;

  const AddLocationDialog({super.key, required this.onSubmit});

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _searchController = TextEditingController();
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();
  final _apiService = AirQualityApiService();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedCity;
  bool _isSearching = false;
  bool _showPopularCities = true;

  @override
  void dispose() {
    _searchController.dispose();
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _searchCities(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showPopularCities = true;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showPopularCities = false;
    });

    final results = await _apiService.searchCity(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectCity(Map<String, dynamic> city) {
    setState(() {
      _selectedCity = city;
      _searchController.text = city['name'] as String;
      _searchResults = [];
      _showPopularCities = false;
    });
  }

  void _selectPopularCity(String name, Map<String, double> coords) {
    setState(() {
      _selectedCity = {
        'name': name,
        'country': 'Indonesia',
        'latitude': coords['latitude'],
        'longitude': coords['longitude'],
      };
      _searchController.text = name;
      _showPopularCities = false;
    });
  }

  void _submit() {
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kota terlebih dahulu')),
      );
      return;
    }

    widget.onSubmit(
      _selectedCity!['name'] as String,
      _selectedCity!['country'] as String? ?? '',
      (_selectedCity!['latitude'] as num).toDouble(),
      (_selectedCity!['longitude'] as num).toDouble(),
      _labelController.text.trim().isEmpty
          ? null
          : _labelController.text.trim(),
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560, maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Lokasi Pantau',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari Kota',
                  hintText: 'contoh: Surabaya, Jakarta...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _selectedCity != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedCity = null;
                              _searchResults = [];
                              _showPopularCities = true;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _searchCities,
              ),
              const SizedBox(height: 8),

              // Search results or popular cities
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchResults.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final city = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(city['name'] as String),
                        subtitle: Text(
                          '${city['admin1'] ?? ''}, ${city['country'] ?? ''}',
                        ),
                        dense: true,
                        onTap: () => _selectCity(city),
                      );
                    },
                  ),
                )
              else if (_showPopularCities && _selectedCity == null)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kota Populer Indonesia',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.popularCities.entries.map((
                              entry,
                            ) {
                              return ActionChip(
                                avatar: const Icon(
                                  Icons.location_city,
                                  size: 16,
                                ),
                                label: Text(entry.key),
                                onPressed: () =>
                                    _selectPopularCity(entry.key, entry.value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Selected city indicator
              if (_selectedCity != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedCity!['name']}, ${_selectedCity!['country'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Label field
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (Opsional)',
                    hintText: 'contoh: Kampus, Kos, Rumah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Notes field
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    hintText: 'contoh: Dekat jalan raya',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedCity != null ? _submit : null,
                    child: const Text('Simpan'),
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
