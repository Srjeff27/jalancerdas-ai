import 'package:flutter/material.dart';
import '../services/detection_service.dart';

class DetectionOverlay extends StatelessWidget {
  final List<BoundingBox> detections;
  final int imageWidth;
  final int imageHeight;

  const DetectionOverlay({
    super.key,
    required this.detections,
    this.imageWidth = 640,
    this.imageHeight = 480,
  });

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetWidth = constraints.maxWidth;
        final widgetHeight = constraints.maxHeight;

        // Calculate scale factors to map image coords to widget coords
        final scaleX = widgetWidth / imageWidth;
        final scaleY = widgetHeight / imageHeight;

        return CustomPaint(
          size: Size(widgetWidth, widgetHeight),
          painter: DetectionPainter(
            detections: detections,
            scaleX: scaleX,
            scaleY: scaleY,
          ),
        );
      },
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<BoundingBox> detections;
  final double scaleX;
  final double scaleY;

  DetectionPainter({
    required this.detections,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      // Scale coordinates from image space to widget space
      final x = detection.x * scaleX;
      final y = detection.y * scaleY;
      final w = detection.width * scaleX;
      final h = detection.height * scaleY;

      // Skip if box is outside visible area
      if (x + w < 0 || y + h < 0 || x > size.width || y > size.height) {
        continue;
      }

      final paint = Paint()
        ..color = _getColor(detection.classIndex)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(4),
      );

      // Draw bounding box
      canvas.drawRRect(rect, paint);

      // Draw fill with low opacity
      final fillPaint = Paint()
        ..color = _getColor(detection.classIndex).withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, fillPaint);

      // Draw confidence label
      final labelText =
          '${DetectionService.labels[detection.classIndex]} ${(detection.confidence * 100).toStringAsFixed(0)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: (12 * (scaleX > 1 ? 1 : scaleX)).clamp(10, 14).toDouble(),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelPaint = Paint()
        ..color = _getColor(detection.classIndex)
        ..style = PaintingStyle.fill;

      final labelY = y - 24 > 0 ? y - 24 : y;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, labelY, textPainter.width + 12, 22),
        const Radius.circular(4),
      );

      canvas.drawRRect(labelRect, labelPaint);
      textPainter.paint(canvas, Offset(x + 6, labelY + 3));

      // Draw corner markers
      _drawCornerMarkers(canvas, x, y, w, h, detection.classIndex);
    }
  }

  void _drawCornerMarkers(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    int classIndex,
  ) {
    final cornerPaint = Paint()
      ..color = _getColor(classIndex)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerSize = 16.0;

    // Top-left
    canvas.drawLine(Offset(x, y), Offset(x + cornerSize, y), cornerPaint);
    canvas.drawLine(Offset(x, y), Offset(x, y + cornerSize), cornerPaint);

    // Top-right
    canvas.drawLine(
        Offset(x + w, y), Offset(x + w - cornerSize, y), cornerPaint);
    canvas.drawLine(
        Offset(x + w, y), Offset(x + w, y + cornerSize), cornerPaint);

    // Bottom-left
    canvas.drawLine(
        Offset(x, y + h), Offset(x + cornerSize, y + h), cornerPaint);
    canvas.drawLine(
        Offset(x, y + h), Offset(x, y + h - cornerSize), cornerPaint);

    // Bottom-right
    canvas.drawLine(
        Offset(x + w, y + h), Offset(x + w - cornerSize, y + h), cornerPaint);
    canvas.drawLine(
        Offset(x + w, y + h), Offset(x + w, y + h - cornerSize), cornerPaint);
  }

  Color _getColor(int classIndex) {
    switch (classIndex) {
      case 0:
        return const Color(0xFFFF5252); // retak_memanjang - red
      case 1:
        return const Color(0xFFFF9800); // pengelupasan - orange
      case 2:
        return const Color(0xFF9C27B0); // lubang - purple
      case 3:
        return const Color(0xFF2196F3); // retak_kulit_buaya - blue
      case 4:
        return const Color(0xFF00E676); // retak_blok - green
      case 5:
        return const Color(0xFFE91E63); // retak_pinggir - pink
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections.length != detections.length ||
        oldDelegate.detections != detections ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY;
  }
}
