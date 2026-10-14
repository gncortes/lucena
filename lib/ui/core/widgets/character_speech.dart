import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../l10n/l10n.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';
import 'character_avatar.dart';
import 'speech_balloon.dart';
import 'typing_dots.dart';

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

/// O personagem falando acima do tabuleiro (prático da lição): o balão com a
/// ponta para baixo, sobre o retrato, e embaixo o retrato com o nome. O clique
/// no balão (ou no retrato) abre a fala inteira ([onOpen]). Texto nulo: só o
/// retrato.
class CharacterSpeech extends StatelessWidget {
  const CharacterSpeech({
    required this.character,
    required this.text,
    this.onOpen,
    this.typing = false,
    this.lead,
    this.semantics,
    this.emotion,
    this.avatarKey,
    this.bubbleKey,
    this.textKey,
    this.typingKey,
    super.key,
  });

  final Character character;
  final String? text;

  /// O clique no balão: abre a folha com a fala inteira.
  final VoidCallback? onOpen;
  final bool typing;
  final String? lead;
  final String? semantics;
  final Emotion? emotion;
  final Key? avatarKey;
  final Key? bubbleKey;
  final Key? textKey;
  final Key? typingKey;

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
    final open = typing || text == null ? null : onOpen;
    final row = Row(
      children: [
        GestureDetector(onTap: open, child: avatar),
        const SizedBox(width: 8),
        Flexible(child: name),
      ],
    );
    if (text == null && !typing) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: row,
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final style = SpeechBalloon.style(context);
        final line = MediaQuery.textScalerOf(context).scale(16) * 1.5;
        // Em tela baixa o balão perde linhas, não o retrato.
        final room = box.hasBoundedHeight
            ? box.maxHeight -
                  avatarRow -
                  SpeechBalloon.defaultPadding.vertical -
                  SpeechBalloon.tailHeight
            : 3 * line;
        final lines = (room / line).floor().clamp(1, 3);
        final tailX = SpeechBalloon.tailXFor(avatarSize);
        final balloon = typing
            ? SpeechBalloon(
                key: bubbleKey,
                tailX: tailX,
                fitContent: true,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
                minHeight: 44,
                child: KeyedSubtree(key: typingKey, child: const TypingDots()),
              )
            : SpeechBalloon(
                key: bubbleKey,
                speech: text,
                tailX: tailX,
                onTap: open,
                tapHint: context.l10n.lessonFullSpeech,
                semanticsLabel: semantics ?? '${character.name}: $text',
                child: TypewriterText(
                  text!,
                  key: textKey,
                  maxLines: lines,
                  shrink: false,
                  prefix: lead == null
                      ? null
                      : _leadSpan(context, lead!, style),
                  style: style,
                ),
              );
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: balloon,
              ),
              const SizedBox(height: gap),
              row,
            ],
          ),
        );
      },
    );
  }
}
