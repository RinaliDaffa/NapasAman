# NapasAman

Aplikasi pemantau kualitas udara (AQI) real-time untuk kota-kota di Indonesia. Mendukung login dengan Firebase, penyimpanan lokasi pantauan, dan notifikasi otomatis jika AQI melampaui threshold.

## Tech Stack

- Flutter
- Firebase (Auth, Firestore, Cloud Messaging)
- WAQI API
- Provider

## SDG Alignment

SDG 3 — Good Health and Well-being

## Team

- **Daffa Rinali (5025231209)** — Modul Lokasi (CRUD)
- **Royyan (5025231223)** — Modul Alerts & Notifikasi (CRUD + Push Notification)

## Setup

```bash
flutter pub get
flutter run
```

## Firebase Setup

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Tambahkan Android app dengan package name `com.example.napas_aman`
3. Download `google-services.json` → simpan ke `android/app/`
4. Enable Authentication (Email/Password) dan Firestore Database
5. Paste config dari `google-services.json` ke `lib/core/firebase/firebase_service.dart`
