import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/detection_record.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/detection_service.dart';
import '../services/upload_service.dart';
import '../services/offline_queue_service.dart';
import '../utils/annotation_painter.dart';

class DetectionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final CameraService _cameraService;
  final LocationService _locationService;
  final DetectionService _detectionService;
  final UploadService _uploadService;
  final OfflineQueueService _offlineQueueService;

  // State
  bool _isDetecting = false;
  bool _shouldBeDetecting = false; // User intent
  int _detectionCount = 0;
  double _currentConfidence = 0.0;
  DetectionRecord? _lastDetection;
  bool _isConnected = true;
  bool _hasGps = false;
  bool _hasCamera = false;
  bool _mockMode = true;
  Timer? _detectionTimer;

  // Persistent detections — survive across frames until explicitly cleared
  List<BoundingBox> _currentDetections = [];
  List<BoundingBox> _lastPersistedDetections = [];

  // Getters
  bool get isDetecting => _isDetecting;
  int get detectionCount => _detectionCount;
  double get currentConfidence => _currentConfidence;
  DetectionRecord? get lastDetection => _lastDetection;
  bool get isConnected => _isConnected;
  bool get hasGps => _hasGps;
  bool get hasCamera => _hasCamera;
  List<BoundingBox> get currentDetections => _currentDetections;
  List<BoundingBox> get lastPersistedDetections => _lastPersistedDetections;
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
    WidgetsBinding.instance.addObserver(this);
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

    // Auto-start detection after everything is ready
    // Small delay to ensure camera preview is rendered
    await Future.delayed(const Duration(milliseconds: 500));
    if (_hasCamera || _mockMode) {
      startDetection();
    }
  }

  // ─── Lifecycle Handling ──────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause detection when app is not visible
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_isDetecting) {
        _pauseDetection();
      }
    }

    // Resume detection when app comes back
    if (state == AppLifecycleState.resumed) {
      if (_shouldBeDetecting) {
        _resumeDetection();
      }
    }
  }

  void _pauseDetection() async {
    _isDetecting = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;

    if (_hasCamera && _cameraService.isInitialized) {
      await _cameraService.stopImageStream();
    }

    debugPrint('DetectionProvider: Paused (app lifecycle)');
    notifyListeners();
  }

  Future<void> _resumeDetection() async {
    if (_isDetecting) return;

    debugPrint('DetectionProvider: Resuming...');
    _isDetecting = true;
    notifyListeners();

    if (_hasCamera && _cameraService.isInitialized) {
      final started = await _cameraService.startImageStream((CameraImage image) {
        _processImageFrame(image);
      });

      if (!started) {
        debugPrint('DetectionProvider: Failed to resume image stream');
        _isDetecting = false;
        _shouldBeDetecting = false;
        notifyListeners();
      }
    } else {
      // Timer fallback
      _detectionTimer = Timer.periodic(
        const Duration(milliseconds: 2000),
        (_) => _processFrame(),
      );
    }
  }

  // ─── Detection Control ──────────────────────────────────────

  /// Start detection loop
  Future<void> startDetection() async {
    if (_isDetecting) return;

    _shouldBeDetecting = true;
    _isDetecting = true;
    notifyListeners();

    // Use image stream if camera is available (real-time detection)
    if (_hasCamera && _cameraService.isInitialized) {
      final started = await _cameraService.startImageStream((CameraImage image) {
        _processImageFrame(image);
      });

      if (started) {
        debugPrint('DetectionProvider: Image stream active');
        return;
      }
      debugPrint('DetectionProvider: Image stream failed, falling back to timer');
    }

    // Fallback: periodic timer when no camera stream
    debugPrint('DetectionProvider: Using timer for detection');
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
      (_) => _processFrame(),
    );
  }

  /// Stop detection
  Future<void> stopDetection() async {
    _shouldBeDetecting = false;
    _isDetecting = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _currentDetections = [];
    _lastPersistedDetections = [];

    if (_hasCamera && _cameraService.isInitialized) {
      await _cameraService.stopImageStream();
    }

    notifyListeners();
  }

  // ─── Frame Processing ───────────────────────────────────────

  /// Process a single frame from timer
  void _processFrame() {
    if (!_isDetecting) return;

    final position = _locationService.currentPosition;
    final lat = position?.latitude ?? -6.2088;
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

    // Use higher threshold to reduce false positives
    final threshold = _detectionService.isModelLoaded ? 0.55 : 0.5;

    // Run detection
    _detectionService.detectFromImage(image, threshold: threshold).then((result) {
      if (!_isDetecting) return;

      if (result.detections.isNotEmpty) {
        _currentDetections = result.detections;
        _lastPersistedDetections = List.from(result.detections);

        final best = result.detections.reduce(
          (a, b) => a.confidence > b.confidence ? a : b,
        );

        _currentConfidence = best.confidence;

        // Only count if confidence is high enough
        if (best.confidence >= 0.6) {
          _handleDetection(best.classIndex, best.confidence, lat, lng, result.detections);
        }
      } else {
        _currentDetections = [];
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

    final mockBox = BoundingBox(
      x: 100 + (DateTime.now().millisecond % 400).toDouble(),
      y: 50 + (DateTime.now().millisecond % 200).toDouble(),
      width: 80 + (DateTime.now().millisecond % 80).toDouble(),
      height: 60 + (DateTime.now().millisecond % 60).toDouble(),
      classIndex: mockDetection.damageType.index,
      confidence: mockDetection.confidence,
    );
    _currentDetections = [mockBox];
    _lastPersistedDetections = [mockBox];

    _handleDetection(
      mockDetection.damageType.index,
      mockDetection.confidence,
      lat,
      lng,
      [mockBox],
    );
  }

  // ─── Detection Handling ─────────────────────────────────────

  String? _lastDetectedImagePath;
  String? get lastDetectedImagePath => _lastDetectedImagePath;

  void _handleDetection(
    int classIndex,
    double confidence,
    double lat,
    double lng,
    List<BoundingBox> detections,
  ) async {
    final record = DetectionRecord(
      id: 'det_${DateTime.now().millisecondsSinceEpoch}',
      damageType: classIndex >= 0 && classIndex < DamageType.values.length
          ? DamageType.values[classIndex]
          : DamageType.retak_pinggir,
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

    // Auto-capture + annotate photo
    try {
      final imagePath = await _cameraService.takePicture();
      if (imagePath != null) {
        _lastDetectedImagePath = imagePath;
        notifyListeners();

        // Annotate photo with bounding boxes + labels
        final appDir = await getApplicationDocumentsDirectory();
        final annotatedPath = '${appDir.path}/annotated_${record.id}.jpg';

        final imgWidth =
            _cameraService.controller?.value.previewSize?.height?.toInt() ?? 640;
        final imgHeight =
            _cameraService.controller?.value.previewSize?.width?.toInt() ?? 480;

        final savedAnnotatedPath = await AnnotationPainter.annotateAndSave(
          imagePath: imagePath,
          detections: detections,
          imageWidth: imgWidth,
          imageHeight: imgHeight,
          outputPath: annotatedPath,
        );

        record.localImagePath = savedAnnotatedPath;
        _lastDetectedImagePath = savedAnnotatedPath;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DetectionProvider: Auto-capture/annotate failed: $e');
    }

    _saveDetection(record);
    _tryUpload(record);
  }

  // ─── Storage & Upload ───────────────────────────────────────

  void _saveDetection(DetectionRecord record) {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      box.put(record.id, record);
    } catch (e) {
      debugPrint('DetectionProvider: Failed to save detection: $e');
    }
  }

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

  // ─── Public Methods ─────────────────────────────────────────

  Future<String?> takePicture() async {
    return await _cameraService.takePicture();
  }

  Future<void> switchCamera() async {
    await _cameraService.switchCamera();
    _hasCamera = _cameraService.hasCamera;

    // Restart detection if it was active
    if (_shouldBeDetecting) {
      await stopDetection();
      await startDetection();
    }

    notifyListeners();
  }

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

  DetectionRecord? getDetectionById(String id) {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      return box.get(id);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteDetection(String id) async {
    try {
      final record = getDetectionById(id);
      if (record?.localImagePath != null) {
        final file = File(record!.localImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      final box = Hive.box<DetectionRecord>('detections');
      await box.delete(id);
      notifyListeners();
    } catch (e) {
      debugPrint('DetectionProvider: Failed to delete detection: $e');
    }
  }

  Future<void> clearAllDetections() async {
    try {
      final box = Hive.box<DetectionRecord>('detections');
      for (final record in box.values) {
        if (record.localImagePath != null) {
          final file = File(record.localImagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      await box.clear();
      _detectionCount = 0;
      _lastDetection = null;
      _lastDetectedImagePath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('DetectionProvider: Failed to clear detections: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraService.dispose();
    _locationService.dispose();
    _detectionService.dispose();
    super.dispose();
  }
}
