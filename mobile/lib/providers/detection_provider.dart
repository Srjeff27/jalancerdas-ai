import 'dart:async';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/detection_record.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/detection_service.dart';
import '../services/upload_service.dart';
import '../services/offline_queue_service.dart';

class DetectionProvider extends ChangeNotifier {
  final CameraService _cameraService;
  final LocationService _locationService;
  final DetectionService _detectionService;
  final UploadService _uploadService;
  final OfflineQueueService _offlineQueueService;

  // State
  bool _isDetecting = false;
  int _detectionCount = 0;
  double _currentConfidence = 0.0;
  DetectionRecord? _lastDetection;
  bool _isConnected = true;
  bool _hasGps = false;
  bool _hasCamera = false;
  List<BoundingBox> _currentDetections = [];
  bool _mockMode = true;
  Timer? _detectionTimer;

  // Getters
  bool get isDetecting => _isDetecting;
  int get detectionCount => _detectionCount;
  double get currentConfidence => _currentConfidence;
  DetectionRecord? get lastDetection => _lastDetection;
  bool get isConnected => _isConnected;
  bool get hasGps => _hasGps;
  bool get hasCamera => _hasCamera;
  List<BoundingBox> get currentDetections => _currentDetections;
  bool get mockMode => _mockMode;
  CameraController? get cameraController => _cameraService.controller;

  DetectionProvider({
    required CameraService cameraService,
    required LocationService locationService,
    required DetectionService detectionService,
    required UploadService uploadService,
    required OfflineQueueService offlineQueueService,
  })  : _cameraService = cameraService,
        _locationService = locationService,
        _detectionService = detectionService,
        _uploadService = uploadService,
        _offlineQueueService = offlineQueueService {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load detection model
    await _detectionService.loadModel();
    _mockMode = _detectionService.isMockMode;

    // Initialize camera
    await _cameraService.initialize();
    _hasCamera = _cameraService.hasCamera;

    // Request GPS permission
    final hasPermission = await _locationService.requestPermission();
    if (hasPermission) {
      await _locationService.getCurrentPosition();
      _hasGps = _locationService.currentPosition != null;

      // Start continuous tracking
      await _locationService.startTracking(
        onPositionUpdate: (position) {
          _hasGps = true;
          notifyListeners();
        },
      );
    }

    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;
      if (!wasConnected && _isConnected) {
        // Connectivity restored - handled by OfflineQueueService
      }
      notifyListeners();
    });

    // Setup offline queue retry
    _offlineQueueService.initialize(
      onRetryUpload: (record) async {
        final success = await _uploadService.uploadDetection(record);
        if (success) {
          record.uploaded = true;
          record.status = DetectionStatus.uploaded;
          _saveDetection(record);
        }
        return success;
      },
    );

    notifyListeners();
  }

  /// Start detection loop
  Future<void> startDetection() async {
    if (_isDetecting) return;

    _isDetecting = true;
    notifyListeners();

    // Start periodic detection
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
      (_) => _processFrame(),
    );

    // Also try image stream if camera is available
    if (_hasCamera && _cameraService.isInitialized) {
      try {
        await _cameraService.startImageStream((CameraImage image) {
          _processImageFrame(image);
        });
      } catch (e) {
        debugPrint('DetectionProvider: Could not start image stream: $e');
      }
    }
  }

  /// Stop detection
  Future<void> stopDetection() async {
    _isDetecting = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _currentDetections = [];

    if (_hasCamera && _cameraService.isInitialized) {
      await _cameraService.stopImageStream();
    }

    notifyListeners();
  }

  /// Process a single frame from timer
  void _processFrame() {
    if (!_isDetecting) return;

    // Get current position
    final position = _locationService.currentPosition;
    final lat = position?.latitude ?? -6.2088; // Default: Jakarta
    final lng = position?.longitude ?? 106.8456;

    if (_mockMode) {
      _processMockFrame(lat, lng);
    }
  }

  /// Process a camera image frame
  void _processImageFrame(CameraImage image) {
    if (!_isDetecting) return;

    final position = _locationService.currentPosition;
    final lat = position?.latitude ?? -6.2088;
    final lng = position?.longitude ?? 106.8456;

    // Run detection
    _detectionService.detectFromImage(image).then((result) {
      _currentDetections = result.detections;

      if (result.detections.isNotEmpty) {
        // Find highest confidence detection
        final best = result.detections.reduce(
          (a, b) => a.confidence > b.confidence ? a : b,
        );

        _currentConfidence = best.confidence;

        // Process detection
        _handleDetection(best.classIndex, best.confidence, lat, lng);
      }

      notifyListeners();
    });
  }

  /// Process mock detection
  void _processMockFrame(double lat, double lng) {
    final mockDetection = _detectionService.generateMockDetection(
      baseLatitude: lat,
      baseLongitude: lng,
    );

    _currentConfidence = mockDetection.confidence;
    _currentDetections = [];

    _handleDetection(
      mockDetection.damageType.index,
      mockDetection.confidence,
      lat,
      lng,
    );
  }

  /// Handle a detection event
  void _handleDetection(int classIndex, double confidence, double lat, double lng) {
    // Create detection record
    final record = DetectionRecord(
      id: 'det_${DateTime.now().millisecondsSinceEpoch}',
      damageType: DetectionService.labels.length > classIndex
          ? DamageType.values[classIndex]
          : DamageType.other,
      confidence: confidence,
      latitude: lat,
      longitude: lng,
      detectedAt: DateTime.now(),
      status: DetectionStatus.detected,
      uploaded: false,
    );

    _lastDetection = record;
    _detectionCount++;
    notifyListeners();

    // Save to Hive
    _saveDetection(record);

    // Auto-upload if enabled and connected
    _tryUpload(record);
  }

  /// Save detection to local Hive storage
  void _saveDetection(DetectionRecord record) {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      box.put(record.id, record);
    } catch (e) {
      debugPrint('DetectionProvider: Failed to save detection: $e');
    }
  }

  /// Try to upload detection
  Future<void> _tryUpload(DetectionRecord record) async {
    if (!_isConnected) {
      await _offlineQueueService.enqueue(record);
      return;
    }

    try {
      final success = await _uploadService.uploadDetection(record);
      if (success) {
        record.uploaded = true;
        record.status = DetectionStatus.uploaded;
        _saveDetection(record);
      } else {
        await _offlineQueueService.enqueue(record);
      }
    } catch (e) {
      await _offlineQueueService.enqueue(record);
    }
  }

  /// Take a manual picture
  Future<String?> takePicture() async {
    return await _cameraService.takePicture();
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
    _hasCamera = _cameraService.hasCamera;
    notifyListeners();
  }

  /// Get all detection records from Hive
  List<DetectionRecord> getAllDetections() {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      final records = box.values.toList();
      records.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      return records;
    } catch (e) {
      return [];
    }
  }

  /// Get detection by ID
  DetectionRecord? getDetectionById(String id) {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      return box.get(id);
    } catch (e) {
      return null;
    }
  }

  /// Delete detection
  Future<void> deleteDetection(String id) async {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      await box.delete(id);
      notifyListeners();
    } catch (e) {
      debugPrint('DetectionProvider: Failed to delete detection: $e');
    }
  }

  /// Clear all detections
  Future<void> clearAllDetections() async {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      await box.clear();
      _detectionCount = 0;
      _lastDetection = null;
      notifyListeners();
    } catch (e) {
      debugPrint('DetectionProvider: Failed to clear detections: $e');
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraService.dispose();
    _locationService.dispose();
    _detectionService.dispose();
    super.dispose();
  }
}
