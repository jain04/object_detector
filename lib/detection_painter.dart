// lib/detection_painter.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // For CameraLensDirection

class DetectionPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size originalImageSize;
  final Size previewScreenSize;
  final Orientation screenOrientation;
  final CameraLensDirection cameraLensDirection;

  DetectionPainter({
    required this.detections,
    required this.originalImageSize,
    required this.previewScreenSize,
    required this.screenOrientation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (originalImageSize.isEmpty || previewScreenSize.isEmpty) {
      // print("Painter: Original or Preview size is empty. Original: $originalImageSize, Preview: $previewScreenSize");
      return;
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final Paint textBgPaint = Paint()..color = Colors.red.withOpacity(0.7);

    for (var detection in detections) {
      if (detection is! Map<String, dynamic>) continue;

      final Map<String, dynamic>? boundingBox = detection['boundingBox'] as Map<String, dynamic>?;
      if (boundingBox == null) continue;

      final double normLeft = boundingBox['left']?.toDouble() ?? 0.0;
      final double normTop = boundingBox['top']?.toDouble() ?? 0.0;
      final double normRight = boundingBox['right']?.toDouble() ?? 0.0;
      final double normBottom = boundingBox['bottom']?.toDouble() ?? 0.0;

      final double scaleX = previewScreenSize.width / originalImageSize.width;
      final double scaleY = previewScreenSize.height / originalImageSize.height;
      final double scale = (scaleX < scaleY) ? scaleX : scaleY;

      final double offsetX = (previewScreenSize.width - originalImageSize.width * scale) / 2;
      final double offsetY = (previewScreenSize.height - originalImageSize.height * scale) / 2;

      double actualLeft = normLeft * (originalImageSize.width * scale) + offsetX;
      double actualTop = normTop * (originalImageSize.height * scale) + offsetY;
      double actualRight = normRight * (originalImageSize.width * scale) + offsetX;
      double actualBottom = normBottom * (originalImageSize.height * scale) + offsetY;

      if (cameraLensDirection == CameraLensDirection.front) {
        double tempLeft = actualLeft;
        actualLeft = previewScreenSize.width - actualRight;
        actualRight = previewScreenSize.width - tempLeft;
      }

      final Rect rect = Rect.fromLTRB(actualLeft, actualTop, actualRight, actualBottom);
      canvas.drawRect(rect, paint);

      final List<dynamic>? labels = detection['labels'] as List<dynamic>?;
      if (labels != null && labels.isNotEmpty) {
        final Map<String, dynamic> firstLabel = labels.first as Map<String, dynamic>;
        final String text = firstLabel['text'] as String;
        final double confidence = (firstLabel['confidence'] as num).toDouble();

        final TextSpan span = TextSpan(
          text: '$text (${(confidence * 100).toStringAsFixed(0)}%)',
          style: TextStyle(color: Colors.white, fontSize: 12),
        );
        final TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
        tp.layout();

        // Draw background for text
        canvas.drawRect(
          Rect.fromLTWH(
            cameraLensDirection == CameraLensDirection.front ? actualRight - tp.width - 4 : actualLeft + 2,
            actualTop - tp.height - 4, // Position above the box
            tp.width + 4, // A little padding
            tp.height + 4  // A little padding
          ),
          textBgPaint,
        );
        // Paint the text
        tp.paint(canvas, Offset(
            cameraLensDirection == CameraLensDirection.front ? actualRight - tp.width - 2 : actualLeft + 4,
            actualTop - tp.height -2)
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
           oldDelegate.originalImageSize != originalImageSize ||
           oldDelegate.previewScreenSize != previewScreenSize ||
           oldDelegate.screenOrientation != screenOrientation ||
           oldDelegate.cameraLensDirection != cameraLensDirection;
  }
}