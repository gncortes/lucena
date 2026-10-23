import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena/ui/core/widgets/character_portrait.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';
import '../../core/keys/free_board_keys.dart';
import '../../settings/view_models/settings_cubit.dart';
import 'sound_dialog.dart';
import 'clock_row.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_speech.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/speech_balloon.dart';
import '../../core/widgets/game_entrance.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../view_models/talk_cubit.dart';
import '../../core/widgets/sound_off_icon.dart';

/// O adversário acima do tabuleiro: o retrato e, ao lado, o balão com a
/// última fala, que aparece letra por letra. O relógio dele fica na linha de
/// baixo. O balão nunca cobre o tabuleiro.
class CharacterBar extends StatelessWidget {
  const CharacterBar({
    required this.talk,
    this.avatarSize = CharacterAvatar.player,
    this.showName = true,
    this.speechTop,
    this.playerRow,
    super.key,
  });

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

  /// Posição do balão flutuante em relação ao retrato. Sem valor, mantém
  /// a faixa usada pelos outros contextos.
  final double? speechTop;

  /// Barra única com retrato, nome e relógio, já pronta pelo chamador.
  final Widget? playerRow;

  @override
  Widget build(BuildContext context) {
    final character = talk.character!;
    final line = talk.enabled ? talk.line : null;
    if (speechTop case final top?) {
      return _SpeechOverlay(
        top: top,
        speech: line == null
            ? null
            : _TransientSpeech(
                text: line.text,
                child: GameEntrance(
                  part: GameEntrancePart.speech,
                  // O balão fica no lugar; só o texto troca (crossfade).
                  child: _balloon(context, character, line, BalloonTail.down),
                ),
              ),
        child: SizedBox(
          height: playerRow == null ? heightFor(avatarSize) : ClockRow.height,
          child: playerRow != null
              ? KeyedSubtree(key: FreeBoardKeys.characterBar, child: playerRow!)
              : CharacterBar(
                  talk: talk.copyWith(clearLine: true),
                  avatarSize: avatarSize,
                  showName: showName,
                ),
        ),
      );
    }
    return SizedBox(
      key: FreeBoardKeys.characterBar,
      height: heightFor(avatarSize),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          topGap,
          AppSpacing.md,
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
                  CharacterPortrait(
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
            // O vão até a ponta vem do balão.
            Expanded(
              // Na entrada da partida, o balão chega por último.
              child: GameEntrance(
                part: GameEntrancePart.speech,
                child: line == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: _balloon(
                          context,
                          character,
                          line,
                          BalloonTail.start,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// O balão único do app com a fala do personagem: o clique abre a folha com
  /// a fala inteira (sem botão de fechar).
  Widget _balloon(
    BuildContext context,
    Character character,
    CharacterLine line,
    BalloonTail tail,
  ) => SpeechBalloon(
    key: FreeBoardKeys.speechBubble,
    speech: line.id,
    tail: tail,
    // No overlay o balão começa 4 dp antes do retrato (12 contra 16).
    tailX:
        SpeechBalloon.tailXFor(avatarSize) + (tail == BalloonTail.down ? 4 : 0),
    fitContent: true,
    semanticsLabel: context.l10n.characterSays(character.name, line.text),
    tapHint: context.l10n.lessonFullSpeech,
    onTap: () => unawaited(
      showScriptSpeechSheet(
        context,
        viktor: character,
        title: character.name,
        texts: [line.text],
      ),
    ),
    child: _spoken(
      context,
      line.id,
      line.text,
      TypewriterText(
        line.text,
        key: FreeBoardKeys.speechText(line.id),
        maxLines: 3,
        shrink: false,
        style: SpeechBalloon.style(context),
      ),
    ),
  );

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
      auto:
          (context.watch<SettingsCubit?>()?.state?.sound ?? true) &&
          !speech.state.settings.charactersMuted,
      speakerId: talk.character!.id,
      child: bubble,
    );
  }
}

/// A camada ocupa o Overlay da rota: o balão continua recebendo toques mesmo
/// quando a fala está acima da faixa do jogador, fora da área dessa faixa.
class _SpeechOverlay extends StatefulWidget {
  const _SpeechOverlay({
    required this.top,
    required this.speech,
    required this.child,
  });
  final double top;
  final Widget? speech;
  final Widget child;

  @override
  State<_SpeechOverlay> createState() => _SpeechOverlayState();
}

class _SpeechOverlayState extends State<_SpeechOverlay> {
  final _controller = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _controller.show();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal.overlayChildLayoutBuilder(
    controller: _controller,
    overlayChildBuilder: (context, info) {
      if (widget.speech == null) return const SizedBox.shrink();
      final origin = MatrixUtils.transformPoint(
        info.childPaintTransform,
        Offset(12, widget.top),
      );
      // A base do balão fica em `top + 84` (os chamadores medem `top` a
      // partir daí); o balão cresce para cima.
      return Positioned(
        left: origin.dx,
        bottom: info.overlaySize.height - (origin.dy + 84),
        width: math.max(0, info.childSize.width - 24),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          heightFactor: 1,
          child: widget.speech!,
        ),
      );
    },
    child: widget.child,
  );
}

/// A fala flutua sem mudar o tamanho da faixa. A duração
/// acompanha a leitura; o esmaecer respeita a preferência de movimento.
class _TransientSpeech extends StatefulWidget {
  const _TransientSpeech({required this.text, required this.child});

  final String text;
  final Widget child;

  @override
  State<_TransientSpeech> createState() => _TransientSpeechState();
}

class _TransientSpeechState extends State<_TransientSpeech> {
  Timer? _hide;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(_TransientSpeech oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _restart();
  }

  void _restart() {
    _hide?.cancel();
    _visible = true;
    _hide = Timer(AppMotion.floatingSpeech(widget.text.length), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !_visible,
    child: ExcludeSemantics(
      excluding: !_visible,
      child: AnimatedOpacity(
        duration: AppMotion.of(context).component,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    ),
  );
}

/// Som e voz num único botão; a velocidade aparece apenas com a voz ativa.
class CharacterSoundButton extends StatelessWidget {
  const CharacterSoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final sound = settings?.sound ?? true;
    final heard =
        sound && (settings?.characterTalk ?? true) && speech.charactersHeard;
    final language = Localizations.localeOf(context).toLanguageTag();
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.gameSoundAndVoice,
      child: SizedBox(
        height: 56,
        child: TextButton(
          key: FreeBoardKeys.soundButton,
          onPressed: () => showGameSoundDialog(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: heard && speech.availableFor(language),
                label: Text(l10n.voiceSpeedValue(speech.settings.speed)),
                child: sound
                    ? const Icon(
                        Icons.volume_up_outlined,
                        size: AppIconSize.standard,
                      )
                    : const SoundOffIcon(size: AppIconSize.standard),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: Text(
                  sound ? l10n.gameSoundLabelOn : l10n.gameSoundLabelOff,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.clear, AppColors.scrimBottom],
          ),
        ),
        child: Text(
          name,
          key: FreeBoardKeys.characterName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
