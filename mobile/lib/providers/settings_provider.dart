import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'app_settings';
  late Box<AppSettings> _box;
  late AppSettings _settings;

  SettingsProvider() {
    _initialize();
  }

  AppSettings get settings => _settings;
  String get apiUrl => _settings.apiUrl;
  double get confidenceThreshold => _settings.confidenceThreshold;
  bool get autoUpload => _settings.autoUpload;
  bool get offlineMode => _settings.offlineMode;
  bool get mockDetectionMode => _settings.mockDetectionMode;
  int get detectionIntervalMs => _settings.detectionIntervalMs;

  Future<void> _initialize() async {
    try {
      _box = await Hive.openBox<AppSettings>(_boxName);

      if (_box.isEmpty) {
        _settings = AppSettings();
        await _box.put('settings', _settings);
      } else {
        _settings = _box.get('settings') ?? AppSettings();
      }
    } catch (e) {
      debugPrint('SettingsProvider: Failed to initialize: $e');
      _settings = AppSettings();
    }
  }

  /// Update API URL
  Future<void> setApiUrl(String url) async {
    _settings.apiUrl = url;
    await _save();
    notifyListeners();
  }

  /// Update confidence threshold
  Future<void> setConfidenceThreshold(double threshold) async {
    _settings.confidenceThreshold = threshold.clamp(0.5, 1.0);
    await _save();
    notifyListeners();
  }

  /// Toggle auto-upload
  Future<void> toggleAutoUpload() async {
    _settings.autoUpload = !_settings.autoUpload;
    await _save();
    notifyListeners();
  }

  /// Toggle offline mode
  Future<void> toggleOfflineMode() async {
    _settings.offlineMode = !_settings.offlineMode;
    await _save();
    notifyListeners();
  }

  /// Toggle mock detection mode
  Future<void> toggleMockDetectionMode() async {
    _settings.mockDetectionMode = !_settings.mockDetectionMode;
    await _save();
    notifyListeners();
  }

  /// Set detection interval
  Future<void> setDetectionInterval(int milliseconds) async {
    _settings.detectionIntervalMs = milliseconds;
    await _save();
    notifyListeners();
  }

  /// Save settings to Hive
  Future<void> _save() async {
    try {
      await _box.put('settings', _settings);
    } catch (e) {
      debugPrint('SettingsProvider: Failed to save: $e');
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _settings = AppSettings();
    await _save();
    notifyListeners();
  }
}
