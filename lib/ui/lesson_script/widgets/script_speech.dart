import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
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
      fontSize: compact ? minFontSize : 16,
      verticalPadding: compact ? 10 : 14,
      horizontalPadding: compact ? 14 : 16,
      top: compact ? 12 : 24,
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
    ScriptSpeech.plainOf(context, texts.join('\n')),
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

/// O balão do Viktor, embaixo da barra de cima. A área guarda duas linhas; o
/// balão cresce para cima primeiro, no espaço sob a barra, e só depois
/// empurra o resto, com `AnimatedSize`. Além de [lines] linhas, a letra
/// diminui; na tela baixa, corta em 2 linhas com reticências. O clique no
/// balão abre a fala inteira, sempre ([onOpen]; Gabriel, 14/10/2026; canvas
/// `T70-etapa1-estados`).
class ScriptSpeech extends StatelessWidget {
  const ScriptSpeech({
    required this.texts,
    required this.metrics,
    this.lines,
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

  /// O clique em "Ver linha principal" dentro da fala: o mesmo do botão.
  final VoidCallback? onMainLine;

  /// O clique em "Ver resposta" dentro da fala: o mesmo do botão.
  final VoidCallback? onShowAnswer;

  /// O clique no balão: abre a fala inteira.
  final VoidCallback? onOpen;

  /// As marcas na fala que viram o rótulo do botão, sublinhado e clicável
  /// (Gabriel, 14/10/2026): todo botão citado na fala é link.
  static const mainLineMark = '{linhaPrincipal}';
  static const showAnswerMark = '{verResposta}';

  /// Uma marca e o ponto logo depois dela (o link não leva ponto colado).
  static final markPattern = RegExp(r'\{(linhaPrincipal|verResposta)\}\.?');

  /// A fala sem as marcas, para medir e para a voz.
  static String plain(
    String text, {
    required String mainLine,
    required String showAnswer,
  }) => text.replaceAllMapped(
    markPattern,
    (m) => m.group(1) == 'verResposta' ? showAnswer : mainLine,
  );

  /// [plain] com os rótulos do idioma da tela.
  static String plainOf(BuildContext context, String text) =>
      markPattern.hasMatch(text)
      ? plain(
          text,
          mainLine: context.l10n.lessonMainLine,
          showAnswer: context.l10n.lessonShowAnswer,
        )
      : text;

  /// A máquina pensa: um balão pequeno só com os três pontinhos.
  final bool typing;

  /// O bico que aponta para o retrato do Viktor.
  static const tailSize = Size(16, 8);

  /// A altura do balão pequeno dos pontinhos (sem o bico).
  static const typingHeight = 44.0;

  /// A folga dos lados dos pontinhos: o balão não fica enxuto demais.
  static const typingPadding = 28.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onColor = colors.onSurface;
    final speech = _bubble(
      context,
      ConstrainedBox(
        key: LessonScriptKeys.speech,
        constraints: BoxConstraints(minHeight: metrics.minHeight(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.horizontalPadding,
            vertical: metrics.verticalPadding,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: LayoutBuilder(
              builder: (context, box) {
                final text = texts.join('\n');
                final style = metrics.fittedStyle(
                  context,
                  box.maxWidth,
                  plainOf(context, text),
                  lines: lines,
                );
                return SizedBox(
                  width: double.infinity,
                  child: ScriptSpeechText(
                    text: text,
                    style: style.copyWith(color: onColor),
                    maxLines: metrics.clips ? metrics.maxLines : null,
                    onMainLine: onMainLine,
                    onShowAnswer: onShowAnswer,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    return AnimatedSize(
      duration: AppMotion.of(context).state,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: metrics.top + metrics.minHeight(context) + tailSize.height,
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
                Visibility.maintain(
                  visible: !typing,
                  child: _open(context, speech),
                ),
                if (typing)
                  PositionedDirectional(
                    start: 0,
                    bottom: 0,
                    child: _bubble(
                      context,
                      SizedBox(
                        height: typingHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: typingPadding,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: TypingDots(
                              key: LessonScriptKeys.typing,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
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

  /// O balão inteiro abre a fala inteira; os links dentro dele ganham o
  /// clique (o reconhecedor do texto entra primeiro na disputa).
  Widget _open(BuildContext context, Widget child) {
    final onOpen = this.onOpen;
    if (onOpen == null) return child;
    return Semantics(
      button: true,
      onTapHint: context.l10n.lessonFullSpeech,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: child,
      ),
    );
  }

  /// Balão e bico numa forma só: a sombra contorna os dois. Sempre branco
  /// (protótipo); o certo e o errado vão na fala.
  Widget _bubble(BuildContext context, Widget child) => Semantics(
    container: true,
    liveRegion: true,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      elevation: 1,
      shape: _SpeechBorder(textDirection: Directionality.of(context)),
      child: Padding(
        padding: EdgeInsets.only(bottom: tailSize.height),
        child: child,
      ),
    ),
  );
}

/// O texto da fala; as marcas [ScriptSpeech.mainLineMark] e
/// [ScriptSpeech.showAnswerMark] viram o rótulo do botão, sublinhado na cor
/// primária, sem o ponto colado depois, e o clique faz o mesmo que o botão.
/// Com [maxLines], corta com reticências.
class ScriptSpeechText extends StatefulWidget {
  const ScriptSpeechText({
    required this.text,
    required this.style,
    this.maxLines,
    this.onMainLine,
    this.onShowAnswer,
    super.key,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final VoidCallback? onMainLine;
  final VoidCallback? onShowAnswer;

  @override
  State<ScriptSpeechText> createState() => _ScriptSpeechTextState();
}

class _ScriptSpeechTextState extends State<ScriptSpeechText> {
  late final _mainLine = TapGestureRecognizer()
    ..onTap = () => widget.onMainLine?.call();
  late final _showAnswer = TapGestureRecognizer()
    ..onTap = () => widget.onShowAnswer?.call();

  @override
  void dispose() {
    _mainLine.dispose();
    _showAnswer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overflow = widget.maxLines == null ? null : TextOverflow.ellipsis;
    final matches = ScriptSpeech.markPattern.allMatches(widget.text).toList();
    if (matches.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: overflow,
      );
    }
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final link = widget.style.copyWith(
      color: primary,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: primary,
    );
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in matches) {
      spans.add(TextSpan(text: widget.text.substring(at, m.start)));
      final answer = m.group(1) == 'verResposta';
      final onTap = answer ? widget.onShowAnswer : widget.onMainLine;
      spans.add(
        TextSpan(
          text: answer ? l10n.lessonShowAnswer : l10n.lessonMainLine,
          style: link,
          recognizer: onTap == null
              ? null
              : answer
              ? _showAnswer
              : _mainLine,
        ),
      );
      at = m.end;
    }
    spans.add(TextSpan(text: widget.text.substring(at)));
    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: widget.maxLines,
      overflow: overflow,
    );
  }
}

/// O contorno do balão: retângulo arredondado com o bico embaixo, centrado
/// no retrato do Viktor (40 dp com 12 de margem: centro a 20 dp do balão).
class _SpeechBorder extends ShapeBorder {
  const _SpeechBorder({required this.textDirection});

  final TextDirection textDirection;

  static const _tailStart = 20.0 - 8.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final tail = ScriptSpeech.tailSize;
    final body = Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom - tail.height,
    );
    final rtl = (textDirection ?? this.textDirection) == TextDirection.rtl;
    final left = rtl
        ? body.right - _tailStart - tail.width
        : body.left + _tailStart;
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(AppShape.large)),
      )
      ..addPolygon([
        Offset(left, body.bottom - 1),
        Offset(left + tail.width, body.bottom - 1),
        Offset(left + tail.width / 2, rect.bottom),
      ], true);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  bool operator ==(Object other) =>
      other is _SpeechBorder && other.textDirection == textDirection;

  @override
  int get hashCode => textDirection.hashCode;
}
