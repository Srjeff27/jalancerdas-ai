import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/detection_service.dart';

/// Utility to render bounding boxes + labels directly onto a captured photo.
/// Used so history photos show exactly what was detected.
class AnnotationPainter {
  /// Annotate an image file with bounding boxes, labels, and coordinates.
  /// Returns the path to the annotated image.
  static Future<String> annotateAndSave({
    required String imagePath,
    required List<BoundingBox> detections,
    required int imageWidth,
    required int imageHeight,
    String? outputPath,
  }) async {
    try {
      // Load original image
      final file = File(imagePath);
      if (!await file.exists()) return imagePath;
      
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create canvas the same size as the original image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      );

      // Draw the original image
      canvas.drawImage(image, Offset.zero, Paint());

      // Scale factor from model input (640) to actual image size
      final scaleX = image.width / 640.0;
      final scaleY = image.height / 640.0;

      // Draw each detection
      for (final detection in detections) {
        final x = detection.x * scaleX;
        final y = detection.y * scaleY;
        final w = detection.width * scaleX;
        final h = detection.height * scaleY;
        final color = _getColor(detection.classIndex);

        // Semi-transparent fill
        final fillPaint = Paint()
          ..color = color.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), fillPaint);

        // Border
        final borderPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), borderPaint);

        // Label background + text
        final label = DetectionService.labels[detection.classIndex];
        final confidence = '${(detection.confidence * 100).toStringAsFixed(0)}%';
        final labelText = '$label $confidence';

        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final labelBg = Paint()..color = color;
        final labelY = y - 22 > 0 ? y - 22 : y;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, labelY, textPainter.width + 12, 22),
            const Radius.circular(4),
          ),
          labelBg,
        );
        textPainter.paint(canvas, Offset(x + 6, labelY + 3));

        // Coordinate text below the box
        final coordText =
            'x:${detection.x.toStringAsFixed(0)} y:${detection.y.toStringAsFixed(0)} '
            'w:${detection.width.toStringAsFixed(0)} h:${detection.height.toStringAsFixed(0)}';

        final coordPainter = TextPainter(
          text: TextSpan(
            text: coordText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        coordPainter.layout();

        final coordBg = Paint()..color = Colors.black.withOpacity(0.7);
        final coordY = y + h + 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, coordY, coordPainter.width + 8, 16),
            const Radius.circular(3),
          ),
          coordBg,
        );
        coordPainter.paint(canvas, Offset(x + 4, coordY + 1));
      }

      // Convert canvas to image
      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(image.width, image.height);
      final byteData = await resultImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return imagePath;

      // Determine output path
      final savePath = outputPath ?? imagePath.replaceAll('.jpg', '_annotated.jpg');

      // Save as JPEG (smaller file size)
      await File(savePath).writeAsBytes(byteData.buffer.asUint8List());

      // Cleanup
      image.dispose();
      resultImage.dispose();

      return savePath;
    } catch (e) {
      debugPrint('AnnotationPainter: Failed to annotate image: $e');
      return imagePath;
    }
  }

  static Color _getColor(int classIndex) {
    switch (classIndex) {
      case 0:
        return const Color(0xFFFF5252);
      case 1:
        return const Color(0xFFFF9800);
      case 2:
        return const Color(0xFF9C27B0);
      case 3:
        return const Color(0xFF2196F3);
      case 4:
        return const Color(0xFF00E676);
      case 5:
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFFFFFFFF);
    }
  }
}
