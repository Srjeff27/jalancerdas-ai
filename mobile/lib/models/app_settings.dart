import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  String apiUrl;

  @HiveField(1)
  double confidenceThreshold;

  @HiveField(2)
  bool autoUpload;

  @HiveField(3)
  bool offlineMode;

  @HiveField(4)
  bool mockDetectionMode;

  @HiveField(5)
  int detectionIntervalMs;

  @HiveField(6)
  String? authToken;

  AppSettings({
    this.apiUrl = 'http://localhost:8000/api/v1',
    this.confidenceThreshold = 0.65,
    this.autoUpload = true,
    this.offlineMode = false,
    this.mockDetectionMode = false,
    this.detectionIntervalMs = 2000,
    this.authToken,
  });
}
