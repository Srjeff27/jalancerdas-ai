import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;
  List<CameraDescription> get cameras => _cameras;
  bool get hasCamera => _cameras.isNotEmpty;

  /// Initialize cameras
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initializeCamera(_cameras[_currentCameraIndex]);
      }
    } catch (e) {
      debugPrint('CameraService: Failed to initialize cameras: $e');
      _isInitialized = false;
    }
  }

  /// Initialize specific camera with lower resolution for detection
  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      await _controller?.dispose();

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('CameraService: Camera initialized successfully');
    } catch (e) {
      debugPrint('CameraService: Failed to initialize camera: $e');
      _isInitialized = false;
    }
  }

  /// Take a picture and return the file path
  Future<String?> takePicture() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('CameraService: Camera not initialized');
      return null;
    }

    try {
      final XFile file = await _controller!.takePicture();
      return file.path;
    } catch (e) {
      debugPrint('CameraService: Failed to take picture: $e');
      return null;
    }
  }

  /// Start image stream for continuous detection.
  /// Includes retry logic — waits for camera to be truly ready.
  Future<bool> startImageStream(void Function(CameraImage) onImageAvailable) async {
    if (!_isInitialized || _controller == null) {
      debugPrint('CameraService: Cannot start stream — camera not initialized');
      return false;
    }

    // If already streaming, don't restart
    if (_isStreaming && _controller!.value.isStreamingImages) {
      debugPrint('CameraService: Already streaming');
      return true;
    }

    // Retry up to 5 times with increasing delay
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        // Wait a bit for camera to stabilize after init
        await Future.delayed(Duration(milliseconds: 300 * attempt));

        if (_controller == null || !_isInitialized) {
          debugPrint('CameraService: Camera disposed during retry');
          return false;
        }

        await _controller!.startImageStream(onImageAvailable);
        _isStreaming = true;
        debugPrint('CameraService: Image stream started (attempt $attempt)');
        return true;
      } catch (e) {
        debugPrint('CameraService: Stream start failed (attempt $attempt): $e');
        if (attempt == 5) {
          debugPrint('CameraService: All retry attempts failed');
          return false;
        }
      }
    }
    return false;
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    if (_controller == null) return;

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      _isStreaming = false;
    } catch (e) {
      debugPrint('CameraService: Failed to stop image stream: $e');
      _isStreaming = false;
    }
  }

  /// Switch between front and back cameras
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    // Stop stream before switching
    await stopImageStream();

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCamera(_cameras[_currentCameraIndex]);
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isStreaming = false;
  }
}
