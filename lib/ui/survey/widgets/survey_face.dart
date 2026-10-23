import 'package:flutter/material.dart';

/// O rosto da nota do questionário: disco cheio com olhos e boca vazados
/// (o `FILL 1` do Material Symbols, que o Material Icons não tem). [rating]
/// vai de 1 (muito insatisfeito) a 5 (muito satisfeito).
class SurveyFace extends StatelessWidget {
  const SurveyFace({required this.rating, required this.color, super.key});

  final int rating;
  final Color color;

  /// Lado do ícone (canvas: 36).
  static const size = 36.0;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(size),
    painter: _FacePainter(rating: rating, color: color),
  );
}

class _FacePainter extends CustomPainter {
  const _FacePainter({required this.rating, required this.color});

  final int rating;
  final Color color;

  // Medidas na grade de 24 do Material Symbols.
  static const _grid = 24.0;
  static const _radius = 10.0;
  static const _eyeY = 9.5;
  static const _eyeDx = 3.5;
  static const _eyeRadius = 1.5;
  static const _mouthStroke = 1.6;
  static const _xHalf = 1.2;
  static const _caretHalf = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _grid;
    canvas.scale(k);
    final center = const Offset(_grid / 2, _grid / 2);
    canvas.saveLayer(Offset.zero & const Size.square(_grid), Paint());
    canvas.drawCircle(center, _radius, Paint()..color = color);
    final cut = Paint()..blendMode = BlendMode.clear;
    for (final dx in const [-_eyeDx, _eyeDx]) {
      _eye(canvas, _grid / 2 + dx, cut);
    }
    switch (rating) {
      case 1:
        canvas.drawPath(
          Path()
            ..moveTo(7, 18)
            ..lineTo(17, 18)
            ..quadraticBezierTo(12, 8.5, 7, 18)
            ..close(),
          cut,
        );
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(8.2, 16.4)
            ..quadraticBezierTo(12, 12.8, 15.8, 16.4),
          _stroke(cut),
        );
      case 3:
        canvas.drawLine(
          const Offset(8.5, 15.2),
          const Offset(15.5, 15.2),
          _stroke(cut),
        );
      case 4:
        canvas.drawPath(
          Path()
            ..moveTo(8.2, 14.2)
            ..quadraticBezierTo(12, 17.8, 15.8, 14.2),
          _stroke(cut),
        );
      default:
        canvas.drawPath(
          Path()
            ..moveTo(7, 13)
            ..lineTo(17, 13)
            ..quadraticBezierTo(12, 22.5, 7, 13)
            ..close(),
          cut,
        );
    }
    canvas.restore();
  }

  /// Olho da nota: "x" no 1, "^" no 5 (olho fechado) e redondo nos demais.
  void _eye(Canvas canvas, double x, Paint cut) {
    switch (rating) {
      case 1:
        const r = _xHalf;
        final pen = _stroke(cut);
        canvas.drawLine(
          Offset(x - r, _eyeY - r),
          Offset(x + r, _eyeY + r),
          pen,
        );
        canvas.drawLine(
          Offset(x - r, _eyeY + r),
          Offset(x + r, _eyeY - r),
          pen,
        );
      case 5:
        canvas.drawPath(
          Path()
            ..moveTo(x - _caretHalf, _eyeY + 0.9)
            ..lineTo(x, _eyeY - 0.9)
            ..lineTo(x + _caretHalf, _eyeY + 0.9),
          _stroke(cut),
        );
      default:
        canvas.drawCircle(Offset(x, _eyeY), _eyeRadius, cut);
    }
  }

  Paint _stroke(Paint base) => Paint()
    ..blendMode = base.blendMode
    ..style = PaintingStyle.stroke
    ..strokeWidth = _mouthStroke
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.rating != rating || old.color != color;
}
