// App constants and default values
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'JalanCerdas AI';
  static const String appVersion = '1.0.0';

  // Default API URL
  static const String defaultApiUrl = 'http://localhost:8000/api';

  // Detection defaults
  static const double defaultConfidenceThreshold = 0.65;
  static const int defaultDetectionIntervalMs = 2000;
  static const bool defaultAutoUpload = true;
  static const bool defaultOfflineMode = false;
  static const bool defaultMockMode = false;

  // Model config
  static const int modelInputSize = 640;
  static const int numDetectionClasses = 6;
  static const double nmsIouThreshold = 0.45;

  // Labels
  static const List<String> damageTypeLabels = [
    'Lubang',
    'Retak Memanjang',
    'Retak Kulit Buaya',
    'Retak Blok',
    'Retak Pinggir',
    'Pengelupasan Lapisan Permukaan',
  ];

  // Status strings
  static const String statusDetected = 'Detected';
  static const String statusUploaded = 'Uploaded';
  static const String statusQueued = 'Queued';
  static const String statusFailed = 'Failed';

  // Default coordinates (Jakarta, Indonesia)
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;

  // Hive box names
  static const String detectionsBox = 'detections';
  static const String uploadQueueBox = 'upload_queue';
  static const String settingsBox = 'app_settings';
}
