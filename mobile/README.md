# Mobile App — JalanCerdas AI

Aplikasi Android berbasis Flutter untuk deteksi lubang jalan secara real-time.

## Quick Start

```bash
flutter pub get
flutter run
```

## Arsitektur

```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration
├── models/                # Hive data models
├── services/              # Business logic services
│   ├── camera_service.dart
│   ├── location_service.dart
│   ├── detection_service.dart    # YOLO TFLite + mock mode
│   ├── upload_service.dart
│   ├── offline_queue_service.dart
│   └── api_service.dart
├── providers/             # State management (Provider)
├── screens/               # UI screens
├── widgets/               # Reusable widgets
└── utils/                 # Constants & helpers
```

## Fitur

- Live kamera dengan deteksi YOLO
- GPS otomatis
- Offline queue untuk area tanpa sinyal
- Dark mode untuk penggunaan di kendaraan

## Model

Letakkan file `pothole_yolo.tflite` di `assets/models/`.

Tanpa model, aplikasi berjalan dalam mode mock (deteksi dummy).
