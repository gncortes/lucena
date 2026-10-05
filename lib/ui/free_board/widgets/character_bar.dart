import 'package:flutter/material.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../view_models/talk_cubit.dart';

/// O adversário acima do tabuleiro, como no chess.com: o retrato grande e, ao
/// lado, o balão com a última fala, que aparece letra por letra. O balão
/// nunca cobre o tabuleiro.
class CharacterBar extends StatelessWidget {
  const CharacterBar({required this.talk, super.key});

  /// Altura reservada para a fileira, para o tabuleiro caber.
  static const height = 108.0;

  static const _avatar = 84.0;

  final TalkState talk;

  @override
  Widget build(BuildContext context) {
    final character = talk.character!;
    final line = talk.enabled ? talk.line : null;
    return SizedBox(
      key: FreeBoardKeys.characterBar,
      height: height,
      child: Padding(
        // O retrato encosta no tabuleiro, como no chess.com.
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              label: character.name,
              child: CharacterAvatar(
                key: FreeBoardKeys.characterAvatar(talk.emotion),
                character: character,
                // O Stockfish não tem emoção: só o logo.
                emotion: talk.isEngine ? null : talk.emotion,
                size: _avatar,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.92, end: 1.0).animate(animation),
                    alignment: AlignmentDirectional.bottomStart.resolve(
                      Directionality.of(context),
                    ),
                    child: child,
                  ),
                ),
                child: line == null
                    ? const SizedBox(key: ValueKey('none'), height: _avatar)
                    : _Bubble(
                        key: ValueKey(line.id),
                        lineId: line.id,
                        text: line.text,
                        semantics: context.l10n.characterSays(
                          character.name,
                          line.text,
                        ),
                        monospace: talk.isEngine,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O balão branco com a ponta virada para o retrato.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.lineId,
    required this.text,
    required this.semantics,
    required this.monospace,
    super.key,
  });

  final String lineId;
  final String text;
  final String semantics;
  final bool monospace;

  static const _tail = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? const Color(0xFF3A3A3C) : Colors.white;
    final foreground = dark ? Colors.white : const Color(0xFF1F1F1F);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // O balão fica embaixo, rente à base da foto.
    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: Padding(
        // A base do balão na mesma linha da base da foto.
        padding: EdgeInsets.zero,
        child: CustomPaint(
          key: FreeBoardKeys.speechBubble,
          painter: _BubblePainter(
            color: background,
            shadow: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
            tail: _tail,
            tailOnRight: rtl,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              _tail + 14,
              12,
              14,
              12,
            ),
            child: Semantics(
              liveRegion: true,
              label: semantics,
              excludeSemantics: true,
              child: TypewriterText(
                text,
                key: FreeBoardKeys.speechText(lineId),
                maxLines: 3,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  fontFamily: monospace ? 'monospace' : null,
                  letterSpacing: monospace ? 0.5 : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O balão com a ponta no canto de baixo, virada para o retrato.
class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.color,
    required this.shadow,
    required this.tail,
    required this.tailOnRight,
  });

  final Color color;
  final Color shadow;
  final double tail;
  final bool tailOnRight;

  @override
  void paint(Canvas canvas, Size size) {
    final left = tailOnRight ? 0.0 : tail;
    final right = tailOnRight ? size.width - tail : size.width;
    final body = RRect.fromLTRBR(
      left,
      0,
      right,
      size.height,
      const Radius.circular(16),
    );
    // A ponta sai da lateral, perto da base, e aponta para a foto.
    final edge = tailOnRight ? right : left;
    final tip = tailOnRight ? size.width : 0.0;
    final bottom = size.height;
    final path = Path()
      ..addRRect(body)
      ..moveTo(edge, bottom - 30)
      ..lineTo(tip, bottom - 16)
      ..lineTo(edge, bottom - 8)
      ..close();
    canvas
      ..drawShadow(path, shadow, 3, false)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.tailOnRight != tailOnRight;
}

/// Um texto que aparece letra por letra, como alguém falando. O espaço do
/// texto inteiro fica reservado desde o começo: o balão não muda de tamanho
/// enquanto as letras chegam.
class TypewriterText extends StatefulWidget {
  const TypewriterText(this.text, {this.style, this.maxLines, super.key});

  final String text;
  final TextStyle? style;
  final int? maxLines;

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
    final instant = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shown = instant
            ? widget.text.length
            : (widget.text.length * _controller.value).round();
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.text.substring(0, shown)),
              // O resto, invisível, guarda o lugar das letras que faltam.
              TextSpan(
                text: widget.text.substring(shown),
                style: const TextStyle(color: Colors.transparent),
              ),
            ],
          ),
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
