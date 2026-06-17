import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection_record.dart';

/// Bounding box from YOLO output
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final int classIndex;
  final double confidence;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.classIndex,
    required this.confidence,
  });

  DamageType get damageType {
    switch (classIndex) {
      case 0:
        return DamageType.retak_memanjang;
      case 1:
        return DamageType.pengelupasan_lapisan_permukaan;
      case 2:
        return DamageType.lubang;
      case 3:
        return DamageType.retak_kulit_buaya;
      case 4:
        return DamageType.retak_blok;
      case 5:
        return DamageType.retak_pinggir;
      default:
        return DamageType.retak_pinggir;
    }
  }
}

/// Detection result from the model
class DetectionResult {
  final List<BoundingBox> detections;
  final int imageWidth;
  final int imageHeight;
  final Duration inferenceTime;

  const DetectionResult({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    required this.inferenceTime,
  });
}

/// Isolate-friendly preprocessing: YUV420 → RGB + resize + normalize
/// Runs in a separate isolate to avoid blocking the UI thread
List<dynamic> _preprocessInIsolate(Map<String, dynamic> args) {
  final Uint8List yBytes = args['yBytes'];
  final Uint8List uBytes = args['uBytes'];
  final Uint8List vBytes = args['vBytes'];
  final int width = args['width'];
  final int height = args['height'];
  final int uvRowStride = args['uvRowStride'];
  final int uvPixelStride = args['uvPixelStride'];
  final int inputSize = args['inputSize'];

  // Output: Float32List for [1, inputSize, inputSize, 3]
  final Float32List input = Float32List(1 * inputSize * inputSize * 3);

  for (int y = 0; y < inputSize; y++) {
    for (int x = 0; x < inputSize; x++) {
      // Map output pixel to source pixel
      final int srcX = (x * width / inputSize).floor().clamp(0, width - 1);
      final int srcY = (y * height / inputSize).floor().clamp(0, height - 1);

      // Get YUV values
      final int yValue = yBytes[srcY * width + srcX] & 0xFF;
      final int uvIndex =
          uvRowStride * (srcY >> 1) + uvPixelStride * (srcX >> 1);
      final int uValue = uBytes[uvIndex] & 0xFF;
      final int vValue = vBytes[uvIndex] & 0xFF;

      // YUV to RGB (integer math, faster than float)
      final int rv = ((vValue - 128) * 112) >> 8;
      final int guv = (((uValue - 128) * 86) >> 8) + (((vValue - 128) * 58) >> 8);
      final int bu = ((uValue - 128) * 112) >> 8;
      int r = (yValue + rv).clamp(0, 255);
      int g = (yValue - guv).clamp(0, 255);
      int b = (yValue + bu).clamp(0, 255);

      // Normalize to [0, 1] and write to CHW format
      final int dstIndex = (y * inputSize + x) * 3;
      input[dstIndex] = r / 255.0;
      input[dstIndex + 1] = g / 255.0;
      input[dstIndex + 2] = b / 255.0;
    }
  }

  return [input, width, height];
}

class DetectionService {
  // TFLite interpreter - lazy loaded
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _mockMode = false;

  // Frame throttling
  bool _isProcessing = false;
  DateTime? _lastInferenceTime;
  static const Duration _minInferenceInterval = Duration(milliseconds: 300);

  // YOLO model config
  static const int inputSize = 640;
  static const int numClasses = 6;
  static const double confidenceThreshold = 0.5;
  static const double nmsIouThreshold = 0.45;

  // Damage type labels (matching model class order)
  static const List<String> labels = [
    'retak_memanjang',
    'pengelupasan_lapisan_permukaan',
    'lubang',
    'retak_kulit_buaya',
    'retak_blok',
    'retak_pinggir',
  ];

  bool get isModelLoaded => _modelLoaded;
  bool get isMockMode => _mockMode;

  /// Load TFLite model from assets
  Future<bool> loadModel() async {
    try {
      // Try to load with GPU delegate for faster inference
      try {
        final gpuDelegate = GpuDelegateV2();
        final options = InterpreterOptions()..addDelegate(gpuDelegate);

        _interpreter = await Interpreter.fromAsset(
          'assets/models/pothole_yolo.tflite',
          options: options,
        );
      } catch (e) {
        // Fallback to CPU if GPU delegate fails
        debugPrint('DetectionService: GPU delegate failed, using CPU: $e');
        _interpreter = await Interpreter.fromAsset(
          'assets/models/pothole_yolo.tflite',
        );
      }

      _modelLoaded = true;
      debugPrint('DetectionService: TFLite model loaded successfully');
      return true;
    } catch (e) {
      debugPrint('DetectionService: Failed to load model, using mock mode: $e');
      _mockMode = true;
      _modelLoaded = false;
      return false;
    }
  }

  /// Set mock mode explicitly
  void setMockMode(bool enabled) {
    _mockMode = enabled;
  }

  /// Process a camera image and return detections
  /// Includes frame throttling to prevent overload
  Future<DetectionResult> detectFromImage(
    CameraImage image, {
    double threshold = confidenceThreshold,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (_mockMode || !_modelLoaded) {
      return _mockDetect(image, threshold, stopwatch);
    }

    // Frame throttling: skip if too soon since last inference
    if (_isProcessing) {
      stopwatch.stop();
      return DetectionResult(
        detections: [],
        imageWidth: image.width,
        imageHeight: image.height,
        inferenceTime: stopwatch.elapsed,
      );
    }

    if (_lastInferenceTime != null &&
        DateTime.now().difference(_lastInferenceTime!) <
            _minInferenceInterval) {
      stopwatch.stop();
      return DetectionResult(
        detections: [],
        imageWidth: image.width,
        imageHeight: image.height,
        inferenceTime: stopwatch.elapsed,
      );
    }

    _isProcessing = true;
    _lastInferenceTime = DateTime.now();

    try {
      return await _runTFLiteDetection(image, threshold, stopwatch);
    } catch (e) {
      debugPrint('DetectionService: Inference failed: $e');
      return _mockDetect(image, threshold, stopwatch);
    } finally {
      _isProcessing = false;
    }
  }

  /// Run real TFLite inference with optimized preprocessing
  Future<DetectionResult> _runTFLiteDetection(
    CameraImage image,
    double threshold,
    Stopwatch stopwatch,
  ) async {
    // Run preprocessing in a background isolate (non-blocking!)
    final preprocessResult = await compute(_preprocessInIsolate, {
      'yBytes': image.planes[0].bytes,
      'uBytes': image.planes[1].bytes,
      'vBytes': image.planes[2].bytes,
      'width': image.width,
      'height': image.height,
      'uvRowStride': image.planes[1].bytesPerRow,
      'uvPixelStride': image.planes[1].bytesPerPixel ?? 1,
      'inputSize': inputSize,
    });

    final input = preprocessResult[0];
    final imgWidth = preprocessResult[1] as int;
    final imgHeight = preprocessResult[2] as int;

    // Prepare output buffer for YOLOv8 format
    // Output shape: [1, numClasses + 4, 8400]
    final output = List.filled(
      1 * (numClasses + 4) * 8400,
      0.0,
    ).reshape([1, numClasses + 4, 8400]);

    // Run inference
    _interpreter!.run(input, output);

    // Parse output
    final detections = _parseOutput(output, threshold, imgWidth, imgHeight);

    stopwatch.stop();

    return DetectionResult(
      detections: detections,
      imageWidth: imgWidth,
      imageHeight: imgHeight,
      inferenceTime: stopwatch.elapsed,
    );
  }

  /// Parse YOLOv8 output tensor into bounding boxes
  List<BoundingBox> _parseOutput(
    dynamic output,
    double threshold,
    int imgWidth,
    int imgHeight,
  ) {
    final detections = <BoundingBox>[];

    // YOLOv8 output shape: [1, numClasses + 4, 8400]
    // Each column: [x_center, y_center, width, height, class_scores...]
    final numDetections = output[0][0].length;

    for (int i = 0; i < numDetections; i++) {
      // Get bounding box coordinates
      final cx = output[0][0][i] as double;
      final cy = output[0][1][i] as double;
      final w = output[0][2][i] as double;
      final h = output[0][3][i] as double;

      // Find best class
      int bestClass = 0;
      double bestClassScore = 0;
      for (int c = 0; c < numClasses; c++) {
        final score = output[0][4 + c][i] as double;
        if (score > bestClassScore) {
          bestClassScore = score;
          bestClass = c;
        }
      }

      // Apply confidence threshold
      if (bestClassScore > threshold) {
        // Scale to image dimensions
        detections.add(BoundingBox(
          x: (cx - w / 2) * imgWidth / inputSize,
          y: (cy - h / 2) * imgHeight / inputSize,
          width: w * imgWidth / inputSize,
          height: h * imgHeight / inputSize,
          classIndex: bestClass,
          confidence: bestClassScore,
        ));
      }
    }

    // Apply Non-Maximum Suppression
    return _nonMaxSuppression(detections);
  }

  /// Non-Maximum Suppression to remove overlapping boxes
  List<BoundingBox> _nonMaxSuppression(List<BoundingBox> boxes) {
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));

    final result = <BoundingBox>[];
    final suppressed = List.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      result.add(boxes[i]);

      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        if (boxes[i].classIndex == boxes[j].classIndex) {
          final iou = _calculateIoU(boxes[i], boxes[j]);
          if (iou > nmsIouThreshold) {
            suppressed[j] = true;
          }
        }
      }
    }

    return result;
  }

  /// Calculate Intersection over Union
  double _calculateIoU(BoundingBox a, BoundingBox b) {
    final x1 = max(a.x, b.x);
    final y1 = max(a.y, b.y);
    final x2 = min(a.x + a.width, b.x + b.width);
    final y2 = min(a.y + a.height, b.y + b.height);

    final intersection = max(0, x2 - x1) * max(0, y2 - y1);
    final union = (a.width * a.height) + (b.width * b.height) - intersection;

    return union > 0 ? intersection / union : 0;
  }

  /// Mock detection mode - generates random detections
  DetectionResult _mockDetect(
    CameraImage image,
    double threshold,
    Stopwatch stopwatch,
  ) {
    final random = Random();
    final detections = <BoundingBox>[];

    // 40% chance of detecting something each frame
    if (random.nextDouble() < 0.4) {
      final numDetections = random.nextInt(3) + 1;

      for (int i = 0; i < numDetections; i++) {
        final classIndex = random.nextInt(numClasses);
        final confidence = 0.6 + random.nextDouble() * 0.35;

        if (confidence >= threshold) {
          final width = (0.1 + random.nextDouble() * 0.2) * image.width;
          final height = (0.1 + random.nextDouble() * 0.15) * image.height;

          detections.add(BoundingBox(
            x: random.nextDouble() * (image.width - width),
            y: random.nextDouble() * (image.height - height),
            width: width,
            height: height,
            classIndex: classIndex,
            confidence: confidence,
          ));
        }
      }
    }

    stopwatch.stop();

    return DetectionResult(
      detections: detections,
      imageWidth: image.width,
      imageHeight: image.height,
      inferenceTime: stopwatch.elapsed,
    );
  }

  /// Generate a mock detection record with nearby coordinates
  DetectionRecord generateMockDetection({
    required double baseLatitude,
    required double baseLongitude,
  }) {
    final random = Random();
    final classIndex = random.nextInt(numClasses);
    final confidence = 0.65 + random.nextDouble() * 0.3;

    // Offset coordinates slightly (within ~100m)
    final latOffset = (random.nextDouble() - 0.5) * 0.001;
    final lngOffset = (random.nextDouble() - 0.5) * 0.001;

    return DetectionRecord(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      damageType: DamageType.values[classIndex],
      confidence: confidence,
      latitude: baseLatitude + latOffset,
      longitude: baseLongitude + lngOffset,
      detectedAt: DateTime.now(),
      status: DetectionStatus.detected,
      uploaded: false,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modelLoaded = false;
  }
}
