import 'package:flutter/material.dart';

// App constants, colors, and default values
class AppColors {
  AppColors._();

  // Primary palette
  static const primary = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF2563EB);

  // Accent
  static const accent = Color(0xFF06D6A0);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);

  // Backgrounds
  static const bgDark = Color(0xFF0F172A);
  static const bgCard = Color(0xFF1E293B);
  static const bgCardLight = Color(0xFF334155);
  static const bgSurface = Color(0xFF0F172A);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  // Damage type colors
  static const damageRetakMemanjang = Color(0xFFEF4444);
  static const damagePengelupasan = Color(0xFFF97316);
  static const damageLubang = Color(0xFFA855F7);
  static const damageRetakKulitBuaya = Color(0xFF3B82F6);
  static const damageRetakBlok = Color(0xFF10B981);
  static const damageRetakPinggir = Color(0xFFEC4899);

  // Status bar / nav
  static const navBg = Color(0xFF1E293B);
  static const navActive = Color(0xFF3B82F6);
  static const navInactive = Color(0xFF64748B);
}

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'JalanCerdas AI';
  static const String appVersion = '1.2.0';

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
