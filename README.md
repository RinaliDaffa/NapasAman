# NapasAman

Aplikasi pemantau kualitas udara (AQI) real-time untuk kota-kota di Indonesia. Mendukung login dengan Firebase, penyimpanan lokasi pantauan, dan notifikasi otomatis jika AQI melampaui threshold.

## Tech Stack

- Flutter
- Firebase (Auth, Firestore, Cloud Messaging)
- Air Quality API
- Provider

## SDG Alignment

SDG 3 - Good Health and Well-being

## Team

- **Daffa Rinali (5025231209)** - Modul Lokasi (CRUD)
- **Royyan (5025231223)** - Modul Alerts & Notifikasi (CRUD + Push Notification)

## Setup

```bash
flutter pub get
flutter run
```

## Firebase Setup

1. Buat project di [Firebase Console](https://console.firebase.google.com).
2. Tambahkan Android app dengan package name `com.example.napasaman`.
3. Download `google-services.json`, lalu simpan ke `android/app/`.
4. Enable Authentication dengan provider Email/Password.
5. Enable Firestore Database.
6. Publish `firestore.rules` dan `firestore.indexes.json` jika ingin memakai aturan dan index dari repo.

Jangan commit `android/app/google-services.json` jika konfigurasi Firebase tim dibuat privat.
