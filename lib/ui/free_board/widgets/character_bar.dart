import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../view_models/talk_cubit.dart';
import '../../core/theme/app_motion.dart';

/// O adversário acima do tabuleiro: o retrato e, ao lado, o balão com a
/// última fala, que aparece letra por letra. O relógio dele fica na linha de
/// baixo. O balão nunca cobre o tabuleiro.
class CharacterBar extends StatelessWidget {
  const CharacterBar({
    required this.talk,
    this.avatarSize = maxAvatar,
    this.showName = true,
    super.key,
  });

  /// O tamanho do retrato: menor em tela baixa, para o tabuleiro ocupar a
  /// largura toda.
  static const maxAvatar = 84.0;
  static const minAvatar = 44.0;

  /// O espaço acima do retrato e o respiro entre a faixa e o tabuleiro.
  static const topGap = 6.0;
  static const bottomGap = 10.0;

  /// A altura da faixa com um retrato de [avatar].
  static double heightFor(double avatar) => avatar + topGap + bottomGap;

  final TalkState talk;
  final double avatarSize;

  /// O nome numa etiqueta sobre a foto. Desligado quando a linha do relógio
  /// logo abaixo já mostra o nome.
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final character = talk.character!;
    final line = talk.enabled ? talk.line : null;
    // Retrato pequeno: a fala também diminui, para caber no balão.
    final small = avatarSize < 72;
    return SizedBox(
      key: FreeBoardKeys.characterBar,
      height: heightFor(avatarSize),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          12,
          topGap,
          12,
          bottomGap,
        ),
        child: Row(
          // O balão alinhado pela base do retrato.
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              label: character.name,
              child: Stack(
                children: [
                  CharacterAvatar(
                    key: FreeBoardKeys.characterAvatar(talk.emotion),
                    character: character,
                    // O Stockfish não tem emoção: só o logo.
                    emotion: talk.isEngine ? null : talk.emotion,
                    size: avatarSize,
                  ),
                  // O nome numa etiqueta sobre a base da foto.
                  if (showName)
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: ExcludeSemantics(
                        child: _NameTag(
                          name: character.name,
                          width: avatarSize,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.state,
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
                    ? const SizedBox(key: ValueKey('none'))
                    : _spoken(
                        context,
                        line.id,
                        line.text,
                        _Bubble(
                          lineId: line.id,
                          text: line.text,
                          semantics: context.l10n.characterSays(
                            character.name,
                            line.text,
                          ),
                          monospace: talk.isEngine,
                          small: small,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A fala sai na voz do personagem, com a voz ligada. O Stockfish não
  /// fala.
  Widget _spoken(BuildContext context, String id, String text, Widget bubble) {
    final speech = TeacherSpeech.speechOf(context);
    if (speech == null || talk.isEngine) {
      return KeyedSubtree(key: ValueKey(id), child: bubble);
    }
    return AutoSpeak(
      key: ValueKey(id),
      speech: speech,
      text: text,
      // Calado pelo botão de som da partida, o balão só aparece.
      auto: !speech.state.settings.charactersMuted,
      speakerId: talk.character!.id,
      child: bubble,
    );
  }
}

/// O botão de som do personagem, na barra da partida: cala a voz dele (e a
/// fala que estiver no meio) ou volta a ouvi-la. A escolha fica gravada. Sem
/// voz no idioma do app, não aparece.
class CharacterSoundButton extends StatelessWidget {
  const CharacterSoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    final speech = TeacherSpeech.speechOf(context);
    if (speech == null) return const SizedBox.shrink();
    return BlocBuilder<SpeechCubit, SpeechState>(
      bloc: speech,
      builder: (context, state) {
        final language = Localizations.localeOf(context).toLanguageTag();
        if (!state.availableFor(language)) return const SizedBox.shrink();
        final heard = state.charactersHeard;
        return IconButton(
          key: FreeBoardKeys.soundButton,
          isSelected: heard,
          icon: const Icon(Icons.volume_off_outlined),
          selectedIcon: const Icon(Icons.volume_up_outlined),
          tooltip: heard
              ? context.l10n.characterSoundOff
              : context.l10n.characterSoundOn,
          onPressed: () => speech.setCharactersHeard(heard: !heard),
        );
      },
    );
  }
}

/// O nome do personagem na base do retrato, em branco sobre uma faixa escura.
class _NameTag extends StatelessWidget {
  const _NameTag({required this.name, required this.width});

  final String name;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(width * 0.14),
      ),
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 3),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xB3000000)],
          ),
        ),
        child: Text(
          name,
          key: FreeBoardKeys.characterName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// O balão com a ponta virada para o retrato, alinhado pela base da foto.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.lineId,
    required this.text,
    required this.semantics,
    required this.monospace,
    required this.small,
  });

  final String lineId;
  final String text;
  final String semantics;
  final bool monospace;
  final bool small;

  static const _tail = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? const Color(0xFF3A3A3C) : Colors.white;
    final foreground = dark ? Colors.white : const Color(0xFF1F1F1F);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final style = small
        ? theme.textTheme.bodyMedium
        : theme.textTheme.titleMedium;
    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: CustomPaint(
        key: FreeBoardKeys.speechBubble,
        painter: BubblePainter(
          color: background,
          shadow: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
          tail: _tail,
          tailOnRight: rtl,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            _tail + 12,
            small ? 8 : 10,
            12,
            small ? 8 : 10,
          ),
          child: Semantics(
            liveRegion: true,
            label: semantics,
            excludeSemantics: true,
            child: TypewriterText(
              text,
              key: FreeBoardKeys.speechText(lineId),
              maxLines: 3,
              style: style?.copyWith(
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
    );
  }
}

/// O balão e a ponta desenhados num caminho só, sem emenda: a ponta sai da
/// lateral, perto da base, levemente curva, e aponta para o retrato.
class BubblePainter extends CustomPainter {
  BubblePainter({
    required this.color,
    required this.shadow,
    required this.tail,
    required this.tailOnRight,
  });

  final Color color;
  final Color shadow;
  final double tail;
  final bool tailOnRight;

  static const _radius = 14.0;

  /// O caminho do balão num retângulo de [size]: o corpo começa depois da
  /// ponta (à esquerda, ou à direita em idiomas da direita para a esquerda).
  static Path pathFor(
    Size size, {
    required double tail,
    bool tailOnRight = false,
  }) {
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
    final path = pathFor(size, tail: tail, tailOnRight: tailOnRight);
    canvas
      ..drawShadow(path, shadow, 3, false)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BubblePainter old) =>
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
    final instant = AppMotion.of(context).disabled;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fala longa no espaço do balão: a letra diminui até caber inteira,
        // em vez de cortar a última linha.
        final style = _fitting(context, constraints);
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
