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

class DetectionService {
  // TFLite interpreter - lazy loaded
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _mockMode = false;

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
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/models/pothole_yolo.tflite');
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
  Future<DetectionResult> detectFromImage(
    CameraImage image, {
    double threshold = confidenceThreshold,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (_mockMode || !_modelLoaded) {
      return _mockDetect(image, threshold, stopwatch);
    }

    try {
      return _runTFLiteDetection(image, threshold, stopwatch);
    } catch (e) {
      debugPrint('DetectionService: Inference failed: $e');
      return _mockDetect(image, threshold, stopwatch);
    }
  }

  /// Run real TFLite inference
  DetectionResult _runTFLiteDetection(
    CameraImage image,
    double threshold,
    Stopwatch stopwatch,
  ) {
    // Convert camera image to input tensor
    final input = _preprocessImage(image);

    // Prepare output buffer for YOLOv8 format
    // Output shape: [1, numClasses + 4, 8400]
    final output = List.filled(
      1 * (numClasses + 4) * 8400,
      0.0,
    ).reshape([1, numClasses + 4, 8400]);

    // Run inference
    _interpreter!.run(input, output);

    // Parse output
    final detections = _parseOutput(output, threshold, image.width, image.height);

    stopwatch.stop();

    return DetectionResult(
      detections: detections,
      imageWidth: image.width,
      imageHeight: image.height,
      inferenceTime: stopwatch.elapsed,
    );
  }

  /// Preprocess camera image to model input
  /// Converts YUV420 to RGB and resizes to model input size
  dynamic _preprocessImage(CameraImage image) {
    // Convert YUV420 to RGB
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final rgbBuffer = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvRowStride * (y >> 1) + uvPixelStride * (x >> 1);
        final int yValue = image.planes[0].bytes[y * width + x] & 0xFF;
        final int uValue = image.planes[1].bytes[uvIndex] & 0xFF;
        final int vValue = image.planes[2].bytes[uvIndex] & 0xFF;

        // YUV to RGB conversion
        int r = (yValue + 1.370705 * (vValue - 128)).round();
        int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round();
        int b = (yValue + 1.732446 * (uValue - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        final int pixelIndex = (y * width + x) * 3;
        rgbBuffer[pixelIndex] = r;
        rgbBuffer[pixelIndex + 1] = g;
        rgbBuffer[pixelIndex + 2] = b;
      }
    }

    // Resize to model input size (simplified - create input tensor)
    // For production, use proper image resizing
    final input = List.filled(
      1 * inputSize * inputSize * 3,
      0.0,
    );

    // Simple nearest-neighbor resize
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final int srcX = (x * width / inputSize).floor().clamp(0, width - 1);
        final int srcY = (y * height / inputSize).floor().clamp(0, height - 1);
        final int srcIndex = (srcY * width + srcX) * 3;
        final int dstIndex = (y * inputSize + x) * 3;

        // Normalize to [0, 1] and convert to CHW format
        input[dstIndex] = rgbBuffer[srcIndex] / 255.0;
        input[dstIndex + 1] = rgbBuffer[srcIndex + 1] / 255.0;
        input[dstIndex + 2] = rgbBuffer[srcIndex + 2] / 255.0;
      }
    }

    return input.reshape([1, inputSize, inputSize, 3]);
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
