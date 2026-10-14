import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_shape.dart';
import 'animated_speech_switcher.dart';

/// Onde fica a ponta do balão (canvas `CompBalao`, parâmetro `ponta`): em
/// cima (o balão abaixo de quem fala), embaixo (o balão acima), no começo
/// (ao lado) ou nenhuma.
enum BalloonTail { up, down, start, none }

/// O contorno do balão: retângulo arredondado e a ponta num caminho só, então
/// a sombra contorna os dois. A ponta de cima e de baixo é o triângulo 18×10
/// do canvas; a lateral é a curva 10×16 dele. O [Rect] recebido inclui o
/// espaço da ponta.
class SpeechBalloonShape extends ShapeBorder {
  const SpeechBalloonShape({
    required this.tail,
    required this.tailX,
    required this.textDirection,
    this.tailY,
  });

  final BalloonTail tail;

  /// Da borda do começo do balão até o começo da base da ponta (canvas
  /// `pontaX`: 13 faz a ponta cair no centro de um retrato de 44).
  final double tailX;

  /// Só da ponta lateral: o centro dela, contado do alto do corpo. Nulo, perto
  /// da base (canvas `pontaY`).
  final double? tailY;

  final TextDirection textDirection;

  /// O triângulo de cima e de baixo (canvas: viewBox 18×10).
  static const tipSize = Size(18, 10);

  /// A ponta lateral (canvas: viewBox 10×16).
  static const sideSize = Size(10, 16);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  /// O corpo (sem a ponta) dentro de [rect].
  Rect bodyOf(Rect rect, TextDirection direction) {
    final rtl = direction == TextDirection.rtl;
    return switch (tail) {
      BalloonTail.up => Rect.fromLTRB(
        rect.left,
        rect.top + tipSize.height,
        rect.right,
        rect.bottom,
      ),
      BalloonTail.down => Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right,
        rect.bottom - tipSize.height,
      ),
      BalloonTail.start => Rect.fromLTRB(
        rtl ? rect.left : rect.left + sideSize.width,
        rect.top,
        rtl ? rect.right - sideSize.width : rect.right,
        rect.bottom,
      ),
      BalloonTail.none => rect,
    };
  }

  /// A pontinha: onde a ponta toca quem fala.
  Offset tipOf(Rect rect, {TextDirection? textDirection}) {
    final direction = textDirection ?? this.textDirection;
    final body = bodyOf(rect, direction);
    switch (tail) {
      case BalloonTail.up:
        return Offset(
          _triangleLeft(body, direction) + tipSize.width / 2,
          rect.top,
        );
      case BalloonTail.down:
        return Offset(
          _triangleLeft(body, direction) + tipSize.width / 2,
          rect.bottom,
        );
      case BalloonTail.start:
        return Offset(
          direction == TextDirection.rtl ? rect.right : rect.left,
          body.top + _sideCenter(body) - 2,
        );
      case BalloonTail.none:
        return rect.center;
    }
  }

  double _triangleLeft(Rect body, TextDirection direction) {
    final rtl = direction == TextDirection.rtl;
    final raw = rtl ? body.right - tailX - tipSize.width : body.left + tailX;
    // Canvas: a base nasce em pontaX (13), já na curva do canto; só não sai
    // do corpo.
    final low = body.left + 8;
    final high = body.right - AppShape.large - tipSize.width;
    return high < low ? raw : raw.clamp(low, high);
  }

  double _sideCenter(Rect body) {
    final raw = tailY ?? math.max(body.height / 2, body.height - 24);
    final low = AppShape.large + sideSize.height / 2;
    final high = body.height - AppShape.large - sideSize.height / 2;
    return high < low ? body.height / 2 : raw.clamp(low, high);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final direction = textDirection ?? this.textDirection;
    final body = bodyOf(rect, direction);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(AppShape.large)),
      );
    switch (tail) {
      case BalloonTail.up:
        final left = _triangleLeft(body, direction);
        path.addPolygon([
          Offset(left, body.top + 1),
          Offset(left + tipSize.width, body.top + 1),
          Offset(left + tipSize.width / 2, rect.top),
        ], true);
      case BalloonTail.down:
        final left = _triangleLeft(body, direction);
        path.addPolygon([
          Offset(left, body.bottom - 1),
          Offset(left + tipSize.width, body.bottom - 1),
          Offset(left + tipSize.width / 2, rect.bottom),
        ], true);
      case BalloonTail.start:
        final rtl = direction == TextDirection.rtl;
        final cy = body.top + _sideCenter(body);
        // Medidas do canvas, a partir da base: (10,+8) → curva → (0,-2) →
        // curva → (10,-8); espelhadas em idiomas da direita para a esquerda.
        double x(double dx) => rtl ? rect.right - dx : rect.left + dx;
        path
          ..moveTo(x(sideSize.width + 0.6), cy + 8)
          ..lineTo(x(sideSize.width), cy + 8)
          ..quadraticBezierTo(x(8), cy + 2, x(0), cy - 2)
          ..quadraticBezierTo(x(6), cy - 6, x(sideSize.width), cy - 8)
          ..lineTo(x(sideSize.width + 0.6), cy - 8)
          ..close();
      case BalloonTail.none:
        break;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  bool operator ==(Object other) =>
      other is SpeechBalloonShape &&
      other.tail == tail &&
      other.tailX == tailX &&
      other.tailY == tailY &&
      other.textDirection == textDirection;

  @override
  int get hashCode => Object.hash(tail, tailX, tailY, textDirection);
}

/// O balão de fala do app, um só (canvas `CompBalao`, T72): o estilo da lição
/// (fundo branco, sombra, raio 16, letra 16/24) vale em toda tela. Quem usa só
/// escolhe a posição da ponta, o corte e se encolhe até o texto; nenhuma tela
/// passa cor, letra ou raio.
///
/// Fala nova (`speech` diferente): o texto troca em crossfade e a altura anima
/// ([AnimatedSpeechSwitcher]); a primeira aparição leva um pop ([SpeechPop]).
/// O clique ([onTap]) abre a folha com a fala inteira; não há botão de fechar.
class SpeechBalloon extends StatelessWidget {
  const SpeechBalloon({
    required this.child,
    this.speech,
    this.tail = BalloonTail.down,
    this.tailX = defaultTailX,
    this.tailY,
    this.fitContent = false,
    this.minHeight = 0,
    this.padding = defaultPadding,
    this.pop = true,
    this.onTap,
    this.tapHint,
    this.semanticsLabel,
    super.key,
  });

  /// O texto (ou os pontinhos) do balão.
  final Widget child;

  /// O que identifica a fala: quando muda, o texto troca em crossfade. Nulo,
  /// o balão não anima a troca.
  final Object? speech;

  final BalloonTail tail;

  /// Da borda do começo até o começo da ponta de cima/baixo (canvas `pontaX`).
  final double tailX;

  /// O centro da ponta lateral (canvas `pontaY`).
  final double? tailY;

  /// Largura: encolhe até o texto (padrão do canvas é a largura toda).
  final bool fitContent;

  /// A altura mínima do corpo, sem a ponta.
  final double minHeight;

  /// A folga do texto (canvas `--balao-pad`: 14 de cima e 16 dos lados), sem
  /// a ponta.
  final EdgeInsetsDirectional padding;

  /// Pop na primeira aparição; desligado quando quem usa já anima o conjunto.
  final bool pop;

  /// O clique no balão: abre a fala inteira.
  final VoidCallback? onTap;
  final String? tapHint;

  /// O que o leitor de tela diz no lugar do conteúdo.
  final String? semanticsLabel;

  /// Canvas `pontaX`: 13 para um retrato de 44 (a ponta cai no centro dele).
  static const defaultTailX = 13.0;

  /// A altura da ponta de cima e de baixo.
  static double get tailHeight => SpeechBalloonShape.tipSize.height;

  static const defaultPadding = EdgeInsetsDirectional.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  /// `pontaX` para a ponta cair no centro de um retrato de [avatar] dp.
  static double tailXFor(double avatar) =>
      avatar / 2 - SpeechBalloonShape.tipSize.width / 2;

  /// A letra do balão (canvas `--balao-letra` 16 e `--balao-linha` 24).
  static TextStyle style(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyLarge!
      .copyWith(
        fontSize: 16,
        height: 24 / 16,
        color: Theme.of(context).colorScheme.onSurface,
      );

  EdgeInsetsDirectional get _tailInset => switch (tail) {
    BalloonTail.up => EdgeInsetsDirectional.only(top: tailHeight),
    BalloonTail.down => EdgeInsetsDirectional.only(bottom: tailHeight),
    BalloonTail.start => EdgeInsetsDirectional.only(
      start: SpeechBalloonShape.sideSize.width,
    ),
    BalloonTail.none => EdgeInsetsDirectional.zero,
  };

  @override
  Widget build(BuildContext context) {
    final speech = this.speech;
    Widget content = Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: fitContent ? 1 : null,
      heightFactor: 1,
      child: speech == null
          ? child
          : AnimatedSpeechSwitcher(speech: speech, child: child),
    );
    Widget balloon = Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        elevation: 1,
        shape: SpeechBalloonShape(
          tail: tail,
          tailX: tailX,
          tailY: tailY,
          textDirection: Directionality.of(context),
        ),
        // A altura mínima conta só o corpo: a ponta fica por fora dela.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                minHeight +
                (tail == BalloonTail.up || tail == BalloonTail.down
                    ? tailHeight
                    : 0),
          ),
          child: Padding(padding: padding.add(_tailInset), child: content),
        ),
      ),
    );
    final onTap = this.onTap;
    if (onTap != null) {
      // Os links dentro do texto ganham o clique (o reconhecedor deles entra
      // primeiro na disputa).
      balloon = Semantics(
        button: true,
        onTapHint: tapHint,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: balloon,
        ),
      );
    }
    if (!pop) return balloon;
    return SpeechPop(
      alignment: switch (tail) {
        BalloonTail.up => AlignmentDirectional.topStart,
        BalloonTail.start => AlignmentDirectional.centerStart,
        BalloonTail.down => AlignmentDirectional.bottomStart,
        BalloonTail.none => AlignmentDirectional.center,
      },
      child: balloon,
    );
  }
}

/// O texto da fala; as marcas [mainLineMark] e [showAnswerMark] viram o
/// rótulo do botão, sublinhado na cor primária, sem o ponto colado depois, e o
/// clique faz o mesmo que o botão. Com [maxLines], corta com reticências.
class SpeechText extends StatefulWidget {
  const SpeechText({
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

  @override
  State<SpeechText> createState() => _SpeechTextState();
}

class _SpeechTextState extends State<SpeechText> {
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
    final matches = SpeechText.markPattern.allMatches(widget.text).toList();
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
