import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
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

  /// Start image stream for continuous detection
  Future<void> startImageStream(CameraImageCallback onImageAvailable) async {
    if (!_isInitialized || _controller == null) return;

    try {
      await _controller!.startImageStream(onImageAvailable);
    } catch (e) {
      debugPrint('CameraService: Failed to start image stream: $e');
    }
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    if (_controller == null) return;

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint('CameraService: Failed to stop image stream: $e');
    }
  }

  /// Switch between front and back cameras
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCamera(_cameras[_currentCameraIndex]);
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
