import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
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
        return DamageType.pothole;
      case 1:
        return DamageType.crack;
      case 2:
        return DamageType.depression;
      case 3:
        return DamageType.bump;
      default:
        return DamageType.other;
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
  dynamic _interpreter;
  bool _modelLoaded = false;
  bool _mockMode = false;

  // YOLO model config
  static const int inputSize = 640;
  static const int numClasses = 5; // pothole, crack, depression, bump, other
  static const double confidenceThreshold = 0.5;
  static const double nmsIouThreshold = 0.45;

  // Damage type labels
  static const List<String> labels = [
    'pothole',
    'crack',
    'depression',
    'bump',
    'other',
  ];

  bool get isModelLoaded => _modelLoaded;
  bool get isMockMode => _mockMode;

  /// Load TFLite model from assets
  Future<bool> loadModel() async {
    try {
      // Try loading TFLite model
      // In production, load from assets/models/model.tflite
      // _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      // _modelLoaded = true;

      // For now, fall back to mock mode
      debugPrint('DetectionService: TFLite model not found, using mock mode');
      _mockMode = true;
      _modelLoaded = false;
      return false;
    } catch (e) {
      debugPrint('DetectionService: Failed to load model: $e');
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

    // Prepare output buffer
    final output = List.filled(
      1 * 5 * (5 + numClasses) * inputSize * inputSize,
      0.0,
    ).reshape([1, 5, 5 + numClasses, inputSize, inputSize]);

    // Run inference
    _interpreter.run(input, output);

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
  dynamic _preprocessImage(CameraImage image) {
    // Convert YUV420 to RGB and resize
    // This is a simplified version - production would need proper conversion
    return image.planes[0].bytes;
  }

  /// Parse YOLO output tensor into bounding boxes
  List<BoundingBox> _parseOutput(
    dynamic output,
    double threshold,
    int imgWidth,
    int imgHeight,
  ) {
    final detections = <BoundingBox>[];

    // YOLO output parsing
    // Output shape: [1, 5, 5 + numClasses, inputSize, inputSize]
    // For each grid cell, check if confidence > threshold

    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        for (int k = 0; k < 5; k++) {
          final objConf = output[0][k][4][i][j] as double;
          if (objConf > threshold) {
            // Find best class
            int bestClass = 0;
            double bestClassScore = 0;
            for (int c = 0; c < numClasses; c++) {
              final score = output[0][k][5 + c][i][j] as double;
              if (score > bestClassScore) {
                bestClassScore = score;
                bestClass = c;
              }
            }

            final confidence = objConf * bestClassScore;
            if (confidence > threshold) {
              // Decode bounding box
              final cx = (output[0][k][0][i][j] as double) / inputSize;
              final cy = (output[0][k][1][i][j] as double) / inputSize;
              final w = (output[0][k][2][i][j] as double) / inputSize;
              final h = (output[0][k][3][i][j] as double) / inputSize;

              detections.add(BoundingBox(
                x: (cx - w / 2) * imgWidth,
                y: (cy - h / 2) * imgHeight,
                width: w * imgWidth,
                height: h * imgHeight,
                classIndex: bestClass,
                confidence: confidence,
              ));
            }
          }
        }
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
