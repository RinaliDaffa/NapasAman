import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator_android/geolocator_android.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../locations/presentation/providers/location_provider.dart';
import '../../../alerts/presentation/providers/alert_provider.dart';
import '../../../../core/api/air_quality_api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/aqi_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Home screen — dashboard showing current location AQI, saved locations, and recent alerts
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AirQualityApiService _apiService = AirQualityApiService();
  AqiReading? _currentLocationAqi;
  bool _isLoadingCurrentAqi = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.user != null) {
      final uid = auth.user!.uid;
      context.read<LocationProvider>().loadLocations(uid);
      context.read<AlertProvider>().loadAlertHistory(uid);
    }
    await _getCurrentLocationAqi();
  }

  Future<void> _getCurrentLocationAqi() async {
    setState(() {
      _isLoadingCurrentAqi = true;
      _locationError = null;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Fallback to Jakarta
        final reading = await _apiService.getAqiByCoords(-6.2088, 106.8456);
        setState(() {
          _currentLocationAqi = reading?.copyWith(city: 'Jakarta (Default)');
          _isLoadingCurrentAqi = false;
          _locationError = 'Izin lokasi ditolak. Menampilkan Jakarta.';
        });
        return;
      }

      late LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
          forceLocationManager: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        );
      }

      // Coba ambil lokasi terakhir yang diketahui terlebih dahulu (sangat berguna untuk emulator)
      Position? position = await Geolocator.getLastKnownPosition();
      
      // Jika belum ada riwayat lokasi sama sekali, baru paksa ambil yang baru
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      final reading = await _apiService.getAqiByCoords(
        position.latitude,
        position.longitude,
      );

      String cityName = 'Lokasi Saat Ini';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.locality ?? p.subAdministrativeArea ?? 'Lokasi Saat Ini';
          if (cityName.isEmpty) cityName = 'Lokasi Saat Ini';
        }
      } catch (_) {}

      setState(() {
        _currentLocationAqi = reading?.copyWith(city: cityName);
        _isLoadingCurrentAqi = false;
      });
    } catch (e) {
      print("Location Error: $e");
      // Fallback to Jakarta on any error
      final reading = await _apiService.getAqiByCoords(-6.2088, 106.8456);
      setState(() {
        _currentLocationAqi = reading?.copyWith(city: 'Jakarta (Default)');
        _isLoadingCurrentAqi = false;
        _locationError = 'Gagal mendapatkan lokasi. Menampilkan Jakarta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NapasAman'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Location AQI Hero
              _buildCurrentAqiCard(),

              // Saved Locations Summary
              _buildSavedLocationsSummary(),

              // Recent Alerts
              _buildRecentAlerts(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentAqiCard() {
    if (_isLoadingCurrentAqi) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentLocationAqi == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Gagal memuat data AQI'),
        ),
      );
    }

    final aqi = _currentLocationAqi!.aqi;
    final color = AppTheme.getAqiColor(aqi);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentLocationAqi!.city,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    aqi.toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLocationAqi!.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentLocationAqi!.healthRecommendation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentLocationAqi!.pm25 != null ||
              _currentLocationAqi!.pm10 != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_currentLocationAqi!.pm25 != null)
                    _buildPollutantChip(
                        'PM2.5', _currentLocationAqi!.pm25!),
                  if (_currentLocationAqi!.pm10 != null)
                    _buildPollutantChip(
                        'PM10', _currentLocationAqi!.pm10!),
                  if (_currentLocationAqi!.o3 != null)
                    _buildPollutantChip('O₃', _currentLocationAqi!.o3!),
                ],
              ),
            ),
          if (_locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _locationError!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPollutantChip(String name, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$name: ${value.toStringAsFixed(1)}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSavedLocationsSummary() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        if (locationProvider.locations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Lokasi Tersimpan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: locationProvider.locations.length,
                itemBuilder: (context, index) {
                  final location = locationProvider.locations[index];
                  final aqi = locationProvider.getAqiForLocation(location.id);
                  final aqiValue = aqi?.aqi ?? 0;
                  final color = aqi != null
                      ? AppTheme.getAqiColor(aqiValue)
                      : Colors.grey;

                  return Container(
                    width: 130,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              aqi != null ? aqiValue.toString() : '--',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            if (aqi != null)
                              Text(
                                aqi.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentAlerts() {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, _) {
        final recentAlerts = alertProvider.alertHistory.take(5).toList();

        if (recentAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Alert Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...recentAlerts.map((alert) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Colors.red[50],
                child: ListTile(
                  leading: Icon(Icons.warning, color: Colors.red[700]),
                  title: Text(
                    alert.city,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'AQI ${alert.currentAqi} (Batas: ${alert.threshold})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  dense: true,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}