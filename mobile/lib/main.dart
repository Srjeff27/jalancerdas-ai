import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'models/detection_record.dart';
import 'models/app_settings.dart';
import 'models/adapters.dart';
import 'providers/detection_provider.dart';
import 'providers/settings_provider.dart';
import 'services/camera_service.dart';
import 'services/location_service.dart';
import 'services/detection_service.dart';
import 'services/upload_service.dart';
import 'services/offline_queue_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(DamageTypeAdapter());
  Hive.registerAdapter(DetectionStatusAdapter());
  Hive.registerAdapter(DetectionRecordAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  // Open boxes
  await Hive.openBox<DetectionRecord>('detections');
  await Hive.openBox<DetectionRecord>('upload_queue');
  await Hive.openBox<AppSettings>('app_settings');

  // Initialize services
  final apiService = ApiService();
  final cameraService = CameraService();
  final locationService = LocationService();
  final detectionService = DetectionService();
  final uploadService = UploadService(apiService);
  final offlineQueueService = OfflineQueueService();

  // Initialize offline queue monitoring
  await offlineQueueService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DetectionProvider(
            cameraService: cameraService,
            locationService: locationService,
            detectionService: detectionService,
            uploadService: uploadService,
            offlineQueueService: offlineQueueService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: const JalanCerdasApp(),
    ),
  );
}
