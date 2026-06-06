import 'package:flutter/material.dart';
import '../models/models.dart';

class HandwrittenPainter extends CustomPainter {
  final List<Stroke> strokes;

  const HandwrittenPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.isSelected
            ? Colors.blue
            : stroke.color // Highlight selected strokes
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode =
            stroke.isHighlighter ? BlendMode.multiply : BlendMode.srcOver;

      if (stroke.isHighlighter) {
        if (stroke.points.length > 1) {
          final path = Path();
          path.moveTo(stroke.points[0].dx, stroke.points[0].dy);

          for (int i = 0; i < stroke.points.length - 1; i++) {
            if (i < stroke.points.length - 2) {
              final p0 = stroke.points[i];
              final p1 = stroke.points[i + 1];
              final p2 = stroke.points[i + 2];

              final controlPoint = Offset(p1.dx, p1.dy);
              final endPoint = Offset(
                (p1.dx + p2.dx) / 2,
                (p1.dy + p2.dy) / 2,
              );

              path.quadraticBezierTo(
                controlPoint.dx,
                controlPoint.dy,
                endPoint.dx,
                endPoint.dy,
              );
            } else {
              path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
            }
          }

          paint.style = PaintingStyle.stroke;
          canvas.drawPath(path, paint);
        } else {
          canvas.drawCircle(stroke.points[0], stroke.strokeWidth / 2, paint);
        }
      } else {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(HandwrittenPainter oldDelegate) => true;
}
