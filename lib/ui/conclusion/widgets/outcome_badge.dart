import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

/// O que o ícone animado desenha.
enum OutcomeMark { check, cross, record }

/// O resultado em destaque, logo abaixo do cabeçalho da conclusão: o ícone
/// animado à esquerda, o título e a linha de baixo. O ✓ entra com o círculo
/// crescendo, uma onda que se espalha, o traço se desenhando e faíscas; o ✕
/// se desenha em dois traços e balança; o troféu pula e brilha. Com
/// "remover animações" no sistema, já aparece pronto.
class OutcomeStrip extends StatelessWidget {
  const OutcomeStrip({
    required this.mark,
    required this.color,
    required this.title,
    this.subtitle,
    super.key,
  });

  final OutcomeMark mark;
  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          AnimatedMark(mark: mark, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O ícone animado do resultado, num quadrado de [size].
class AnimatedMark extends StatefulWidget {
  const AnimatedMark({
    required this.mark,
    required this.color,
    this.size = 56,
    super.key,
  });

  final OutcomeMark mark;
  final Color color;
  final double size;

  @override
  State<AnimatedMark> createState() => _AnimatedMarkState();
}

class _AnimatedMarkState extends State<AnimatedMark>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).disabled) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _MarkPainter(
          mark: widget.mark,
          color: widget.color,
          t: _controller.value,
        ),
      ),
    ),
  );
}

/// Desenha o quadro [t] (0 a 1) da animação.
class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.mark,
    required this.color,
    required this.t,
  });

  final OutcomeMark mark;
  final Color color;
  final double t;

  // A parte de [t] entre [begin] e [end], de 0 a 1, na curva [curve].
  double _phase(double begin, double end, [Curve curve = AppMotion.enter]) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.36;
    // O ✕ balança depois de desenhado.
    final shake = mark == OutcomeMark.cross
        ? math.sin(_phase(0.6, 1, AppMotion.linear) * math.pi * 4) *
              (1 - _phase(0.6, 1, AppMotion.linear)) *
              size.width *
              0.06
        : 0.0;
    canvas.translate(shake, 0);

    // A onda: um anel que cresce e some.
    final wave = _phase(0.15, 0.7);
    if (wave > 0 && wave < 1) {
      canvas.drawCircle(
        center,
        radius * (1 + 0.45 * wave),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.04 * (1 - wave)
          ..color = color.withValues(alpha: 0.5 * (1 - wave)),
      );
    }

    // O círculo cresce com um pulo.
    final grow = _phase(0, 0.4, AppMotion.pop);
    canvas.drawCircle(center, radius * grow, Paint()..color = color);

    // As faíscas do sucesso.
    if (mark != OutcomeMark.cross) {
      final burst = _phase(0.35, 0.9);
      if (burst > 0 && burst < 1) {
        final spark = Paint()
          ..color = color.withValues(alpha: 1 - burst)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.width * 0.035;
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4 + math.pi / 8;
          final direction = Offset(math.cos(angle), math.sin(angle));
          final from = radius * (1.1 + 0.3 * burst);
          final to = from + radius * 0.22 * (1 - burst);
          canvas.drawLine(
            center + direction * from,
            center + direction * to,
            spark,
          );
        }
      }
    }

    final draw = _phase(0.3, 0.75);
    if (mark == OutcomeMark.record) {
      _record(canvas, center, radius, _phase(0.3, 0.7, AppMotion.pop));
      return;
    }
    final w = radius * 2;
    final origin = center - Offset(radius, radius);
    Offset at(double x, double y) => origin + Offset(w * x, w * y);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final strokes = mark == OutcomeMark.check
        ? [
            Path()
              ..moveTo(at(0.28, 0.52).dx, at(0.28, 0.52).dy)
              ..lineTo(at(0.44, 0.67).dx, at(0.44, 0.67).dy)
              ..lineTo(at(0.73, 0.36).dx, at(0.73, 0.36).dy),
          ]
        : [
            Path()
              ..moveTo(at(0.34, 0.34).dx, at(0.34, 0.34).dy)
              ..lineTo(at(0.66, 0.66).dx, at(0.66, 0.66).dy),
            Path()
              ..moveTo(at(0.66, 0.34).dx, at(0.66, 0.34).dy)
              ..lineTo(at(0.34, 0.66).dx, at(0.34, 0.66).dy),
          ];
    // Cada traço tem a sua parte do tempo.
    for (final (index, path) in strokes.indexed) {
      final share = 1 / strokes.length;
      final local = ((draw - index * share) / share).clamp(0.0, 1.0);
      if (local <= 0) continue;
      for (final PathMetric metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * local), stroke);
      }
    }
  }

  // O recorde: o ícone do Material, crescendo com um pulo.
  void _record(Canvas canvas, Offset center, double radius, double scale) {
    if (scale <= 0) return;
    const icon = Icons.leaderboard_rounded;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: radius * 1.25 * scale,
          color: Colors.white,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.t != t || old.mark != mark || old.color != color;
}
