# Contoh Implementasi Alerts Feature

Dokumentasi ini menunjukkan cara menggunakan alerts feature di bagian lain aplikasi.

## 1. Menggunakan AlertProvider di Widget

```dart
Consumer<AlertProvider>(
  builder: (context, alertProvider, _) {
    return ListView.builder(
      itemCount: alertProvider.thresholds.length,
      itemBuilder: (context, index) {
        final threshold = alertProvider.thresholds[index];
        return ListTile(
          title: Text(threshold.city),
          subtitle: Text('AQI Threshold: ${threshold.aqi}'),
        );
      },
    );
  },
)
```

## 2. Create Threshold Dari Location Module

```dart
final alertProvider = context.read<AlertProvider>();
final authProvider = context.read<AuthProvider>();

await alertProvider.createThreshold(
  authProvider.user!.uid,
  'Surabaya',
  100,
  label: 'Kampus',
);
```

## 3. Check AQI Saat App Dibuka

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAqiForAllThresholds();
  });
}

Future<void> _checkAqiForAllThresholds() async {
  final alertProvider = context.read<AlertProvider>();
  final authProvider = context.read<AuthProvider>();

  if (authProvider.user == null) return;

  final monitoringService = AqiMonitoringService();
  await monitoringService.checkAllThresholds(
    authProvider.user!.uid,
    alertProvider.thresholds,
  );

  // Reload alert history
  await alertProvider.loadAlertHistory(authProvider.user!.uid);
}
```

## 4. Display Alert Status di Home Screen

```dart
Consumer<AlertProvider>(
  builder: (context, alertProvider, _) {
    if (alertProvider.alertHistory.isEmpty) {
      return const Text('Tidak ada alert');
    }

    final latestAlert = alertProvider.alertHistory.first;
    return Container(
      color: Colors.red[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Alert: ${latestAlert.city}'),
          Text('AQI: ${latestAlert.currentAqi}'),
          Text(latestAlert.message),
        ],
      ),
    );
  },
)
```

## 5. Error Handling

```dart
Consumer<AlertProvider>(
  builder: (context, alertProvider, _) {
    if (alertProvider.isLoading) {
      return const CircularProgressIndicator();
    }

    if (alertProvider.error != null) {
      return Column(
        children: [
          Text('Error: ${alertProvider.error}'),
          ElevatedButton(
            onPressed: () {
              alertProvider.clearError();
              // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return // Your content
  },
)
```

## Integration Points

### Dengan Locations Module
1. Setelah user menambah lokasi pantauan
2. Sugesti user untuk membuat threshold untuk lokasi tersebut
3. User diarahkan ke alerts tab dengan kota pre-filled

### Dengan Home Module
1. Tampilkan status alert terbaru
2. Quick action untuk set threshold
3. Notification badge menunjukkan jumlah alert aktif

### Dengan Profile Module
1. Tampilkan total thresholds yang dibuat
2. Statistik alert yang pernah terpicu
3. Pengaturan notifikasi
