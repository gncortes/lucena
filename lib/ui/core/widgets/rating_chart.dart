import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_shape.dart';

/// O rating partida a partida, num gráfico de linha com a escala ao lado.
/// Tocar ou arrastar o dedo mostra o rating daquela partida.
class RatingChart extends StatefulWidget {
  const RatingChart({
    required this.ratings,
    this.height = 200,
    this.highlighted,
    super.key,
  });

  /// Da partida mais antiga para a mais recente.
  final List<double> ratings;

  /// A partida em destaque (o índice em [ratings]): um anel maior e o rating
  /// dela no balão, enquanto o dedo não marca outra. Nula: nenhuma.
  final int? highlighted;
  final double height;

  @override
  State<RatingChart> createState() => _RatingChartState();
}

class _RatingChartState extends State<RatingChart> {
  // A partida debaixo do dedo. Nula: nenhuma marcada.
  int? _selected;

  @override
  void didUpdateWidget(RatingChart old) {
    super.didUpdateWidget(old);
    // Trocou o período: a marca era de outra curva.
    if (old.ratings.length != widget.ratings.length) _selected = null;
  }

  void _select(Offset position, double width) {
    final plot = width - _Plot.axisWidth;
    final count = widget.ratings.length;
    if (plot <= 0 || count < 2) return;
    final x = (position.dx - _Plot.axisWidth).clamp(0, plot);
    final index = (x / plot * (count - 1)).round();
    if (index != _selected) setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (widget.ratings.length < 2) return SizedBox(height: widget.height);
    return ExcludeSemantics(
      // O gráfico não espelha: o tempo corre da esquerda para a direita.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                _select(details.localPosition, constraints.maxWidth),
            onHorizontalDragStart: (details) =>
                _select(details.localPosition, constraints.maxWidth),
            onHorizontalDragUpdate: (details) =>
                _select(details.localPosition, constraints.maxWidth),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: _Plot(
                  widget.ratings,
                  selected: _selected,
                  highlighted: widget.highlighted,
                  line: colors.primary,
                  surface: theme.cardTheme.color ?? colors.surfaceContainerLow,
                  grid: colors.outlineVariant,
                  label:
                      theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ) ??
                      const TextStyle(),
                  bubble: colors.inverseSurface,
                  bubbleText:
                      theme.textTheme.labelLarge?.copyWith(
                        color: colors.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ) ??
                      const TextStyle(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Plot extends CustomPainter {
  _Plot(
    this.values, {
    required this.selected,
    required this.highlighted,
    required this.line,
    required this.surface,
    required this.grid,
    required this.label,
    required this.bubble,
    required this.bubbleText,
  });

  final List<double> values;
  final int? selected;
  final int? highlighted;
  final Color line;
  final Color surface;
  final Color grid;
  final TextStyle label;
  final Color bubble;
  final TextStyle bubbleText;

  /// O espaço da escala, à esquerda da curva.
  static const axisWidth = 40.0;
  static const _top = 28.0;
  static const _bottom = 8.0;
  static const _end = 8.0;

  // Com poucas partidas, cada uma ganha a sua marca.
  static const _maxMarkers = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final step = _step(values.reduce(math.max) - values.reduce(math.min));
    // A escala cobre a curva com folga, em números redondos.
    var low = (values.reduce(math.min) / step).floor() * step;
    var high = (values.reduce(math.max) / step).ceil() * step;
    if (high - low < step * 2) {
      low -= step;
      high += step;
    }
    final plot = Rect.fromLTRB(
      axisWidth,
      _top,
      size.width - _end,
      size.height - _bottom,
    );
    Offset point(int index) => Offset(
      plot.left + plot.width * index / (values.length - 1),
      plot.bottom - plot.height * (values[index] - low) / (high - low),
    );

    // A grade discreta, com o valor de cada linha.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var value = low; value <= high + 0.5; value += step) {
      final y = plot.bottom - plot.height * (value - low) / (high - low);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final text = _text('${value.round()}', label);
      text.paint(
        canvas,
        Offset(plot.left - 8 - text.width, y - text.height / 2),
      );
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < values.length; index++) {
      path.lineTo(point(index).dx, point(index).dy);
    }
    final area = Path.from(path)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas
      ..drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.18), line.withValues(alpha: 0)],
          ).createShader(plot),
      )
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

    // As marcas: todas com poucas partidas; senão, só a última.
    void marker(int index, {double radius = 4}) {
      canvas
        ..drawCircle(point(index), radius + 2, Paint()..color = surface)
        ..drawCircle(point(index), radius, Paint()..color = line);
    }

    if (values.length <= _maxMarkers) {
      for (var index = 0; index < values.length - 1; index++) {
        marker(index);
      }
    }
    marker(values.length - 1, radius: 5);

    // O rating de uma partida no balão do topo, acima da marca dela.
    void bubbleAt(int index) {
      final at = point(index);
      final text = _text('${values[index].round()}', bubbleText);
      final width = text.width + 16;
      final left = (at.dx - width / 2).clamp(0.0, size.width - width);
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, width, text.height + 6),
        const Radius.circular(AppShape.small),
      );
      canvas.drawRRect(box, Paint()..color = bubble);
      text.paint(canvas, Offset(left + 8, 3));
    }

    // A partida em destaque: um anel em volta de uma marca maior.
    final highlighted = this.highlighted;
    final hasHighlight = highlighted != null && highlighted < values.length;
    if (hasHighlight) {
      canvas.drawCircle(
        point(highlighted),
        10,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      marker(highlighted, radius: 6);
    }

    final selected = this.selected;
    if (selected == null || selected >= values.length) {
      // Sem o dedo, o balão fica com a partida em destaque.
      if (hasHighlight) bubbleAt(highlighted);
      return;
    }
    // A partida debaixo do dedo: a linha de guia, a marca e o rating dela.
    final at = point(selected);
    canvas.drawLine(
      Offset(at.dx, plot.top),
      Offset(at.dx, plot.bottom),
      Paint()
        ..color = line.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    marker(selected, radius: 6);
    bubbleAt(selected);
  }

  // O intervalo entre as linhas da grade: redondo, com poucas linhas.
  static double _step(double span) {
    for (final step in const [10.0, 20.0, 50.0, 100.0, 200.0, 500.0]) {
      if (span / step <= 4) return step;
    }
    return 1000;
  }

  static TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  bool shouldRepaint(_Plot old) =>
      old.values != values ||
      old.selected != selected ||
      old.highlighted != highlighted ||
      old.line != line ||
      old.surface != surface ||
      old.grid != grid;
}
