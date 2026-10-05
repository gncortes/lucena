import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A curva do rating partida a partida, com a área embaixo dela.
class RatingSparkline extends StatelessWidget {
  const RatingSparkline({
    required this.ratings,
    this.height = 72,
    this.strokeWidth = 2.5,
    super.key,
  });

  /// Da partida mais antiga para a mais recente.
  final List<double> ratings;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (ratings.length < 2) return SizedBox(height: height);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _Curve(
            ratings,
            line: colors.primary,
            fill: colors.primary.withValues(alpha: 0.12),
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _Curve extends CustomPainter {
  _Curve(
    this.values, {
    required this.line,
    required this.fill,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color line;
  final Color fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(math.min) - 10;
    final high = values.reduce(math.max) + 10;
    Offset point(int index) => Offset(
      size.width * index / (values.length - 1),
      size.height * (1 - (values[index] - low) / (high - low)),
    );
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < values.length; index++) {
      path.lineTo(point(index).dx, point(index).dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_Curve old) =>
      old.values != values || old.line != line || old.fill != fill;
}
