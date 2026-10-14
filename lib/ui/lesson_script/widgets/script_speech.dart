import 'package:flutter/material.dart';

import '../../core/keys/lesson_script_keys.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// As medidas do balão do Viktor (protótipo T70, §8 do contrato): 15 sp e
/// padding 10×12 em 412×915; 14 sp e 8×12 em 360×640 (tela baixa).
class ScriptSpeechMetrics {
  const ScriptSpeechMetrics._({
    required this.compact,
    required this.fontSize,
    required this.verticalPadding,
    required this.maxLines,
  });

  factory ScriptSpeechMetrics.of(BuildContext context) {
    // Tela baixa: 360×640 (o protótipo `m*.png`); 412×915 é a normal.
    final compact = MediaQuery.sizeOf(context).height < 700;
    return ScriptSpeechMetrics._(
      compact: compact,
      fontSize: compact ? 14 : 15,
      verticalPadding: compact ? 8 : 10,
      maxLines: compact ? 3 : 4,
    );
  }

  static const minLines = 2;
  static const horizontalPadding = 12.0;
  static const margin = 12.0;
  static const lineHeight = 1.25;

  final bool compact;
  final double fontSize;
  final double verticalPadding;

  /// Até quantas linhas a área cresce (4 em 412×915, 3 em 360×640).
  final int maxLines;

  TextStyle style(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyLarge!
      .copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: lineHeight,
      );

  /// A altura mínima do balão: duas linhas.
  double minHeight(BuildContext context) =>
      _lineHeight(context) * minLines + 2 * verticalPadding;

  double _lineHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(fontSize) * lineHeight;
  }

  /// O texto cabe no balão (até [maxLines] linhas) na largura [width] da tela?
  bool fits(BuildContext context, double width, List<String> texts) {
    final painter = TextPainter(
      text: TextSpan(text: texts.join('\n'), style: style(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: width - 2 * margin - 2 * horizontalPadding);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }
}

/// O balão do Viktor, colado na barra de cima. Cresce com o texto (mínimo de
/// duas linhas) e empurra o resto da tela só além disso, com `AnimatedSize`.
class ScriptSpeech extends StatelessWidget {
  const ScriptSpeech({required this.texts, required this.metrics, super.key});

  final List<String> texts;
  final ScriptSpeechMetrics metrics;

  /// O bico que aponta para o retrato do Viktor.
  static const tailSize = Size(16, 8);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // O balão é sempre branco (protótipo); o certo e o errado vão na fala.
    final color = colors.surfaceContainerLowest;
    final onColor = colors.onSurface;
    return AnimatedSize(
      duration: AppMotion.of(context).state,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          ScriptSpeechMetrics.margin,
          8,
          ScriptSpeechMetrics.margin,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              liveRegion: true,
              child: Material(
                key: LessonScriptKeys.speech,
                color: color,
                elevation: 1,
                borderRadius: BorderRadius.circular(AppShape.large),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: metrics.minHeight(context),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ScriptSpeechMetrics.horizontalPadding,
                      vertical: metrics.verticalPadding,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          texts.join('\n'),
                          style: metrics
                              .style(context)
                              .copyWith(color: onColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 20),
              child: CustomPaint(size: tailSize, painter: _TailPainter(color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
