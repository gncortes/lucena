import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../keys/free_board_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';
import 'character_avatar.dart';
import 'typing_dots.dart';

/// O balão do personagem (T70, pg. 4.6/6.1): compacto com até 3 linhas e "…",
/// grande sobreposto com X por fora. Serve a partida, o Speedrun, o tabuleiro
/// livre e o prático da lição.

/// O balão e a ponta desenhados num caminho só, sem emenda: a ponta sai da
/// lateral, perto da base, levemente curva, e aponta para o retrato.
class BubblePainter extends CustomPainter {
  BubblePainter({
    required this.color,
    required this.shadow,
    required this.tail,
    required this.tailOnRight,
    this.tailBelow = false,
    this.tailInset = defaultInset,
  });

  final Color color;
  final Color shadow;
  final double tail;
  final bool tailOnRight;
  final bool tailBelow;

  /// A distância do centro da ponta de baixo até a borda do balão.
  final double tailInset;

  static const defaultInset = 22.0;
  static const _radius = 14.0;

  /// O caminho do balão num retângulo de [size]: o corpo começa depois da
  /// ponta (à esquerda, ou à direita em idiomas da direita para a esquerda).
  static Path pathFor(
    Size size, {
    required double tail,
    bool tailOnRight = false,
    bool tailBelow = false,
    double tailInset = defaultInset,
  }) {
    if (tailBelow) {
      final bottom = size.height - tail;
      final path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, bottom),
            const Radius.circular(_radius),
          ),
        );
      final x = tailOnRight ? size.width - tailInset : tailInset;
      return Path.combine(
        PathOperation.union,
        path,
        Path()
          ..moveTo(x - 8, bottom - 1)
          ..lineTo(x, size.height)
          ..lineTo(x + 8, bottom - 1)
          ..close(),
      );
    }
    final width = size.width - tail;
    final height = size.height;
    final r = math.min(_radius, math.min(width, height) / 2);
    // A ponta fica perto da base, logo acima do canto arredondado, na altura
    // da base da foto.
    final middle = math.max(height / 2, height - r - 10);
    // A base da ponta não passa dos cantos arredondados.
    final half = math.min(8.0, middle - r);
    final path = Path()
      ..moveTo(tail + r, 0)
      ..lineTo(tail + width - r, 0)
      ..arcToPoint(Offset(tail + width, r), radius: Radius.circular(r))
      ..lineTo(tail + width, height - r)
      ..arcToPoint(Offset(tail + width - r, height), radius: Radius.circular(r))
      ..lineTo(tail + r, height)
      ..arcToPoint(Offset(tail, height - r), radius: Radius.circular(r))
      ..lineTo(tail, middle + half)
      // A ponta: duas curvas suaves até a pontinha, um pouco acima do meio.
      ..quadraticBezierTo(tail - 2, middle + 2, 0, middle - 2)
      ..quadraticBezierTo(tail - 4, middle - half + 2, tail, middle - half)
      ..lineTo(tail, r)
      ..arcToPoint(Offset(tail + r, 0), radius: Radius.circular(r))
      ..close();
    if (!tailOnRight) return path;
    // Espelhada: a ponta à direita.
    final mirror = Matrix4.identity()
      ..translateByDouble(size.width, 0, 0, 1)
      ..scaleByDouble(-1, 1, 1, 1);
    return path.transform(mirror.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = pathFor(
      size,
      tail: tail,
      tailOnRight: tailOnRight,
      tailBelow: tailBelow,
      tailInset: tailInset,
    );
    canvas
      ..drawShadow(path, shadow, 3, false)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BubblePainter old) =>
      old.color != color ||
      old.shadow != shadow ||
      old.tail != tail ||
      old.tailOnRight != tailOnRight ||
      old.tailBelow != tailBelow ||
      old.tailInset != tailInset;
}

/// Um texto que aparece letra por letra, como alguém falando. O espaço do
/// texto inteiro fica reservado desde o começo: o balão não muda de tamanho
/// enquanto as letras chegam.
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    this.style,
    this.maxLines,
    this.shrink = true,
    this.prefix,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;

  /// A letra diminui até a fala caber (até 60 %). Desligado, o que não cabe
  /// ganha "…".
  final bool shrink;

  /// Algo antes do texto, visível desde o começo (o selo "Dica").
  final InlineSpan? prefix;

  /// Quanto cada letra leva para aparecer.
  static const perLetter = Duration(milliseconds: 28);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _controller
      ..duration = TypewriterText.perLetter * widget.text.length
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Com menos movimento pedido ao sistema, o texto já aparece inteiro.
    final instant = AppMotion.of(context).disabled;
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = widget.shrink
            ? _fitting(context, constraints)
            : widget.style;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _text(instant, style),
        );
      },
    );
  }

  // O estilo com a letra no maior tamanho em que a fala inteira cabe no
  // espaço dado (até 60% do tamanho normal).
  TextStyle? _fitting(BuildContext context, BoxConstraints constraints) {
    final base = widget.style ?? DefaultTextStyle.of(context).style;
    if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
      return base;
    }
    final size = base.fontSize ?? 14;
    final scaler = MediaQuery.textScalerOf(context);
    for (var scale = 1.0; scale > 0.6; scale -= 0.05) {
      final style = base.copyWith(fontSize: size * scale);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: widget.maxLines,
      )..layout(maxWidth: constraints.maxWidth);
      final fits =
          painter.height <= constraints.maxHeight && !painter.didExceedMaxLines;
      painter.dispose();
      if (fits) return style;
    }
    return base.copyWith(fontSize: size * 0.6);
  }

  Widget _text(bool instant, TextStyle? style) {
    final shown = instant
        ? widget.text.length
        : (widget.text.length * _controller.value).round();
    return Text.rich(
      TextSpan(
        children: [
          ?widget.prefix,
          TextSpan(text: widget.text.substring(0, shown)),
          // O resto, invisível, guarda o lugar das letras que faltam.
          TextSpan(
            text: widget.text.substring(shown),
            style: const TextStyle(color: Colors.transparent),
          ),
        ],
      ),
      style: style,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

TextStyle? _bubbleStyle(
  BuildContext context, {
  required bool small,
  required bool monospace,
}) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  final style = small
      ? theme.textTheme.bodyMedium
      : theme.textTheme.titleMedium;
  return style?.copyWith(
    color: dark ? Colors.white : const Color(0xFF1F1F1F),
    fontWeight: FontWeight.w600,
    height: 1.25,
    fontFamily: monospace ? 'monospace' : null,
    letterSpacing: monospace ? 0.5 : null,
  );
}

/// O selo ("Dica") antes do texto do balão.
InlineSpan _leadSpan(BuildContext context, String lead, TextStyle? base) {
  final colors = Theme.of(context).colorScheme;
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            lead,
            style: base?.copyWith(
              color: colors.primary,
              fontSize: (base.fontSize ?? 14) * .85,
            ),
          ),
        ),
      ),
    ),
  );
}

/// O balão compacto: a ponta para o retrato, o texto letra por letra em até
/// [maxLines] linhas (com "…") ou os três pontinhos enquanto a máquina pensa.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    required this.text,
    required this.semantics,
    this.textKey,
    this.bubbleKey,
    this.typingKey,
    this.monospace = false,
    this.small = false,
    this.opacity = 1,
    this.tailBelow = false,
    this.tailInset = BubblePainter.defaultInset,
    this.typing = false,
    this.lead,
    this.maxLines = 3,
    this.shrink = false,
    this.onOverflow,
    this.onTap,
    super.key,
  });

  final String text;
  final String semantics;
  final Key? textKey;
  final Key? bubbleKey;
  final Key? typingKey;
  final bool monospace;
  final bool small;
  final double opacity;
  final bool tailBelow;
  final double tailInset;
  final bool typing;
  final String? lead;
  final int maxLines;
  final bool shrink;

  /// Avisa se o texto não cabe nas [maxLines] (o toque abre o balão grande).
  final ValueChanged<bool>? onOverflow;
  final VoidCallback? onTap;

  static const tail = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? const Color(0xFF3A3A3C) : Colors.white;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final style = _bubbleStyle(context, small: small, monospace: monospace);
    final vertical = small ? 8.0 : 10.0;
    final startPad = tailBelow ? 12.0 : tail + 12;
    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          key: bubbleKey,
          painter: BubblePainter(
            color: background.withValues(alpha: opacity),
            shadow: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
            tail: tail,
            tailOnRight: rtl,
            tailBelow: tailBelow,
            tailInset: tailInset,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              startPad,
              vertical,
              12,
              vertical + (tailBelow ? tail : 0),
            ),
            child: typing
                ? SizedBox(
                    height: (style?.fontSize ?? 14) * 1.25,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: KeyedSubtree(
                        key: typingKey,
                        child: const TypingDots(),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, box) {
                      _report(context, box, style);
                      return Semantics(
                        liveRegion: true,
                        label: semantics,
                        excludeSemantics: true,
                        child: TypewriterText(
                          text,
                          key: textKey,
                          maxLines: maxLines,
                          shrink: shrink,
                          prefix: lead == null
                              ? null
                              : _leadSpan(context, lead!, style),
                          style: style,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _report(BuildContext context, BoxConstraints box, TextStyle? style) {
    final callback = onOverflow;
    if (callback == null || !box.hasBoundedWidth) return;
    final painter = TextPainter(
      text: TextSpan(
        text: lead == null ? text : '$lead  $text',
        style: shrink
            ? style?.copyWith(fontSize: (style.fontSize ?? 14) * .6)
            : style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: box.maxWidth);
    final over = painter.didExceedMaxLines;
    painter.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(over));
  }
}

/// O balão com a versão grande: toque (se o texto não cabe) abre uma camada
/// sobreposta que pode cobrir a AppBar e o tabuleiro, largura da tela menos
/// 8 dp de cada lado, altura até 60 % da tela, rolagem com barra visível e o
/// X por fora, acima do canto, que volta ao compacto.
class ExpandableSpeech extends StatefulWidget {
  const ExpandableSpeech({
    required this.text,
    required this.semantics,
    required this.expanded,
    required this.onExpandedChanged,
    required this.builder,
    this.textKey,
    this.bubbleKey,
    this.typingKey,
    this.closeKey,
    this.scrollKey,
    this.monospace = false,
    this.small = false,
    this.opacity = 1,
    this.tailBelow = false,
    this.tailInset = BubblePainter.defaultInset,
    this.typing = false,
    this.lead,
    this.maxLines = 3,
    this.shrink = false,
    super.key,
  });

  final String text;
  final String semantics;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  /// Monta o conjunto: o balão (já com a camada) e o que abre o grande
  /// (nulo se o texto cabe no compacto).
  final Widget Function(
    BuildContext context,
    Widget bubble,
    VoidCallback? expand,
  )
  builder;
  final Key? textKey;
  final Key? bubbleKey;
  final Key? typingKey;
  final Key? closeKey;
  final Key? scrollKey;
  final bool monospace;
  final bool small;
  final double opacity;
  final bool tailBelow;
  final double tailInset;
  final bool typing;
  final String? lead;
  final int maxLines;
  final bool shrink;

  @override
  State<ExpandableSpeech> createState() => _ExpandableSpeechState();
}

class _ExpandableSpeechState extends State<ExpandableSpeech> {
  final _portal = OverlayPortalController();
  final _scroll = ScrollController();
  bool _overflow = false;

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  @override
  void didUpdateWidget(ExpandableSpeech old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      // Fala nova abre compacta.
      if (_scroll.hasClients) _scroll.jumpTo(0);
      if (widget.expanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onExpandedChanged(false);
        });
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _setOverflow(bool value) {
    if (!mounted || value == _overflow) return;
    setState(() => _overflow = value);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final expanded = w.expanded && !w.typing;
    final bubble = SpeechBubble(
      text: w.text,
      semantics: w.semantics,
      textKey: expanded ? null : w.textKey,
      bubbleKey: expanded ? null : w.bubbleKey,
      typingKey: w.typingKey,
      monospace: w.monospace,
      small: w.small,
      opacity: w.opacity,
      tailBelow: w.tailBelow,
      tailInset: w.tailInset,
      typing: w.typing,
      lead: w.lead,
      maxLines: w.maxLines,
      shrink: w.shrink,
      onOverflow: expanded ? null : _setOverflow,
      onTap: _overflow && !w.typing ? () => w.onExpandedChanged(true) : null,
    );
    final portal = OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, info) =>
          expanded ? _overlay(context, info) : const SizedBox.shrink(),
      child: expanded
          ? ExcludeSemantics(
              child: IgnorePointer(child: Opacity(opacity: 0, child: bubble)),
            )
          : bubble,
    );
    return w.builder(
      context,
      portal,
      _overflow && !w.typing && !expanded
          ? () => w.onExpandedChanged(true)
          : null,
    );
  }

  Widget _overlay(BuildContext context, OverlayChildLayoutInfo info) {
    final w = widget;
    final bottomEdge = MatrixUtils.transformPoint(
      info.childPaintTransform,
      Offset(0, info.childSize.height),
    ).dy;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final style = _bubbleStyle(context, small: true, monospace: w.monospace);
    final safeTop = MediaQuery.paddingOf(context).top;
    const closeRow = 48.0;
    final room = bottomEdge - safeTop - closeRow;
    final maxCard = math.max(
      60.0,
      math.min(info.overlaySize.height * .6, room),
    );
    return Positioned(
      left: 8,
      right: 8,
      bottom: info.overlaySize.height - bottomEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CloseButton(
            key: w.closeKey ?? FreeBoardKeys.speechClose,
            onPressed: () => w.onExpandedChanged(false),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxCard),
            child: CustomPaint(
              key: w.bubbleKey ?? FreeBoardKeys.speechBubble,
              painter: BubblePainter(
                color: dark ? const Color(0xFF3A3A3C) : Colors.white,
                shadow: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
                tail: SpeechBubble.tail,
                tailOnRight: Directionality.of(context) == TextDirection.rtl,
                tailBelow: true,
                // O centro da ponta sobre o centro do retrato (12 + 24).
                tailInset: 28,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  12,
                  8,
                  4,
                  8 + SpeechBubble.tail,
                ),
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    key: w.scrollKey,
                    controller: _scroll,
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Semantics(
                      liveRegion: true,
                      label: w.semantics,
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (w.lead != null)
                              _leadSpan(context, w.lead!, style),
                            TextSpan(text: w.text),
                          ],
                        ),
                        key: w.textKey,
                        style: style?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O X do balão grande: círculo branco de 40 dp com alvo de 48 dp.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const SizedBox.square(dimension: 40),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onPressed,
            color: colors.onSurfaceVariant,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}

/// O personagem falando acima do tabuleiro (prático da lição): o balão com a
/// ponta para baixo e, embaixo, o retrato com o nome. Texto nulo: só o
/// retrato.
class CharacterSpeech extends StatelessWidget {
  const CharacterSpeech({
    required this.character,
    required this.text,
    required this.expanded,
    required this.onExpandedChanged,
    this.typing = false,
    this.lead,
    this.semantics,
    this.emotion,
    this.avatarKey,
    this.bubbleKey,
    this.textKey,
    this.typingKey,
    this.closeKey,
    this.scrollKey,
    super.key,
  });

  final Character character;
  final String? text;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final bool typing;
  final String? lead;
  final String? semantics;
  final Emotion? emotion;
  final Key? avatarKey;
  final Key? bubbleKey;
  final Key? textKey;
  final Key? typingKey;
  final Key? closeKey;
  final Key? scrollKey;

  static const avatarSize = 48.0;
  static const gap = 4.0;

  /// A altura da linha do retrato e da folga até a ponta.
  static const avatarRow = avatarSize + gap;

  @override
  Widget build(BuildContext context) {
    final avatar = Semantics(
      label: character.name,
      child: CharacterAvatar(
        key: avatarKey,
        character: character,
        emotion: emotion,
        size: avatarSize,
        radius: 12,
      ),
    );
    final name = Text(
      character.name,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final style = _bubbleStyle(context, small: true, monospace: false);
        final line =
            MediaQuery.textScalerOf(context).scale(style?.fontSize ?? 14) *
            1.25;
        // Em tela baixa o balão perde linhas, não o retrato.
        final room = box.hasBoundedHeight
            ? box.maxHeight - avatarRow - 16 - SpeechBubble.tail
            : 3 * line;
        final lines = (room / line).floor().clamp(1, 3);
        Widget row(VoidCallback? expand) => Row(
          children: [
            GestureDetector(onTap: expand, child: avatar),
            const SizedBox(width: 8),
            Flexible(child: name),
          ],
        );
        if (text == null && !typing) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: row(null),
          );
        }
        return ExpandableSpeech(
          text: text ?? '',
          semantics: semantics ?? '${character.name}: ${text ?? ''}',
          expanded: expanded,
          onExpandedChanged: onExpandedChanged,
          textKey: textKey,
          bubbleKey: bubbleKey,
          typingKey: typingKey,
          closeKey: closeKey,
          scrollKey: scrollKey,
          small: true,
          tailBelow: true,
          tailInset: 28,
          typing: typing,
          lead: lead,
          maxLines: lines,
          builder: (context, bubble, expand) => Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: bubble,
                ),
                const SizedBox(height: gap),
                row(expand),
              ],
            ),
          ),
        );
      },
    );
  }
}
