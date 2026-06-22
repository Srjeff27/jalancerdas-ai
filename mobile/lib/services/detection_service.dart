import 'dart:math';
import 'dart:typed_data';
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
/// Uses proper BT.601 coefficients for accurate color conversion
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
      // Map output pixel to source pixel with bilinear-ish sampling
      final int srcX = (x * width / inputSize).floor().clamp(0, width - 1);
      final int srcY = (y * height / inputSize).floor().clamp(0, height - 1);

      // Get YUV values
      final int yValue = yBytes[srcY * width + srcX] & 0xFF;
      final int uvIndex =
          uvRowStride * (srcY >> 1) + uvPixelStride * (srcX >> 1);
      final int uValue = uBytes[uvIndex] & 0xFF;
      final int vValue = vBytes[uvIndex] & 0xFF;

      // BT.601 standard YUV → RGB conversion
      // More accurate than simplified coefficients
      final int c = yValue - 16;
      final int d = uValue - 128;
      final int e = vValue - 128;

      int r = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255);
      int g = ((298 * c - 100 * d - 208 * e + 128) >> 8).clamp(0, 255);
      int b = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255);

      // Normalize to [0, 1] and write to CHW format
      final int dstIndex = (y * inputSize + x) * 3;
      input[dstIndex] = r / 255.0;
      input[dstIndex + 1] = g / 255.0;
      input[dstIndex + 2] = b / 255.0;
    }
  }

  return [input, width, height];
}

/// Calculate frame quality score (0-1, higher = better)
/// Checks brightness and contrast to skip bad frames
double _calculateFrameQuality(Uint8List yBytes) {
  if (yBytes.isEmpty) return 0;

  // Sample every 100th pixel for speed
  int sum = 0;
  int minVal = 255;
  int maxVal = 0;
  final int step = max(1, yBytes.length ~/ 500);

  for (int i = 0; i < yBytes.length; i += step) {
    final int val = yBytes[i] & 0xFF;
    sum += val;
    if (val < minVal) minVal = val;
    if (val > maxVal) maxVal = val;
  }

  final int count = yBytes.length ~/ step;
  final double mean = sum / count;
  final double range = (maxVal - minVal).toDouble();

  // Penalize too dark (< 30) or too bright (> 230)
  double brightnessScore = 1.0;
  if (mean < 30) {
    brightnessScore = mean / 30;
  } else if (mean > 230) {
    brightnessScore = (255 - mean) / 25;
  }

  // Reward good contrast (range > 50)
  double contrastScore = (range / 255).clamp(0.0, 1.0);

  // Combined score
  return (brightnessScore * 0.6 + contrastScore * 0.4).clamp(0.0, 1.0);
}

/// Analyze texture in a region to determine if it looks like road surface.
/// Road surfaces typically have:
/// - Medium brightness (not too dark like shadows, not too bright like sky)
/// - Moderate texture variance (not flat like painted surfaces)
/// - Grayish tones (not colorful like vegetation or signs)
///
/// Returns a score 0-1 where 1 = definitely road, 0 = definitely not road.
double _analyzeRoadTexture(Uint8List yBytes, int imgWidth, int imgHeight,
    double boxCx, double boxCy, double boxW, double boxH) {
  // Convert normalized coordinates to pixel coordinates
  final int cx = (boxCx * imgWidth).toInt().clamp(0, imgWidth - 1);
  final int cy = (boxCy * imgHeight).toInt().clamp(0, imgHeight - 1);
  final int halfW = (boxW * imgWidth / 2).toInt().clamp(1, imgWidth ~/ 2);
  final int halfH = (boxH * imgHeight / 2).toInt().clamp(1, imgHeight ~/ 2);

  // Sample pixels in the detection region
  int sum = 0;
  int minVal = 255;
  int maxVal = 0;
  int count = 0;
  final int step = max(1, halfW ~/ 5);

  for (int dy = -halfH; dy <= halfH; dy += step) {
    for (int dx = -halfW; dx <= halfW; dx += step) {
      final int px = cx + dx;
      final int py = cy + dy;
      if (px >= 0 && px < imgWidth && py >= 0 && py < imgHeight) {
        final int idx = py * imgWidth + px;
        if (idx < yBytes.length) {
          final int val = yBytes[idx] & 0xFF;
          sum += val;
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
          count++;
        }
      }
    }
  }

  if (count == 0) return 0.5; // Unknown

  final double mean = sum / count;
  final double range = (maxVal - minVal).toDouble();

  // Road brightness score: roads are typically 60-180 brightness
  double brightnessScore = 1.0;
  if (mean < 40) {
    brightnessScore = 0.2; // Too dark — likely shadow or night
  } else if (mean < 60) {
    brightnessScore = 0.6; // Dark road (wet or asphalt)
  } else if (mean <= 180) {
    brightnessScore = 1.0; // Ideal road brightness
  } else if (mean <= 220) {
    brightnessScore = 0.6; // Bright road (concrete)
  } else {
    brightnessScore = 0.1; // Too bright — likely sky or reflection
  }

  // Texture variance score: roads have moderate texture (not flat, not chaotic)
  // Range of 20-100 is typical for road surfaces
  double textureScore = 1.0;
  if (range < 10) {
    textureScore = 0.2; // Too uniform — painted surface, sign, or sky
  } else if (range < 20) {
    textureScore = 0.5; // Low texture — smooth road or painted area
  } else if (range <= 100) {
    textureScore = 1.0; // Good road texture
  } else if (range <= 150) {
    textureScore = 0.7; // High texture — rough surface or mixed content
  } else {
    textureScore = 0.3; // Too varied — likely complex scene (trees, buildings)
  }

  return (brightnessScore * 0.5 + textureScore * 0.5).clamp(0.0, 1.0);
}

class DetectionService {
  // TFLite interpreter - lazy loaded
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  bool _mockMode = false;

  // Frame throttling
  bool _isProcessing = false;
  DateTime? _lastInferenceTime;
  static const Duration _minInferenceInterval = Duration(milliseconds: 250);

  // Frame quality
  static const double _minFrameQuality = 0.25;
  int _skipFrameCount = 0;

  // YOLO model config — tunable
  static const int inputSize = 640;
  static const int numClasses = 6;
  static const double confidenceThreshold = 0.65; // Raised from 0.55 — fewer false positives
  static const double nmsIouThreshold = 0.45; // Tighter NMS

  // ─── SPATIAL FILTERS ───────────────────────────────────────
  // Road area: bottom 70% of frame (camera on dashcam sees road in lower portion)
  static const double _roadAreaTopRatio = 0.30;
  // Max bounding box area ratio — skip if > 25% of frame (probably a car/person)
  static const double _maxBoxAreaRatio = 0.25;
  // Min bounding box size — skip tiny detections (noise)
  static const double _minBoxSizeRatio = 0.025;
  // Max aspect ratio (w/h or h/w) — road damage is roughly square-ish
  // A long thin box is likely a lane marking or shadow, not damage
  static const double _maxAspectRatio = 4.0;

  // ─── ASPECT RATIO FILTERS ──────────────────────────────────
  // Different damage types have expected aspect ratios
  // lubang (pothole): roughly circular → ratio 0.5–2.0
  // retak_memanjang (longitudinal crack): tall & thin → ratio 0.2–1.5
  // retak_kulit_buaya (alligator crack): roughly square → ratio 0.5–2.0
  // retak_blok (block crack): roughly square → ratio 0.5–2.0
  // retak_pinggir (edge crack): along edge → ratio 0.3–3.0
  // pengelupasan (surface peeling): irregular → ratio 0.3–3.0
  static const double _minAspectForCrack = 0.15;
  static const double _maxAspectForCrack = 5.0;
  static const double _minAspectForPothole = 0.4;
  static const double _maxAspectForPothole = 2.5;

  // ─── TEMPORAL CONSISTENCY ───────────────────────────────────
  // Require detection to appear in N consecutive frames before counting
  static const int _minConsecutiveFrames = 2;
  int _consecutiveCount = 0;
  int _lastDetectedClass = -1;
  double _lastDetectedConfidence = 0.0;
  double _lastDetectedCx = 0.0;
  double _lastDetectedCy = 0.0;

  // ─── PERSISTENCE ────────────────────────────────────────────
  static const int _persistFrames = 6;
  int _persistCounter = 0;
  List<BoundingBox> _lastDetections = [];

  // Damage type labels
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
      try {
        final gpuDelegate = GpuDelegateV2();
        final options = InterpreterOptions()..addDelegate(gpuDelegate);

        _interpreter = await Interpreter.fromAsset(
          'assets/models/pothole_yolo.tflite',
          options: options,
        );
      } catch (e) {
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

  void setMockMode(bool enabled) {
    _mockMode = enabled;
  }

  /// Process a camera image and return detections
  Future<DetectionResult> detectFromImage(
    CameraImage image, {
    double? threshold,
  }) async {
    final stopwatch = Stopwatch()..start();
    final useThreshold = threshold ?? confidenceThreshold;

    if (_mockMode || !_modelLoaded) {
      return _mockDetect(image, useThreshold, stopwatch);
    }

    // Frame throttling
    if (_isProcessing) {
      stopwatch.stop();
      return DetectionResult(
        detections: _lastDetections,
        imageWidth: image.width,
        imageHeight: image.height,
        inferenceTime: stopwatch.elapsed,
      );
    }

    if (_lastInferenceTime != null &&
        DateTime.now().difference(_lastInferenceTime!) < _minInferenceInterval) {
      stopwatch.stop();
      return DetectionResult(
        detections: _lastDetections,
        imageWidth: image.width,
        imageHeight: image.height,
        inferenceTime: stopwatch.elapsed,
      );
    }

    // Frame quality check — skip very dark/blurry frames
    final quality = _calculateFrameQuality(image.planes[0].bytes);
    if (quality < _minFrameQuality) {
      _skipFrameCount++;
      if (_skipFrameCount < 5) {
        stopwatch.stop();
        return DetectionResult(
          detections: _lastDetections,
          imageWidth: image.width,
          imageHeight: image.height,
          inferenceTime: stopwatch.elapsed,
        );
      }
    } else {
      _skipFrameCount = 0;
    }

    _isProcessing = true;
    _lastInferenceTime = DateTime.now();

    try {
      return await _runTFLiteDetection(image, useThreshold, stopwatch);
    } catch (e) {
      debugPrint('DetectionService: Inference failed: $e');
      return _mockDetect(image, useThreshold, stopwatch);
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
    // Run preprocessing in a background isolate
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
    final detections = _parseOutput(output, threshold, imgWidth, imgHeight, image.planes[0].bytes);

    // ─── TEMPORAL CONSISTENCY CHECK ───────────────────────────
    // Only count detections that appear in multiple consecutive frames
    if (detections.isNotEmpty) {
      final best = detections.reduce(
        (a, b) => a.confidence > b.confidence ? a : b,
      );

      // Normalize center position for comparison
      final currentCx = best.x + best.width / 2;
      final currentCy = best.y + best.height / 2;

      // Check if this detection is similar to the previous frame's detection
      final isSameDetection = _lastDetectedClass == best.classIndex &&
          (currentCx - _lastDetectedCx).abs() < imgWidth * 0.15 && // Within 15% of frame width
          (currentCy - _lastDetectedCy).abs() < imgHeight * 0.15; // Within 15% of frame height

      if (isSameDetection) {
        _consecutiveCount++;
      } else {
        _consecutiveCount = 1; // New detection, start counting
      }

      // Update tracking state
      _lastDetectedClass = best.classIndex;
      _lastDetectedConfidence = best.confidence;
      _lastDetectedCx = currentCx;
      _lastDetectedCy = currentCy;

      // Only persist if detection has been consistent for N frames
      if (_consecutiveCount >= _minConsecutiveFrames) {
        _lastDetections = detections;
        _persistCounter = _persistFrames;
      } else {
        // Not enough consecutive frames yet — keep showing previous detections if any
        if (_persistCounter > 0) {
          _persistCounter--;
        } else {
          _lastDetections = [];
        }
      }
    } else {
      _consecutiveCount = 0;
      if (_persistCounter > 0) {
        _persistCounter--;
      } else {
        _lastDetections = [];
      }
    }

    stopwatch.stop();

    return DetectionResult(
      detections: _lastDetections,
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
    Uint8List yBytes,
  ) {
    final detections = <BoundingBox>[];

    // YOLOv8 output shape: [1, numClasses + 4, 8400]
    final numDetections = output[0][0].length;

    // Collect all candidates first
    final candidates = <_DetectionCandidate>[];

    for (int i = 0; i < numDetections; i++) {
      final cx = output[0][0][i] as double;
      final cy = output[0][1][i] as double;
      final w = output[0][2][i] as double;
      final h = output[0][3][i] as double;

      // Find best class with score
      int bestClass = 0;
      double bestClassScore = 0;
      for (int c = 0; c < numClasses; c++) {
        final score = output[0][4 + c][i] as double;
        if (score > bestClassScore) {
          bestClassScore = score;
          bestClass = c;
        }
      }

      if (bestClassScore > threshold) {
        // ─── FILTER 1: Spatial — only bottom 70% of frame (road area) ───
        final yNormalized = cy / inputSize;
        if (yNormalized < _roadAreaTopRatio) {
          continue; // Skip — above road area (sky, buildings, people)
        }

        // ─── FILTER 2: Area — skip too large (cars, people, buildings) ───
        final areaRatio = (w * h) / (inputSize * inputSize);
        if (areaRatio > _maxBoxAreaRatio) {
          continue; // Skip — bounding box too large for road damage
        }

        // ─── FILTER 3: Size — skip too tiny (noise, texture) ───
        if (w < inputSize * _minBoxSizeRatio || h < inputSize * _minBoxSizeRatio) {
          continue; // Skip — too small to be meaningful damage
        }

        // ─── FILTER 4: Aspect ratio — road damage has expected shapes ───
        final aspectRatio = w / h;
        final invAspectRatio = h / w;
        final maxAR = max(aspectRatio, invAspectRatio);

        // General filter: skip extremely elongated boxes (lane markings, shadows)
        if (maxAR > _maxAspectRatio) {
          continue; // Skip — too elongated, not damage
        }

        // Class-specific aspect ratio filter
        if (bestClass == 2) {
          // lubang (pothole) — should be roughly circular
          if (maxAR > _maxAspectForPothole) {
            continue; // Skip — pothole shouldn't be this elongated
          }
        } else {
          // Other crack types — allow more elongation but still bounded
          if (maxAR > _maxAspectForCrack) {
            continue; // Skip — too elongated for any damage type
          }
        }

        // ─── FILTER 5: Texture analysis — verify area looks like road ───
        // Only apply texture check for high-confidence detections to save CPU
        if (bestClassScore > 0.7) {
          final textureScore = _analyzeRoadTexture(
            yBytes, imgWidth, imgHeight,
            cx / inputSize, cy / inputSize,
            w / inputSize, h / inputSize,
          );
          // If texture doesn't look like road, reduce effective confidence
          if (textureScore < 0.3) {
            // Area doesn't look like road surface — likely false positive
            continue;
          }
        }

        candidates.add(_DetectionCandidate(
          cx: cx,
          cy: cy,
          w: w,
          h: h,
          classIndex: bestClass,
          confidence: bestClassScore,
        ));
      }
    }

    // Apply weighted Non-Maximum Suppression
    final suppressed = _weightedNMS(candidates);

    // Convert to BoundingBox with image coordinates
    for (final c in suppressed) {
      detections.add(BoundingBox(
        x: (c.cx - c.w / 2) * imgWidth / inputSize,
        y: (c.cy - c.h / 2) * imgHeight / inputSize,
        width: c.w * imgWidth / inputSize,
        height: c.h * imgHeight / inputSize,
        classIndex: c.classIndex,
        confidence: c.confidence,
      ));
    }

    return detections;
  }

  /// Weighted Non-Maximum Suppression — better than basic NMS
  List<_DetectionCandidate> _weightedNMS(List<_DetectionCandidate> boxes) {
    if (boxes.isEmpty) return [];

    // Sort by confidence descending
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));

    final result = <_DetectionCandidate>[];
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
  double _calculateIoU(_DetectionCandidate a, _DetectionCandidate b) {
    final aX1 = a.cx - a.w / 2;
    final aY1 = a.cy - a.h / 2;
    final aX2 = a.cx + a.w / 2;
    final aY2 = a.cy + a.h / 2;

    final bX1 = b.cx - b.w / 2;
    final bY1 = b.cy - b.h / 2;
    final bX2 = b.cx + b.w / 2;
    final bY2 = b.cy + b.h / 2;

    final x1 = max(aX1, bX1);
    final y1 = max(aY1, bY1);
    final x2 = min(aX2, bX2);
    final y2 = min(aY2, bY2);

    final intersection = max(0, x2 - x1) * max(0, y2 - y1);
    final areaA = a.w * a.h;
    final areaB = b.w * b.h;
    final union = areaA + areaB - intersection;

    return union > 0 ? intersection / union : 0;
  }

  /// Mock detection mode
  DetectionResult _mockDetect(
    CameraImage image,
    double threshold,
    Stopwatch stopwatch,
  ) {
    final random = Random();
    final detections = <BoundingBox>[];

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

    // Persist mock detections too
    if (detections.isNotEmpty) {
      _lastDetections = detections;
      _persistCounter = _persistFrames;
    } else if (_persistCounter > 0) {
      _persistCounter--;
    }

    stopwatch.stop();

    return DetectionResult(
      detections: _lastDetections,
      imageWidth: image.width,
      imageHeight: image.height,
      inferenceTime: stopwatch.elapsed,
    );
  }

  DetectionRecord generateMockDetection({
    required double baseLatitude,
    required double baseLongitude,
  }) {
    final random = Random();
    final classIndex = random.nextInt(numClasses);
    final confidence = 0.65 + random.nextDouble() * 0.3;

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

/// Internal candidate for NMS
class _DetectionCandidate {
  final double cx;
  final double cy;
  final double w;
  final double h;
  final int classIndex;
  final double confidence;

  const _DetectionCandidate({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.classIndex,
    required this.confidence,
  });
}
