import 'package:flutter/material.dart';

import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/animated_speech_switcher.dart';
import '../../core/widgets/speech_balloon.dart';
import '../../core/widgets/typing_dots.dart';
import 'script_page.dart';

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
    required this.maxLines,
  });

  factory ScriptSpeechMetrics.of(BuildContext context) {
    // Tela baixa: 360×640 (o protótipo `m*.png`); 412×915 é a normal.
    final compact = MediaQuery.sizeOf(context).height < 700;
    return ScriptSpeechMetrics._(
      compact: compact,
      // Canvas `PropV2ExA4P360`: em 360 a letra segue 15; a tela baixa
      // reduz só os espaçamentos.
      fontSize: 15,
      // Folga de cima e de baixo menor que a dos lados (12 < 16): ganha
      // altura para o tabuleiro (Gabriel, 14/10/2026).
      verticalPadding: compact ? 8 : 12,
      horizontalPadding: compact ? 14 : 16,
      maxLines: compact ? minLines : areaLines,
    );
  }

  static const minLines = 2;

  /// A área da fala tem 3 linhas fixas (Gabriel, 14/10/2026): o balão cresce
  /// e diminui dentro dela, presa embaixo, e o tabuleiro não sobe nem desce.
  static const areaLines = 3;
  static const margin = 12.0;
  static const lineHeight = 1.5;

  /// A menor letra da fala: além de [maxLines] linhas, ela diminui até
  /// caber, e o balão não toma a lista (Gabriel, 14/10/2026).
  static const minFontSize = 13.0;

  /// A folga mínima entre a barra de cima e o balão cheio.
  static const minTop = 2.0;

  /// O vão visível entre a ponta do balão e o retrato do Viktor (Gabriel,
  /// 14/10/2026): antes eram 11 (vão da ponta 6 + 5 de folga da faixa).
  static const portraitGap = 2.0;

  final bool compact;
  final double fontSize;
  final double verticalPadding;
  final double horizontalPadding;

  /// Até quantas linhas a fala vai na letra de sempre (3; 2 na tela baixa);
  /// além disso a letra diminui até [minFontSize] e, se ainda não cabe, a
  /// fala rola dentro do balão.
  final int maxLines;

  TextStyle style(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!
          .copyWith(fontSize: fontSize, height: lineHeight);

  /// A altura fixa da área da fala: [maxLines] linhas, a folga do balão e a
  /// ponta. Não muda de um passo para outro; o balão fica preso embaixo.
  double areaHeight(BuildContext context) =>
      minTop +
      _lineHeight(context) * maxLines +
      2 * verticalPadding +
      SpeechBalloon.tailHeight;

  /// A altura da fala em [maxLines] linhas.
  double textMaxHeight(BuildContext context) => _lineHeight(context) * maxLines;

  /// A altura mínima do balão: uma linha (fala curta, balão curto).
  double minHeight(BuildContext context) =>
      _lineHeight(context) + 2 * verticalPadding;

  /// A altura de uma linha de fala.
  double lineExtent(BuildContext context) => _lineHeight(context);

  double _lineHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(fontSize) * lineHeight;
  }

  /// O texto cabe no balão (até [maxLines] linhas) na largura [width] da tela?
  bool fits(BuildContext context, double width, List<String> texts) => textFits(
    context,
    width - 2 * margin - 2 * horizontalPadding,
    SpeechText.noBreak(SpeechText.plainOf(context, texts.join('\n'))),
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
        !textFits(context, textWidth, text, fitted, limit)) {
      fitted = fitted.copyWith(fontSize: fitted.fontSize! - 0.5);
    }
    return fitted;
  }

  bool textFits(
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

/// O balão do Viktor, acima da faixa dele, no [SpeechBalloon] do app. A área
/// da fala tem altura FIXA (3 linhas, [ScriptSpeechMetrics.areaHeight]): o
/// balão desenhado pode ser menor, preso embaixo junto do retrato, e a sobra
/// fica vazia em cima; o tabuleiro não se mexe de um passo para o outro. Fala
/// além das 3 linhas: a letra diminui até 13 e, se ainda não cabe, rola dentro
/// do balão. O clique no balão abre a fala inteira ([onOpen]; Gabriel,
/// 14/10/2026; canvas `T70-etapa1-estados`).
class ScriptSpeech extends StatelessWidget {
  const ScriptSpeech({
    required this.texts,
    required this.metrics,
    this.footnote,
    this.typing = false,
    this.onMainLine,
    this.onShowAnswer,
    this.onSquareTap,
    this.onOpen,
    super.key,
  });

  final List<String> texts;
  final ScriptSpeechMetrics metrics;

  /// Uma linha à parte embaixo da fala (a dica do borrar do exercício, canvas
  /// `PropV2ExA10`); conta nas 3 linhas.
  final String? footnote;

  /// O clique em "Ver linha principal" dentro da fala: o mesmo do botão.
  final VoidCallback? onMainLine;

  /// O clique em "Ver resposta" dentro da fala: o mesmo do botão.
  final VoidCallback? onShowAnswer;

  /// O toque numa casa citada na fala: a tela a realça no tabuleiro.
  final ValueChanged<String>? onSquareTap;

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
    final whole = footnote == null ? text : '$text\n$footnote';
    // A faixa deixa 5 dp acima do retrato; a ponta (sem o vão padrão de 6)
    // desce sobre eles até sobrar [ScriptSpeechMetrics.portraitGap].
    const overlap =
        (ScriptPage.stripHeight - portrait) / 2 -
        ScriptSpeechMetrics.portraitGap;
    final speech = SpeechBalloon(
      key: LessonScriptKeys.speech,
      // Fala nova: o texto troca em crossfade e a altura anima.
      speech: whole,
      tailX: SpeechBalloon.tailXFor(portrait),
      tailSpace: 0,
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
          final plain = SpeechText.noBreak(SpeechText.plainOf(context, whole));
          final style = metrics.fittedStyle(context, box.maxWidth, plain);
          final fits = metrics.textFits(
            context,
            box.maxWidth,
            plain,
            style,
            metrics.maxLines,
          );
          final speech = SpeechText(
            text: text,
            style: style.copyWith(color: onColor),
            onMainLine: onMainLine,
            onShowAnswer: onShowAnswer,
            onSquareTap: onSquareTap,
          );
          Widget body = footnote == null
              ? speech
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    speech,
                    SpeechText(
                      text: footnote!,
                      style: style.copyWith(color: onColor),
                      onSquareTap: onSquareTap,
                    ),
                  ],
                );
          // Nem em 13 cabe em 3 linhas: a fala rola dentro do balão, sem
          // reticências que a cortem.
          if (!fits) {
            body = SizedBox(
              height: metrics.textMaxHeight(context),
              child: SingleChildScrollView(child: body),
            );
          }
          return SizedBox(width: double.infinity, child: body);
        },
      ),
    );
    return SpeechPop(
      child: SizedBox(
        height: metrics.areaHeight(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: ScriptSpeechMetrics.margin,
          ),
          // Preso embaixo, colado no retrato; a sobra fica em cima. Pensando,
          // o balão encolhe para os pontinhos e a fala de antes, invisível,
          // guarda o lugar (Gabriel, 14/10/2026; canvas `T70-etapa1-estados`).
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: -overlap,
                child: Visibility.maintain(visible: !typing, child: speech),
              ),
              if (typing)
                PositionedDirectional(
                  start: 0,
                  bottom: -overlap,
                  child: SpeechBalloon(
                    tailX: SpeechBalloon.tailXFor(portrait),
                    tailSpace: 0,
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
    );
  }
}
