import 'package:flutter/material.dart';
import '../services/detection_service.dart';

class DetectionOverlay extends StatelessWidget {
  final List<BoundingBox> detections;

  const DetectionOverlay({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: DetectionPainter(detections: detections),
        );
      },
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<BoundingBox> detections;

  DetectionPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final paint = Paint()
        ..color = _getColor(detection.classIndex)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final rect = RRect.fromRectAndRadius(
        detection.classIndex >= 0 && detection.classIndex < 5
            ? Rect.fromLTWH(
                detection.x,
                detection.y,
                detection.width,
                detection.height,
              )
            : Rect.zero,
        const Radius.circular(4),
      );

      // Draw bounding box
      canvas.drawRRect(rect, paint);

      // Draw confidence label
      final labelPaint = Paint()
        ..color = _getColor(detection.classIndex).withOpacity(0.8)
        ..style = PaintingStyle.fill;

      final labelText = '${DetectionService.labels[detection.classIndex]} '
          '${(detection.confidence * 100).toStringAsFixed(1)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          detection.x,
          detection.y - 22,
          textPainter.width + 12,
          20,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(labelRect, labelPaint);
      textPainter.paint(
        canvas,
        Offset(detection.x + 6, detection.y - 20),
      );

      // Draw corner markers
      _drawCornerMarker(canvas, detection, size);
    }
  }

  void _drawCornerMarker(Canvas canvas, BoundingBox detection, Size size) {
    final cornerPaint = Paint()
      ..color = _getColor(detection.classIndex)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerSize = 12.0;

    final x = detection.x;
    final y = detection.y;
    final w = detection.width;
    final h = detection.height;

    // Top-left
    canvas.drawLine(
      Offset(x, y),
      Offset(x + cornerSize, y),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + cornerSize),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(x + w, y),
      Offset(x + w - cornerSize, y),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(x + w, y),
      Offset(x + w, y + cornerSize),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(x, y + h),
      Offset(x + cornerSize, y + h),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(x, y + h),
      Offset(x, y + h - cornerSize),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(x + w, y + h),
      Offset(x + w - cornerSize, y + h),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(x + w, y + h),
      Offset(x + w, y + h - cornerSize),
      cornerPaint,
    );
  }

  Color _getColor(int classIndex) {
    switch (classIndex) {
      case 0:
        return const Color(0xFFFF5252); // pothole - red
      case 1:
        return const Color(0xFFFF9800); // crack - orange
      case 2:
        return const Color(0xFF9C27B0); // depression - purple
      case 3:
        return const Color(0xFF2196F3); // bump - blue
      default:
        return const Color(0xFF00E676); // other - green
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections.length != detections.length ||
        oldDelegate.detections != detections;
  }
}
