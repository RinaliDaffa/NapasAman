# Modul Sistem Peringatan Kesehatan & Notifikasi (Alerts Feature)

## Gambaran Umum
Modul ini menangani seluruh logika untuk membuat, mengelola, dan memicu alert/peringatan berdasarkan threshold AQI yang ditentukan pengguna.

## Struktur File

```
lib/features/alerts/
├── data/
│   ├── models/
│   │   ├── alert_threshold.dart      # Model untuk pengaturan threshold
│   │   └── alert_history.dart        # Model untuk riwayat alert
│   └── services/
│       ├── firestore_alert_service.dart     # CRUD Firestore
│       ├── notification_service.dart        # Notification handling
│       └── aqi_monitoring_service.dart      # AQI checking logic
└── presentation/
    ├── screens/
    │   └── alerts_screen.dart               # Main UI screen
    └── widgets/
        ├── threshold_card.dart              # Display single threshold
        ├── alert_history_card.dart          # Display single alert history
        ├── aqi_legend.dart                  # AQI category legend
        └── add_edit_threshold_dialog.dart   # Dialog untuk add/edit
```

## Models

### AlertThreshold
Menyimpan pengaturan ambang batas AQI untuk satu kota:
```dart
AlertThreshold(
  id: "doc_id",
  userId: "user_uid",
  city: "Surabaya",
  aqi: 100,  // Threshold AQI
  label: "Kampus",  // Optional label
  createdAt: DateTime.now(),
)
```

**Firebase Collection**: `alert_thresholds`

### AlertHistory
Menyimpan riwayat alert yang pernah terpicu:
```dart
AlertHistory(
  id: "doc_id",
  userId: "user_uid",
  thresholdId: "threshold_doc_id",
  city: "Surabaya",
  currentAqi: 150,
  threshold: 100,
  status: "triggered",
  message: "AQI 150 telah melebihi batas aman...",
  triggeredAt: DateTime.now(),
)
```

**Firebase Collection**: `alert_history`

## Services

### 1. FirestoreAlertService
CRUD operations untuk Firestore:

**CREATE**
```dart
final threshold = await firestoreService.createThreshold(
  userId: user.uid,
  city: "Surabaya",
  aqi: 100,
  label: "Kampus",
);
```

**READ**
```dart
// Get all thresholds
final thresholds = await firestoreService.getThresholds(userId);

// Get threshold by city
final threshold = await firestoreService.getThresholdByCity(userId, "Surabaya");

// Get alert history
final history = await firestoreService.getAlertHistory(userId);
```

**UPDATE**
```dart
await firestoreService.updateThreshold(
  thresholdId,
  newAqi: 120,
  newLabel: "Kos",
);
```

**DELETE**
```dart
await firestoreService.deleteThreshold(thresholdId);
await firestoreService.deleteAlertHistory(historyId);
await firestoreService.clearAlertHistory(userId);  // Clear all
```

**Stream (Real-time)**
```dart
// Watch threshold changes in real-time
firestoreService.watchThresholds(userId).listen((thresholds) {
  // Update UI
});

// Watch alert history changes
firestoreService.watchAlertHistory(userId).listen((history) {
  // Update UI
});
```

### 2. NotificationService
Handle push & local notifications:

```dart
// Initialize (dipanggil di main.dart atau app startup)
await notificationService.initialize();

// Send alert notification
await notificationService.sendAlertNotification(
  city: "Surabaya",
  currentAqi: 150,
  threshold: 100,
  message: "Gunakan masker...",
  thresholdId: "threshold_id",
);

// Subscribe/Unsubscribe dari notification topic
await notificationService.subscribeToThresholdTopic(threshold);
await notificationService.unsubscribeFromThresholdTopic(thresholdId);
```

### 3. AqiMonitoringService
Monitoring & checking AQI terhadap threshold:

```dart
// Check all thresholds user
await monitoringService.checkAllThresholds(userId, thresholds);

// Check specific city AQI
final currentAqi = await monitoringService.checkCityAqi("Surabaya");
```

## Provider (State Management)

### AlertProvider
Menggunakan ChangeNotifier untuk state management:

```dart
// Getters
List<AlertThreshold> thresholds
List<AlertHistory> alertHistory
bool isLoading
String? error

// Methods
Future<void> loadThresholds(userId)
Future<void> loadAlertHistory(userId)
Future<bool> createThreshold(userId, city, aqi, label)
Future<bool> updateThreshold(thresholdId, newAqi, newLabel)
Future<bool> deleteThreshold(thresholdId)
Future<bool> deleteAlertHistory(historyId)
Future<bool> clearAlertHistory(userId)
Future<void> checkAndTriggerAlert(userId, thresholdId, city, currentAqi)
```

**Usage dalam Widget:**
```dart
Consumer<AlertProvider>(
  builder: (context, alertProvider, _) {
    return ListView.builder(
      itemCount: alertProvider.thresholds.length,
      itemBuilder: (context, index) {
        // Display threshold
      },
    );
  },
)
```

## UI Screens

### AlertsScreen
Main screen dengan 2 tabs:

1. **Tab 1: Threshold Settings**
   - Daftar semua threshold yang dibuat user
   - Button untuk tambah threshold baru
   - Setiap threshold bisa di-edit atau dihapus
   - Menampilkan AQI legend

2. **Tab 2: Alert History**
   - Riwayat alert yang pernah terpicu
   - Bisa dihapus satu-satu
   - Button "Bersihkan" untuk clear semua history

## Flow & Use Case

### 1. User Membuat Threshold Baru
```
User tap "+" button
↓
AlertDialog muncul (AddEditThresholdDialog)
↓
User input: Kota, AQI threshold, label (optional)
↓
AlertProvider.createThreshold()
↓
FirestoreAlertService.createThreshold()
↓
Simpan ke Firestore `alert_thresholds` collection
↓
NotificationService.subscribeToThresholdTopic() (untuk FCM)
↓
Threshold ditambahkan ke list & UI update
```

### 2. AQI Melebihi Threshold
```
App cek AQI via WAQI API (contoh: saat user buka app)
↓
AqiMonitoringService.checkAllThresholds()
↓
For each threshold: check apakah AQI >= threshold
↓
Jika ya:
  - Create AlertHistory
  - Save to Firestore
  - Send local notification
  - Update UI
```

### 3. User Edit Threshold
```
User tap "Edit" pada threshold card
↓
Dialog muncul dengan data existing
↓
User ubah AQI value atau label
↓
AlertProvider.updateThreshold()
↓
Firestore update
↓
UI refresh
```

### 4. User Delete Threshold
```
User tap "Delete" pada threshold card
↓
Confirm dialog
↓
AlertProvider.deleteThreshold()
↓
FirestoreAlertService.deleteThreshold()
↓
NotificationService.unsubscribeFromThresholdTopic()
↓
Firestore delete
↓
Threshold dihapus dari list & UI update
```

## Integrasi dengan Module Lain

### 1. Integration dengan Locations Module (Daffa)
```dart
// Setelah user tambah lokasi monitoring di Locations module,
// Royyan bisa suggest buat threshold untuk lokasi tersebut

// Flow:
// 1. Locations module: User pilih kota (misal: Surabaya)
// 2. Alerts module: Navigate ke alerts tab & pre-fill city
// 3. User cukup atur threshold AQI
```

### 2. Integration dengan Home Module
```dart
// Di Home screen, bisa tampilkan:
// - Alert notifications dari Alerts module
// - Quick status: "X alerts triggered today"
// - Quick action: "Set threshold now"
```

## Firebase Setup

### Collections Structure:

#### `alert_thresholds`
```json
{
  "userId": "uid",
  "city": "Surabaya",
  "aqi": 100,
  "label": "Kampus",
  "createdAt": "timestamp"
}
```

#### `alert_history`
```json
{
  "userId": "uid",
  "thresholdId": "threshold_doc_id",
  "city": "Surabaya",
  "currentAqi": 150,
  "threshold": 100,
  "status": "triggered",
  "message": "AQI 150 telah melebihi...",
  "triggeredAt": "timestamp"
}
```

## Testing Checklist

- [ ] Buat threshold baru
- [ ] Edit threshold (ubah AQI & label)
- [ ] Delete threshold
- [ ] View alert history
- [ ] Delete alert history
- [ ] Clear all history
- [ ] Notification triggered saat AQI melebihi threshold
- [ ] AQI legend muncul dengan benar
- [ ] Loading state ditampilkan
- [ ] Error handling berfungsi

## Dependencies
- `firebase_core`: Firebase initialization
- `cloud_firestore`: Firestore database
- `firebase_messaging`: FCM push notifications
- `flutter_local_notifications`: Local notifications
- `provider`: State management

## Notes untuk Development

1. **API Key**: WAQI API menggunakan token "demo" (limited). Untuk production, gunakan token API yang valid.

2. **Background AQI Check**: Untuk check AQI secara periodic saat app di background, perlu setup `firebase_messaging` background handler.

3. **Notification Channels** (Android):
   - Channel ID: `air_quality_alert`
   - Importance: HIGH
   - Sound: Enabled

4. **Lokalisasi**: Semua text sudah dalam bahasa Indonesia. Jika perlu multi-bahasa, setup dengan `intl` package.

---

**Dibuat oleh**: Royyan
**Tanggal**: 2026
**Status**: Siap untuk integrasi
