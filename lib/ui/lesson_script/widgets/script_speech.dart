import 'package:flutter/material.dart';

import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/animated_speech_switcher.dart';
import '../../core/widgets/speech_balloon.dart';
import '../../core/widgets/typing_dots.dart';

/// As medidas do balão do Viktor (canvas `T70-balao`, variante A, Gabriel
/// 14/10/2026): 15 sp, folga 14×16 e 24 dp abaixo da barra em 412×915; na
/// tela baixa (360×640), 12 sp, folga 10×14, 12 dp e no máximo 2 linhas com
/// reticências (o tabuleiro fica o maior possível; a fala inteira abre no
/// clique).
class ScriptSpeechMetrics {
  const ScriptSpeechMetrics._({
    required this.compact,
    required this.fontSize,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.top,
    required this.maxLines,
  });

  factory ScriptSpeechMetrics.of(BuildContext context) {
    // Tela baixa: 360×640 (o protótipo `m*.png`); 412×915 é a normal.
    final compact = MediaQuery.sizeOf(context).height < 700;
    return ScriptSpeechMetrics._(
      compact: compact,
      // Canvas `PropV2ExA4P360`: em 360 a letra segue 16; a tela baixa
      // reduz só os espaçamentos.
      fontSize: 16,
      verticalPadding: compact ? 10 : 14,
      horizontalPadding: compact ? 14 : 16,
      // Canvas `PropV2ExA4`: 20 dp entre a barra de cima e o balão de 2 linhas
      // (min-height 105,5 = 20 + 76 + ponta).
      top: compact ? 12 : 20,
      maxLines: compact ? minLines : 4,
    );
  }

  static const minLines = 2;
  static const margin = 12.0;
  static const lineHeight = 1.5;

  /// A menor letra da fala: além de [maxLines] linhas, ela diminui até
  /// caber, e o balão não toma a lista (Gabriel, 14/10/2026).
  static const minFontSize = 12.0;

  /// A folga mínima entre a barra de cima e o balão que cresceu.
  static const minTop = 2.0;

  final bool compact;
  final double fontSize;
  final double verticalPadding;
  final double horizontalPadding;

  /// O espaço entre a barra de cima e o balão.
  final double top;

  /// Até quantas linhas a fala vai na letra de sempre (4 em 412×915); a
  /// tela pode dar mais quando cabem acima do tabuleiro centralizado. Na tela
  /// baixa é o corte: 2 linhas e reticências.
  final int maxLines;

  /// A tela baixa corta a fala em [maxLines] linhas, com reticências.
  bool get clips => compact;

  TextStyle style(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!
          .copyWith(fontSize: fontSize, height: lineHeight);

  /// A altura mínima do balão: duas linhas.
  double minHeight(BuildContext context) =>
      _lineHeight(context) * minLines + 2 * verticalPadding;

  /// A altura de uma linha de fala.
  double lineExtent(BuildContext context) => _lineHeight(context);

  double _lineHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(fontSize) * lineHeight;
  }

  /// O texto cabe no balão (até [maxLines] linhas) na largura [width] da tela?
  bool fits(BuildContext context, double width, List<String> texts) => _fits(
    context,
    width - 2 * margin - 2 * horizontalPadding,
    SpeechText.plainOf(context, texts.join('\n')),
    style(context),
    maxLines,
  );

  /// A letra da fala na largura [textWidth]: a de sempre se o texto cabe em
  /// [lines] linhas (padrão [maxLines]); senão, diminui de meio em meio ponto
  /// até caber (no mínimo [minFontSize]).
  TextStyle fittedStyle(
    BuildContext context,
    double textWidth,
    String text, {
    int? lines,
  }) {
    var fitted = style(context);
    final limit = lines ?? maxLines;
    while (fitted.fontSize! > minFontSize &&
        !_fits(context, textWidth, text, fitted, limit)) {
      fitted = fitted.copyWith(fontSize: fitted.fontSize! - 0.5);
    }
    return fitted;
  }

  bool _fits(
    BuildContext context,
    double textWidth,
    String text,
    TextStyle style,
    int lines,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: lines,
    )..layout(maxWidth: textWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }
}

/// O balão do Viktor, embaixo da barra de cima, no [SpeechBalloon] do app. A
/// área guarda duas linhas; o balão cresce para cima primeiro, no espaço sob a
/// barra, e só depois empurra o resto, com `AnimatedSize`. Além de [lines]
/// linhas, a letra diminui; na tela baixa, corta em 2 linhas com reticências.
/// O clique no balão abre a fala inteira, sempre ([onOpen]; Gabriel,
/// 14/10/2026; canvas `T70-etapa1-estados`).
class ScriptSpeech extends StatelessWidget {
  const ScriptSpeech({
    required this.texts,
    required this.metrics,
    this.lines,
    this.clipLines,
    this.footnote,
    this.typing = false,
    this.onMainLine,
    this.onShowAnswer,
    this.onOpen,
    super.key,
  });

  final List<String> texts;
  final ScriptSpeechMetrics metrics;

  /// Até quantas linhas a fala vai antes de a letra diminuir; nulo,
  /// [ScriptSpeechMetrics.maxLines]. A tela dá mais quando cabem acima do
  /// tabuleiro centralizado.
  final int? lines;

  /// Corta a fala nesse número de linhas, com reticências, mesmo fora da tela
  /// baixa (o exercício resolvido, canvas `PropV2ExA4`); o clique abre a fala
  /// inteira. Nulo, só a tela baixa corta.
  final int? clipLines;

  /// Uma linha à parte embaixo da fala cortada, que o corte não esconde (a
  /// dica do borrar do exercício, canvas `PropV2ExA10`).
  final String? footnote;

  /// O clique em "Ver linha principal" dentro da fala: o mesmo do botão.
  final VoidCallback? onMainLine;

  /// O clique em "Ver resposta" dentro da fala: o mesmo do botão.
  final VoidCallback? onShowAnswer;

  /// O clique no balão: abre a fala inteira.
  final VoidCallback? onOpen;

  /// A máquina pensa: um balão pequeno só com os três pontinhos.
  final bool typing;

  /// O retrato do Viktor na faixa de cima (40 dp): a ponta cai no centro dele.
  static const portrait = 40.0;

  /// A altura do balão pequeno dos pontinhos (sem a ponta).
  static const typingHeight = 44.0;

  /// A folga dos lados dos pontinhos: o balão não fica enxuto demais.
  static const typingPadding = 28.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onColor = colors.onSurface;
    final text = texts.join('\n');
    final speech = SpeechBalloon(
      key: LessonScriptKeys.speech,
      // Fala nova: o texto troca em crossfade e a altura anima.
      speech: footnote == null ? text : '$text\n$footnote',
      tailX: SpeechBalloon.tailXFor(portrait),
      minHeight: metrics.minHeight(context),
      pop: false,
      onTap: onOpen,
      tapHint: onOpen == null ? null : context.l10n.lessonFullSpeech,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: metrics.verticalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          // Cortada em [clipLines] linhas, a fala mantém a letra e termina em
          // reticências; sem corte, a letra diminui até caber.
          final style = clipLines != null || metrics.compact
              ? metrics.style(context)
              : metrics.fittedStyle(
                  context,
                  box.maxWidth,
                  SpeechText.plainOf(context, text),
                  lines: lines,
                );
          final speech = SpeechText(
            text: text,
            style: style.copyWith(color: onColor),
            maxLines: clipLines ?? (metrics.clips ? metrics.maxLines : null),
            onMainLine: onMainLine,
            onShowAnswer: onShowAnswer,
          );
          return SizedBox(
            width: double.infinity,
            child: footnote == null
                ? speech
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      speech,
                      SpeechText(
                        text: footnote!,
                        style: style.copyWith(color: onColor),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
    // A altura acompanha o texto, já animado dentro do balão.
    return SpeechPop(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              metrics.top +
              metrics.minHeight(context) +
              SpeechBalloon.tailExtent,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              ScriptSpeechMetrics.margin,
              ScriptSpeechMetrics.minTop,
              ScriptSpeechMetrics.margin,
              0,
            ),
            // Pensando, o balão encolhe para os pontinhos, colado no retrato; a
            // fala de antes, invisível, guarda a altura e o tabuleiro não pula
            // (Gabriel, 14/10/2026; canvas `T70-etapa1-estados`, E4b).
            child: Stack(
              children: [
                Visibility.maintain(visible: !typing, child: speech),
                if (typing)
                  PositionedDirectional(
                    start: 0,
                    bottom: 0,
                    child: SpeechBalloon(
                      tailX: SpeechBalloon.tailXFor(portrait),
                      fitContent: true,
                      pop: false,
                      minHeight: typingHeight,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: typingPadding,
                      ),
                      child: TypingDots(
                        key: LessonScriptKeys.typing,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
