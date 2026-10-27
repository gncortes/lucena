import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../keys/speech_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'animated_speech_switcher.dart';
import 'speech_sheet_fade.dart';

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
        return Offset(_apexX(body, direction), rect.top);
      case BalloonTail.down:
        return Offset(_apexX(body, direction), rect.bottom);
      case BalloonTail.start:
        return Offset(
          direction == TextDirection.rtl ? rect.right : rect.left,
          body.top + _sideCenter(body) - 2,
        );
      case BalloonTail.none:
        return rect.center;
    }
  }

  double _rawLeft(Rect body, TextDirection direction) =>
      direction == TextDirection.rtl
      ? body.right - tailX - tipSize.width
      : body.left + tailX;

  /// O começo da base: inteira no trecho reto da borda, depois do raio do
  /// canto, para a emenda com o corpo não sair torta.
  double _triangleLeft(Rect body, TextDirection direction) {
    final raw = _rawLeft(body, direction);
    final low = body.left + AppShape.large;
    final high = body.right - AppShape.large - tipSize.width;
    return high < low ? raw : raw.clamp(low, high);
  }

  /// A pontinha mira onde [tailX] pede (o centro do retrato), mesmo quando a
  /// base precisou sair de dentro do raio; nunca passa da base.
  double _apexX(Rect body, TextDirection direction) {
    final left = _triangleLeft(body, direction);
    final aim = _rawLeft(body, direction) + tipSize.width / 2;
    return aim.clamp(left, left + tipSize.width);
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

  /// Corpo e ponta num contorno só (união), sem emenda: a sombra e o fundo
  /// passam pela ponta como pelo corpo.
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final direction = textDirection ?? this.textDirection;
    final body = bodyOf(rect, direction);
    final bodyPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(AppShape.large)),
      );
    final path = Path();
    switch (tail) {
      case BalloonTail.up:
        final left = _triangleLeft(body, direction);
        path.addPolygon([
          Offset(left, body.top + 2),
          Offset(left + tipSize.width, body.top + 2),
          Offset(_apexX(body, direction), rect.top),
        ], true);
      case BalloonTail.down:
        final left = _triangleLeft(body, direction);
        path.addPolygon([
          Offset(left, body.bottom - 2),
          Offset(left + tipSize.width, body.bottom - 2),
          Offset(_apexX(body, direction), rect.bottom),
        ], true);
      case BalloonTail.start:
        final rtl = direction == TextDirection.rtl;
        final cy = body.top + _sideCenter(body);
        // Medidas do canvas, a partir da base: (10,+8) → curva → (0,-2) →
        // curva → (10,-8); espelhadas em idiomas da direita para a esquerda.
        double x(double dx) => rtl ? rect.right - dx : rect.left + dx;
        path
          ..moveTo(x(sideSize.width + 2), cy + 8)
          ..lineTo(x(sideSize.width), cy + 8)
          ..quadraticBezierTo(x(8), cy + 2, x(0), cy - 2)
          ..quadraticBezierTo(x(6), cy - 6, x(sideSize.width), cy - 8)
          ..lineTo(x(sideSize.width + 2), cy - 8)
          ..close();
      case BalloonTail.none:
        return bodyPath;
    }
    return Path.combine(PathOperation.union, bodyPath, path);
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

/// O balão pintado como uma forma só: primeiro a sombra do canvas
/// (`--balao-sombra`: drop-shadow 0 1px 1.5px, preto a 25%, a cor `shadow` do
/// tema), depois o fundo, os dois no mesmo contorno de corpo e ponta. Assim a
/// ponta tem a mesma sombra do corpo, para cima, para baixo ou ao lado, e não
/// há emenda nem elevação do Material.
class BalloonPainter extends CustomPainter {
  const BalloonPainter(this.shape, {required this.color, required this.shadow});

  final SpeechBalloonShape shape;

  /// O fundo (`surfaceContainerLowest`).
  final Color color;

  /// A cor da sombra, já com a [opacity].
  final Color shadow;

  /// A opacidade da sombra do canvas (25%).
  static const opacity = 0.25;
  static const offset = Offset(0, 1);

  /// O blur de 1,5 px do CSS é o dobro do sigma.
  static const sigma = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getOuterPath(Offset.zero & size);
    canvas
      ..drawPath(
        path.shift(offset),
        Paint()
          ..color = shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, sigma),
      )
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BalloonPainter old) =>
      old.shape != shape || old.color != color || old.shadow != shadow;
}

/// Como uma fala cabe no balão (canvas `CompBalao`, T84, Gabriel 27/10/2026):
/// um espaço fixo de [fixedLines] linhas, com a letra de 15 descendo até
/// [minFontSize]; se nem assim cabe, o balão se abre até [openLines] linhas
/// (de novo de 15 a 13); além disso, corta numa palavra inteira e termina em
/// "… Ver mais" ([cut]).
class SpeechFit {
  const SpeechFit._({
    required this.style,
    required this.lines,
    required this.open,
    required this.overflow,
  });

  /// As linhas do espaço fixo, que a tela reserva desde o começo.
  static const fixedLines = 2;

  /// Até quantas linhas o balão aberto (por cima do topo) mostra.
  static const openLines = 4;

  /// A menor letra: abaixo de 15, de meio em meio ponto até 13.
  static const minFontSize = 13.0;
  static const fontStep = 0.5;

  /// A letra que cabe.
  final TextStyle style;

  /// Em quantas linhas a fala fica (no máximo, as do balão aberto).
  final int lines;

  /// Passou do espaço fixo: o balão se abre por cima, com o X.
  final bool open;

  /// Nem aberto cabe: corta e mostra "… Ver mais".
  final bool overflow;

  /// Mede [text] na largura [width] com a letra [base], primeiro em
  /// [fixed] linhas e, se não couber, em [opened] (igual a [fixed]: o balão
  /// não se abre, só corta).
  static SpeechFit measure(
    BuildContext context, {
    required String text,
    required double width,
    required TextStyle base,
    int fixed = fixedLines,
    int opened = openLines,
  }) {
    for (final limit in {fixed, opened}) {
      var style = base;
      while (true) {
        final lines = _lines(context, text, width, style);
        if (lines <= limit) {
          return SpeechFit._(
            style: style,
            lines: lines,
            open: lines > fixed,
            overflow: false,
          );
        }
        if (style.fontSize! - fontStep < minFontSize - .01) break;
        style = style.copyWith(fontSize: style.fontSize! - fontStep);
      }
    }
    return SpeechFit._(
      style: base.copyWith(fontSize: math.min(base.fontSize!, minFontSize)),
      lines: opened,
      open: opened > fixed,
      overflow: true,
    );
  }

  static int _lines(
    BuildContext context,
    String text,
    double width,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines;
  }

  /// A pontuação solta que sai antes do "…".
  static final _trailing = RegExp(r'[\s,;:.–—-]+$');

  /// O maior começo de [text], numa palavra inteira, que cabe em [lines]
  /// linhas na largura [width] junto de [more] ("… Ver mais"). [spans]
  /// desenha o trecho (com as marcas da fala).
  static String cut(
    BuildContext context, {
    required String text,
    required double width,
    required int lines,
    required TextStyle style,
    required InlineSpan more,
    List<InlineSpan> Function(String text)? spans,
  }) {
    final ends = <int>[
      for (final m in RegExp(r'\s+').allMatches(text)) m.start,
    ];
    String piece(int end) => text.substring(0, end).replaceFirst(_trailing, '');
    bool fits(String piece) {
      final painter = TextPainter(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.merge(style),
          children: [
            ...(spans?.call(piece) ?? [TextSpan(text: piece)]),
            more,
          ],
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: lines,
      )..layout(maxWidth: width);
      final ok = !painter.didExceedMaxLines;
      painter.dispose();
      return ok;
    }

    // Busca binária pela última palavra que cabe.
    var low = 0;
    var high = ends.length - 1;
    var best = '';
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = piece(ends[mid]);
      if (fits(candidate)) {
        best = candidate;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return best;
  }

  /// O "… Ver mais": as reticências na cor do texto e o link na cor
  /// primária, em negrito, sem sublinhado (canvas `CompBalao`).
  static InlineSpan more(
    BuildContext context, {
    required TextStyle style,
    GestureRecognizer? recognizer,
  }) => TextSpan(
    children: [
      const TextSpan(text: '… '),
      TextSpan(
        text: context.l10n.speechSeeMore,
        recognizer: recognizer,
        style: style.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: AppWeight.strong,
        ),
      ),
    ],
  );
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
    this.tailSpace = tailGap,
    this.pop = true,
    this.onTap,
    this.tapHint,
    this.semanticsLabel,
    this.onClose,
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

  /// O vão entre a pontinha e o retrato; a lição roteirizada o zera e põe o
  /// vão que quer (canvas `T70-balao`).
  final double tailSpace;

  /// Pop na primeira aparição; desligado quando quem usa já anima o conjunto.
  final bool pop;

  /// O clique no balão: abre a fala inteira.
  final VoidCallback? onTap;
  final String? tapHint;

  /// O que o leitor de tela diz no lugar do conteúdo.
  final String? semanticsLabel;

  /// O balão aberto por cima do topo (T84): ganha o X de fechar, redondo,
  /// de superfície com sombra, com o centro na borda de cima, a
  /// [closeInset] da borda do fim e metade para fora. O balão guarda
  /// [closeLift] em cima e [closeOverhang] no fim para o alvo de toque
  /// inteiro ficar dentro dele.
  final VoidCallback? onClose;

  /// O diâmetro do X e o alvo de toque dele.
  static const closeSize = 32.0;
  static const closeTarget = 48.0;

  /// Do centro do X até a borda do fim do balão.
  static const closeInset = AppSpacing.sm;

  /// O que o alvo do X passa acima e depois do balão.
  static const closeLift = closeTarget / 2;
  static const closeOverhang = closeTarget / 2 - closeInset;

  /// Canvas `pontaX`: 13 para um retrato de 44 (a ponta cai no centro dele).
  static const defaultTailX = 13.0;

  /// A altura da ponta de cima e de baixo.
  static double get tailHeight => SpeechBalloonShape.tipSize.height;

  /// O vão entre a pontinha e o retrato, em toda ponta (canvas `CompBalao`
  /// 3f3938b: margem 16 = ponta 10 + vão 6). Fica por fora do balão.
  static const tailGap = 6.0;

  /// O que o balão ocupa além do corpo, com a ponta de cima ou de baixo: a
  /// ponta e o vão até o retrato.
  static double get tailExtent => tailHeight + tailGap;

  static const defaultPadding = EdgeInsetsDirectional.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.lg,
  );

  /// A altura do corpo do balão no espaço fixo da fala (T84): as
  /// [SpeechFit.fixedLines] linhas na letra de sempre e o recuo.
  static double fixedHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(style(context).fontSize!) *
          style(context).height! *
          SpeechFit.fixedLines +
      defaultPadding.vertical;

  /// `pontaX` para a ponta cair no centro de um retrato de [avatar] dp.
  static double tailXFor(double avatar) =>
      avatar / 2 - SpeechBalloonShape.tipSize.width / 2;

  /// A letra do balão (canvas `--balao-letra` 16 e `--balao-linha` 24).
  static TextStyle style(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyLarge!
      .copyWith(
        fontSize: 15,
        height: 1.5,
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

  EdgeInsetsDirectional get _gap => switch (tail) {
    BalloonTail.up => EdgeInsetsDirectional.only(top: tailSpace),
    BalloonTail.down => EdgeInsetsDirectional.only(bottom: tailSpace),
    BalloonTail.start => EdgeInsetsDirectional.only(start: tailSpace),
    BalloonTail.none => EdgeInsetsDirectional.zero,
  };

  @override
  Widget build(BuildContext context) {
    final speech = this.speech;
    final colors = Theme.of(context).colorScheme;
    final shape = SpeechBalloonShape(
      tail: tail,
      tailX: tailX,
      tailY: tailY,
      textDirection: Directionality.of(context),
    );
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
      child: CustomPaint(
        painter: BalloonPainter(
          shape,
          color: colors.surfaceContainerLowest,
          shadow: colors.shadow.withValues(alpha: BalloonPainter.opacity),
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
    final onClose = this.onClose;
    if (onClose != null) {
      final colors = Theme.of(context).colorScheme;
      balloon = Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: closeLift,
              end: closeOverhang,
            ),
            child: balloon,
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: SizedBox.square(
              dimension: closeTarget,
              child: Center(
                child: IconButton.filled(
                  key: SpeechKeys.close,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerLowest,
                    foregroundColor: colors.onSurface,
                    elevation: 2,
                    padding: EdgeInsets.zero,
                    fixedSize: const Size.square(closeSize),
                    minimumSize: const Size.square(closeSize),
                    maximumSize: const Size.square(closeSize),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  tooltip: context.l10n.speechClose,
                  iconSize: AppIconSize.button,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ),
            ),
          ),
        ],
      );
    }
    // O vão até o retrato fica fora do clique e da sombra.
    if (tail != BalloonTail.none) {
      balloon = Padding(padding: _gap, child: balloon);
    }
    // A folha da fala inteira aberta: o balão de cima some, mas o vão fica.
    balloon = SpeechSheetFade(child: balloon);
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

/// O texto da fala; as marcas `{linhaPrincipal}` e `{verResposta}` viram o
/// rótulo do botão, sublinhado na cor primária, sem o ponto colado depois, e o
/// clique faz o mesmo que o botão. Com [maxLines], corta com reticências; se o
/// trecho cortado tem link, o corte vai para o meio e a frase do link fica.
class SpeechText extends StatefulWidget {
  const SpeechText({
    required this.text,
    required this.style,
    this.maxLines,
    this.onMainLine,
    this.onShowAnswer,
    this.onSquareTap,
    this.onMore,
    super.key,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;

  /// Com [maxLines]: a fala que não cabe é cortada numa palavra inteira e
  /// termina em "… Ver mais" ([SpeechFit.cut]); o clique nele chama este
  /// callback (a folha com a fala inteira).
  final VoidCallback? onMore;
  final VoidCallback? onMainLine;
  final VoidCallback? onShowAnswer;

  /// Com tabuleiro na tela: toda casa citada na fala (`[f5]` ou solta, `f5`)
  /// vira um alvo de toque, em negrito na cor primária, e chama este callback
  /// com o nome dela. Nulo, a casa solta fica como texto comum.
  final ValueChanged<String>? onSquareTap;

  /// Uma marca (`{linhaPrincipal}`, `{verResposta}`) e o ponto logo depois
  /// dela: ela vira o rótulo do botão, sublinhado e clicável (o link não leva
  /// ponto colado).
  static final markPattern = RegExp(r'\{(linhaPrincipal|verResposta)\}\.?');

  /// Uma casa entre colchetes, como `[c6]`: na tela vira negrito azul; fora
  /// dela (voz, medida) fica só a casa.
  static final squarePattern = RegExp(r'\[([a-h][1-8])\]');

  /// Uma casa solta no texto, como palavra inteira: "Rg7" e "1.Rg7" não
  /// contam, porque a letra da peça vem colada antes.
  static final looseSquarePattern = RegExp(
    r'(?<![A-Za-z0-9])[a-h][1-8](?![0-9])',
  );

  /// O hífen entre letras ("casas-chave"): na tela vira o hífen não
  /// separável (U+2011, presente na Roboto), e a linha não quebra no meio da
  /// palavra composta. A voz segue com o hífen comum.
  static final wordHyphen = RegExp(r'(?<=\p{L})-(?=\p{L})', unicode: true);

  /// [text] com os hífens entre letras trocados por U+2011.
  static String noBreak(String text) => text.replaceAll(wordHyphen, '\u2011');

  /// A fala sem as marcas, para medir e para a voz.
  static String plain(
    String text, {
    required String mainLine,
    required String showAnswer,
  }) => text
      .replaceAllMapped(
        markPattern,
        (m) => inline(
          m.group(1) == 'verResposta' ? showAnswer : mainLine,
          text.substring(0, m.start),
        ),
      )
      .replaceAllMapped(squarePattern, (m) => m.group(1)!);

  /// O rótulo do botão citado no meio da frase ("clique em ver resposta")
  /// começa em minúscula; no começo da fala ou de uma frase, fica como no
  /// botão (Gabriel, 16/10/2026).
  static String inline(String label, String before) {
    final prev = before.trimRight();
    if (prev.isEmpty || RegExp(r'[.!?…:]$').hasMatch(prev)) return label;
    return label.substring(0, 1).toLowerCase() + label.substring(1);
  }

  /// A folga em volta da casa citada que ainda conta como toque nela: as
  /// duas letras sozinhas são um alvo pequeno demais para o dedo, e o toque
  /// ao lado abria a fala inteira (Gabriel, 16/10/2026).
  static const squareSlop = EdgeInsets.symmetric(horizontal: 14, vertical: 6);

  /// [plain] com os rótulos do idioma da tela.
  static String plainOf(BuildContext context, String text) =>
      markPattern.hasMatch(text) || squarePattern.hasMatch(text)
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
  late final _more = TapGestureRecognizer()
    ..onTap = () => widget.onMore?.call();

  final _squares = <String, TapGestureRecognizer>{};

  @override
  void dispose() {
    _mainLine.dispose();
    _showAnswer.dispose();
    _more.dispose();
    for (final recognizer in _squares.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _squareTap(String square) => _squares.putIfAbsent(
    square,
    () =>
        TapGestureRecognizer()..onTap = () => widget.onSquareTap?.call(square),
  );

  /// Há algo a desenhar além do texto simples?
  bool _hasMarkup(String text) =>
      SpeechText.markPattern.hasMatch(text) ||
      SpeechText.squarePattern.hasMatch(text) ||
      (widget.onSquareTap != null &&
          SpeechText.looseSquarePattern.hasMatch(text));

  /// O texto com as marcas trocadas pelos links.
  List<InlineSpan> _spans(BuildContext context, String text) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final link = widget.style.copyWith(
      color: primary,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: primary,
    );
    final square = widget.style.copyWith(
      color: primary,
      fontWeight: AppWeight.strong,
    );
    final spans = <InlineSpan>[];
    var at = 0;
    final tappable = widget.onSquareTap != null;
    final both = RegExp(
      '${SpeechText.markPattern.pattern}|${SpeechText.squarePattern.pattern}'
      '${tappable ? '|(${SpeechText.looseSquarePattern.pattern})' : ''}',
    );
    for (final m in both.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(at, m.start)));
      final name = m.group(2) ?? (tappable ? m.group(3) : null);
      if (name != null) {
        spans.add(
          TextSpan(
            text: name,
            style: square,
            recognizer: tappable ? _squareTap(name) : null,
          ),
        );
        at = m.end;
        continue;
      }
      final answer = m.group(1) == 'verResposta';
      final onTap = answer ? widget.onShowAnswer : widget.onMainLine;
      spans.add(
        TextSpan(
          text: SpeechText.inline(
            answer ? l10n.lessonShowAnswer : l10n.lessonMainLine,
            text.substring(0, m.start),
          ),
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
    spans.add(TextSpan(text: text.substring(at)));
    return spans;
  }

  Widget _rich(
    BuildContext context,
    String text,
    int? maxLines, {
    InlineSpan? more,
    Key? key,
  }) {
    final overflow = maxLines == null ? null : TextOverflow.ellipsis;
    if (more == null && !_hasMarkup(text)) {
      return Text(
        text,
        style: widget.style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    final rich = Text.rich(
      key: key,
      TextSpan(
        style: widget.style,
        children: [..._spans(context, text), ?more],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
    final onSquare = widget.onSquareTap;
    if (onSquare == null) return rich;
    return _SquareSlop(
      squares: {for (final e in _squares.entries) e.value: e.key},
      onSquare: onSquare,
      child: rich,
    );
  }

  TextPainter _painter(BuildContext context, String text, double width) =>
      TextPainter(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.merge(widget.style),
          children: _spans(context, text),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);

  /// Onde começa a frase do último link; nulo se ela é a fala inteira.
  static int? _linkSentence(String text) {
    final link = SpeechText.markPattern.allMatches(text).last;
    final before = text.substring(0, link.start);
    final end = RegExp(r'[.!?…]\s+').allMatches(before).lastOrNull?.end;
    return end == null || end == 0 ? null : end;
  }

  @override
  Widget build(BuildContext context) {
    final maxLines = widget.maxLines;
    final text = SpeechText.noBreak(widget.text);
    if (maxLines != null && widget.onMore != null) {
      return LayoutBuilder(
        builder: (context, box) {
          final whole = _painter(context, text, box.maxWidth);
          final lines = whole.computeLineMetrics().length;
          whole.dispose();
          if (lines <= maxLines) return _rich(context, text, null);
          final more = SpeechFit.more(
            context,
            style: widget.style,
            recognizer: _more,
          );
          final cut = SpeechFit.cut(
            context,
            text: text,
            width: box.maxWidth,
            lines: maxLines,
            style: widget.style,
            more: more,
            spans: (piece) => _spans(context, piece),
          );
          return _rich(context, cut, null, more: more, key: SpeechKeys.cut);
        },
      );
    }
    if (maxLines == null ||
        maxLines < 2 ||
        !SpeechText.markPattern.hasMatch(text)) {
      return _rich(context, text, maxLines);
    }
    // O corte nunca esconde o link (T71, opção C): se o trecho cortado tem
    // link, o corte vai para o meio, com "…", e as últimas linhas mostram
    // sempre a frase do link.
    return LayoutBuilder(
      builder: (context, box) {
        final split = _linkSentence(text);
        if (split == null || !box.hasBoundedWidth) {
          return _rich(context, text, maxLines);
        }
        final width = box.maxWidth;
        final whole = _painter(context, text, width);
        final lines = whole.computeLineMetrics().length;
        whole.dispose();
        if (lines <= maxLines) return _rich(context, text, maxLines);
        final tail = text.substring(split);
        final tailPainter = _painter(context, tail, width);
        final tailLines = tailPainter.computeLineMetrics().length.clamp(
          1,
          maxLines - 1,
        );
        tailPainter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _rich(
              context,
              text.substring(0, split).trimRight(),
              maxLines - tailLines,
            ),
            _rich(context, tail, tailLines),
          ],
        );
      },
    );
  }
}

/// O toque perto de uma casa citada (dentro de [SpeechText.squareSlop]) vale
/// como toque nela e ganha do clique do balão, que abriria a fala inteira.
/// Longe de toda casa, o toque passa adiante.
class _SquareSlop extends StatefulWidget {
  const _SquareSlop({
    required this.squares,
    required this.onSquare,
    required this.child,
  });

  /// O reconhecedor de cada casa na fala, e a casa dele.
  final Map<GestureRecognizer, String> squares;
  final ValueChanged<String> onSquare;
  final Widget child;

  @override
  State<_SquareSlop> createState() => _SquareSlopState();
}

class _SquareSlopState extends State<_SquareSlop> {
  final _text = GlobalKey();

  /// A casa mais perto de [global], se alguma está dentro da folga.
  String? _near(Offset global) {
    final paragraph = _text.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph || !paragraph.hasSize) return null;
    final local = paragraph.globalToLocal(global);
    final slop = SpeechText.squareSlop;
    String? best;
    var bestDistance = double.infinity;
    var at = 0;
    paragraph.text.visitChildren((span) {
      if (span is! TextSpan) return true;
      final length = span.text?.length ?? 0;
      final square = widget.squares[span.recognizer];
      if (square != null && length > 0) {
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: at, extentOffset: at + length),
        );
        for (final box in boxes) {
          final rect = box.toRect();
          if (!slop.inflateRect(rect).contains(local)) continue;
          final distance = (rect.center - local).distance;
          if (distance < bestDistance) {
            bestDistance = distance;
            best = square;
          }
        }
      }
      at += length;
      return true;
    });
    return best;
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    gestures: {
      _NearSquareTap: GestureRecognizerFactoryWithHandlers<_NearSquareTap>(
        () => _NearSquareTap(_near),
        (tap) => tap
          ..near = _near
          ..onTap = () {
            final square = tap.square;
            if (square != null) widget.onSquare(square);
          },
      ),
    },
    child: KeyedSubtree(key: _text, child: widget.child),
  );
}

/// Só entra na disputa do toque se ele começa perto de uma casa.
class _NearSquareTap extends TapGestureRecognizer {
  _NearSquareTap(this.near);

  String? Function(Offset global) near;

  /// A casa do toque em andamento.
  String? square;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    square = near(event.position);
    return square != null && super.isPointerAllowed(event);
  }
}
