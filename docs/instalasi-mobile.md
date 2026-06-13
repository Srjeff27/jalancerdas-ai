# 📱 Instalasi Mobile App

Panduan menginstal dan menjalankan aplikasi mobile JalanCerdas AI.

---

## 📋 Prerequisites

| Komponen | Versi Minimum | Cek Versi |
|----------|--------------|-----------|
| Flutter SDK | 3.0+ | `flutter --version` |
| Dart SDK | 3.0+ | `dart --version` |
| Android Studio | Latest | — |
| Xcode (macOS) | 14+ | — (untuk iOS) |
| Android SDK | API 21+ | Via Android Studio |

### Setup Flutter

```bash
# Cek Flutter installation
flutter doctor

# Harus menunjukkan ✓ untuk:
# - Flutter
# - Android toolchain
# - Connected device / emulator
```

### Setup Android

1. Install Android Studio
2. Buka SDK Manager → install:
   - Android SDK Platform 33+
   - Android SDK Build-Tools 33+
   - Android Emulator
3. Buat Virtual Device (AVD) dengan API 33+

---

## 🚀 Installation

### 1. Clone Repository

```bash
git clone https://github.com/username/jalancerdas-ai.git
cd jalancerdas-ai/mobile
```

### 2. Install Dependencies

```bash
flutter pub get
```

**Dependencies utama:**

| Package | Versi | Fungsi |
|---------|-------|--------|
| camera | 0.11.0+2 | Live camera preview |
| geolocator | 11.0.0 | GPS location |
| permission_handler | 11.3.0 | Runtime permissions |
| dio | 5.4.3+1 | HTTP client |
| connectivity_plus | 6.0.3 | Network monitoring |
| hive | 2.2.3 | Local database |
| hive_flutter | 1.1.0 | Hive Flutter init |
| tflite_flutter | 0.10.4 | AI model inference |
| provider | 6.1.2 | State management |
| image | 4.2.0 | Image processing |
| google_fonts | 6.2.1 | Custom fonts |
| flutter_speed_dial | 7.0.0 | FAB menu |

### 3. Generate Hive Adapters

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Konfigurasi API URL

Edit file `lib/utils/constants.dart`:

```dart
static const String defaultApiUrl = 'http://10.0.2.2:8000/api/v1';
//                                    ^^^^^^^^^^^^
//                                    Android emulator → localhost
```

**API URL berdasarkan environment:**

| Environment | API URL |
|-------------|---------|
| Android Emulator | `http://10.0.2.2:8000/api/v1` |
| iOS Simulator | `http://localhost:8000/api/v1` |
| Physical Device | `http://<YOUR_IP>:8000/api/v1` |
| Production | `https://api.jalancerdas.com/api/v1` |

Atau ubah via Settings screen di aplikasi.

### 5. Jalankan di Emulator/Device

```bash
# List devices
flutter devices

# Run di emulator/device
flutter run
```

### 6. Install Model TFLite (Opsional)

Model AI untuk deteksi lubang jalan.

```bash
# Download model file
# Letakkan di:
# assets/models/model.tflite

# Update pubspec.yaml assets section jika belum ada:
flutter:
  assets:
    - assets/models/
    - assets/images/
```

Tanpa model, aplikasi akan berjalan dalam **mock mode** (deteksi simulasi).

---

## 🏗️ Build APK

### Debug APK

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APK (per ABI)

```bash
flutter build apk --split-per-abi
```

Output:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Install APK ke Device

```bash
flutter install
# Atau manual
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🍎 Build iOS (macOS only)

```bash
cd ios
pod install
cd ..

flutter build ios --release
```

> ⚠️ iOS build memerlukan Apple Developer Account dan code signing.

---

## 📁 Struktur Aplikasi

```
mobile/
├── lib/
│   ├── main.dart                          # Entry point
│   │   ├── Inisialisasi Hive
│   │   ├── Register adapters
│   │   ├── Open boxes
│   │   ├── Init services
│   │   └── runApp(MultiProvider)
│   ├── app.dart                           # MaterialApp config
│   │
│   ├── models/
│   │   ├── detection_record.dart          # DetectionRecord model
│   │   ├── app_settings.dart              # AppSettings model
│   │   └── adapters.dart                  # Hive type adapters
│   │
│   ├── screens/
│   │   ├── splash_screen.dart             # Splash/loading
│   │   ├── home_screen.dart               # Camera + detection
│   │   ├── history_screen.dart            # Detection history
│   │   ├── detection_detail_screen.dart   # Detail view
│   │   └── settings_screen.dart           # App settings
│   │
│   ├── services/
│   │   ├── api_service.dart               # Dio HTTP client
│   │   ├── camera_service.dart            # Camera init/control
│   │   ├── location_service.dart          # GPS coordinates
│   │   ├── detection_service.dart         # TFLite inference
│   │   ├── upload_service.dart            # Backend upload
│   │   └── offline_queue_service.dart     # Offline upload queue
│   │
│   ├── providers/
│   │   ├── detection_provider.dart        # Detection state
│   │   └── settings_provider.dart         # Settings state
│   │
│   ├── widgets/
│   │   ├── detection_card.dart            # List item card
│   │   ├── detection_overlay.dart         # Bounding box overlay
│   │   └── status_indicator.dart          # GPS/NET indicator
│   │
│   └── utils/
│       ├── constants.dart                 # App constants
│       └── helpers.dart                   # Utility functions
│
├── assets/
│   ├── models/
│   │   └── model.tflite                   # AI model file
│   └── images/
│       └── ...                            # Static images
│
├── android/                               # Android-specific config
├── ios/                                   # iOS-specific config
├── test/
│   └── widget_test.dart                   # Unit tests
├── pubspec.yaml                           # Package config
└── pubspec.lock                           # Locked versions
```

---

## 🔧 Konfigurasi TFLite Model

### Training Model dengan Ultralytics (YOLO)

```python
from ultralytics import YOLO

# Load atau buat model
model = YOLO('yolov8n.pt')

# Train dengan dataset road damage
results = model.train(
    data='road_damage.yaml',
    epochs=100,
    imgsz=640,
    classes=[0, 1, 2, 3, 4],  # pothole, crack, depression, bump, other
)

# Export ke TFLite
model.export(format='tflite')
```

### Konfigurasi Model di App

Di `lib/utils/constants.dart`:

```dart
static const int modelInputSize = 640;
static const int numDetectionClasses = 5;
static const double nmsIouThreshold = 0.45;
```

Di `lib/services/detection_service.dart`:
```dart
static const int inputSize = 640;
static const int numClasses = 5;
static const double confidenceThreshold = 0.5;
static const double nmsIouThreshold = 0.45;
```

---

## ⚙️ Konfigurasi Aplikasi

### Settings yang Tersedia

| Setting | Default | Deskripsi |
|---------|---------|-----------|
| API URL | `http://10.0.2.2:8000/api/v1` | Backend API endpoint |
| Confidence Threshold | 0.65 (65%) | Minimum confidence untuk deteksi |
| Mock Detection Mode | false | Gunakan deteksi simulasi |
| Auto Upload | true | Auto upload ke server |
| Offline Mode | false | Matikan semua network ops |

### Model Detection Classes

| Index | Label | Deskripsi |
|-------|-------|-----------|
| 0 | Pothole | Lubang di jalan |
| 1 | Crack | Retakan jalan |
| 2 | Depression | Penurunan permukaan |
| 3 | Bump | Tonjolan/gundukan |
| 4 | Other | Kerusakan lainnya |

---

## 🔧 Troubleshooting

### Error: `Flutter SDK not found`

```bash
# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor
```

### Error: `Camera permission denied`

Pastikan izin kamera diberikan:
- Android: Settings → Apps → JalanCerdas → Permissions → Camera
- iOS: Settings → Privacy → Camera → JalanCerdas

### Error: `Location permission denied`

```bash
# Pastikan permission handler di-setup
# Cek AndroidManifest.xml untuk location permission
```

### Error: `Unable to load TFLite model`

Aplikasi akan fallback ke mock mode. Untuk model production:
1. Pastikan file `assets/models/model.tflite` ada
2. Jalankan `flutter pub get` ulang
3. Rebuild: `flutter clean && flutter pub get && flutter run`

### Error: `Connection refused` ke API

```bash
# Android emulator harus pakai 10.0.2.2 bukan localhost
# Physical device harus pakai IP address komputer
ip addr show | grep inet
```

### Error: `Hive box already opened`

```bash
# Jalankan clean build
flutter clean
flutter pub get
flutter run
```

### Warning: `Deprecated API usage`

Normal. Flutter framework akan update API di versi mendatang.

---

## ✅ Checklist Instalasi

- [ ] Flutter 3.0+ terinstall
- [ ] `flutter doctor` menunjukkan ✓ untuk semua komponen
- [ ] `flutter pub get` berhasil
- [ ] Hive adapters generated
- [ ] API URL dikonfigurasi
- [ ] Emulator / device tersedia
- [ ] `flutter run` berhasil
- [ ] Kamera preview berjalan
- [ ] GPS indicator menampilkan status
- [ ] Detection overlay berfungsi (mock mode OK)
- [ ] Upload ke backend berhasil
