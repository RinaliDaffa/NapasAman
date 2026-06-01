import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/add_location_dialog.dart';
import '../widgets/edit_location_dialog.dart';
import 'location_detail_screen.dart';

/// Locations screen — full CRUD for saved monitoring locations
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();

    if (auth.isLoggedIn && auth.user != null) {
      locationProvider.loadLocations(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pantau'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = context.read<LocationProvider>();
              provider.refreshAllAqi();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memperbarui data AQI...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh AQI',
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          if (locationProvider.isLoading && locationProvider.locations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (locationProvider.error != null &&
              locationProvider.locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    locationProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (locationProvider.locations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada lokasi tersimpan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan lokasi untuk memantau kualitas udara secara real-time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddLocationDialog(context),
                      icon: const Icon(Icons.add_location),
                      label: const Text('Tambah Lokasi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => locationProvider.refreshAllAqi(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: locationProvider.locations.length,
              itemBuilder: (context, index) {
                final location = locationProvider.locations[index];
                final aqiReading =
                    locationProvider.getAqiForLocation(location.id);

                return LocationCard(
                  location: location,
                  aqiReading: aqiReading,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LocationDetailScreen(
                          location: location,
                          aqiReading: aqiReading,
                        ),
                      ),
                    );
                  },
                  onEdit: () => _showEditDialog(context, location),
                  onDelete: () =>
                      _confirmDelete(context, locationProvider, location),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLocationDialog(context),
        child: const Icon(Icons.add_location),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddLocationDialog(
        onSubmit: (cityName, country, lat, lon, label, notes) {
          final auth = context.read<AuthProvider>();
          final locationProvider = context.read<LocationProvider>();

          if (auth.user != null) {
            locationProvider.saveLocation(
              userId: auth.user!.uid,
              cityName: cityName,
              country: country,
              latitude: lat,
              longitude: lon,
              label: label,
              notes: notes,
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic location) {
    showDialog(
      context: context,
      builder: (_) => EditLocationDialog(
        cityName: location.cityName,
        currentLabel: location.label ?? '',
        currentNotes: location.notes ?? '',
        onSubmit: (label, notes) {
          final locationProvider = context.read<LocationProvider>();
          locationProvider.updateLocation(
            location.id,
            label: label,
            notes: notes,
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    LocationProvider locationProvider,
    dynamic location,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${location.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              locationProvider.deleteLocation(location.id);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Lokasi dihapus')),
              );
            },
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}