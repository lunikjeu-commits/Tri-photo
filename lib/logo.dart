import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

class LcLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.accent, AppColors.accent2],
    ).createShader(rect);

    final frame = RRect.fromRectAndRadius(
        rect.deflate(s * 0.03), Radius.circular(s * 0.28));
    canvas.drawRRect(frame, Paint()..color = const Color(0x14FFFFFF));
    canvas.drawRRect(
        frame,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04);

    final stroke = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Lettre L
    final l = Path()
      ..moveTo(s * 0.30, s * 0.26)
      ..lineTo(s * 0.30, s * 0.72)
      ..lineTo(s * 0.54, s * 0.72);
    canvas.drawPath(l, stroke);

    // Lettre C (imbriquée avec le pied du L)
    final c = Rect.fromCircle(center: Offset(s * 0.60, s * 0.49), radius: s * 0.21);
    canvas.drawArc(c, -math.pi / 4, -1.5 * math.pi, false, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
