import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/character.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/keys/speech_keys.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../settings/view_models/settings_cubit.dart';
import 'sound_dialog.dart';
import 'clock_row.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/character_speech.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/speech_balloon.dart';
import '../../core/widgets/game_entrance.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../view_models/talk_cubit.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/sound_off_icon.dart';
import '../../core/theme/app_colors.dart';

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
    this.speechMaxLines = 3,
    this.onSpeechVisibilityChanged,
    this.dismissOn,
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

  /// Resumo responsivo; o toque continua abrindo a fala inteira.
  final int speechMaxLines;

  /// A largura do texto do balão numa faixa de [width]: o balão tem 12 de
  /// margem de cada lado (`_SpeechOverlay`) e o recuo do próprio balão.
  static double speechTextWidth(double width) =>
      math.max(0, width - 24 - SpeechBalloon.defaultPadding.horizontal);

  final ValueChanged<bool>? onSpeechVisibilityChanged;

  /// Muda a cada lance: o balão aberto por cima fecha no lance seguinte.
  final Object? dismissOn;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _build(context, box.maxWidth));

  Widget _build(BuildContext context, double width) {
    final character = talk.character!;
    final line = talk.enabled ? talk.line : null;
    if (speechTop case final top?) {
      final fit = line == null
          ? null
          : SpeechFit.measure(
              context,
              text: line.text,
              width: speechTextWidth(width),
              base: SpeechBalloon.style(context),
            );
      return _SpeechOverlay(
        top: top,
        open: fit?.open ?? false,
        speech: line == null
            ? null
            : _TransientSpeech(
                id: line.id,
                text: line.text,
                open: fit!.open,
                dismissOn: dismissOn,
                onVisibilityChanged: onSpeechVisibilityChanged,
                builder: (context, close) => GameEntrance(
                  part: GameEntrancePart.speech,
                  // O balão fica no lugar; só o texto troca (crossfade).
                  child: _balloon(
                    context,
                    character,
                    line,
                    BalloonTail.down,
                    fit,
                    speechTextWidth(width),
                    onClose: fit.open ? close : null,
                  ),
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
    // Ao lado do retrato, numa faixa de altura fixa: as linhas do espaço
    // fixo e, além delas, "… Ver mais" (sem abrir por cima).
    final besideWidth = math.max(
      0.0,
      width -
          2 * AppSpacing.md -
          avatarSize -
          SpeechBalloonShape.sideSize.width -
          SpeechBalloon.tailGap -
          SpeechBalloon.defaultPadding.horizontal,
    );
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
                          SpeechFit.measure(
                            context,
                            text: line.text,
                            width: besideWidth,
                            base: SpeechBalloon.style(context),
                            opened: SpeechFit.fixedLines,
                          ),
                          besideWidth,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A folha com a fala inteira: retrato, nome, a fala direto na superfície
  /// e o botão de som.
  void _openSheet(BuildContext context, Character character, String text) {
    final speech = context.read<SpeechCubit?>()?.state;
    final sound = context.read<SettingsCubit?>()?.state?.sound ?? true;
    unawaited(
      showScriptSpeechSheet(
        context,
        viktor: character,
        title: character.name,
        texts: [text],
        // O mesmo painel de som e voz da partida.
        action: LessonVoiceButton(
          audible: sound && (speech?.charactersHeard ?? false),
          speed: speech?.settings.speed ?? 1,
          onPressed: () => showGameSoundDialog(context),
        ),
      ),
    );
  }

  /// O balão único do app com a fala do personagem (T84): cabe no espaço
  /// fixo de 2 linhas (letra de 15 a 13); passou disso, se abre por cima com
  /// o X ([onClose]); nem assim cabe, corta em "… Ver mais". O clique no
  /// balão abre a folha com a fala inteira.
  Widget _balloon(
    BuildContext context,
    Character character,
    CharacterLine line,
    BalloonTail tail,
    SpeechFit fit,
    double width, {
    VoidCallback? onClose,
  }) {
    final style = fit.style;
    var text = line.text;
    InlineSpan? more;
    if (fit.overflow) {
      // "Ver mais" sem reconhecedor próprio: o toque cai no balão, que abre
      // a folha com a fala inteira.
      more = SpeechFit.more(context, style: style);
      text = SpeechFit.cut(
        context,
        text: line.text,
        width: width,
        lines: fit.lines,
        style: style,
        more: more,
      );
    }
    return SpeechBalloon(
      key: FreeBoardKeys.speechBubble,
      speech: line.id,
      tail: tail,
      // No overlay o balão começa 4 dp antes do retrato (12 contra 16).
      tailX:
          SpeechBalloon.tailXFor(avatarSize) +
          (tail == BalloonTail.down ? 4 : 0),
      fitContent: true,
      semanticsLabel: context.l10n.characterSays(character.name, line.text),
      tapHint: context.l10n.lessonFullSpeech,
      onTap: () => _openSheet(context, character, line.text),
      onClose: onClose,
      child: _spoken(
        context,
        line.id,
        line.text,
        KeyedSubtree(
          key: more == null ? null : SpeechKeys.cut,
          child: TypewriterText(
            text,
            key: FreeBoardKeys.speechText(line.id),
            maxLines: fit.lines,
            shrink: false,
            suffix: more,
            style: style,
          ),
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
    this.open = false,
  });
  final double top;

  /// Aberto por cima: o X sai 16 dp além da borda, e a camada alarga o
  /// mesmo tanto para o balão manter a largura.
  final bool open;
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
        width: math.max(
          0,
          info.childSize.width -
              24 +
              (widget.open ? SpeechBalloon.closeOverhang : 0),
        ),
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
/// acompanha a leitura; o esmaecer respeita a preferência de movimento. O
/// balão aberto por cima também fecha no X e no lance seguinte ([dismissOn]).
class _TransientSpeech extends StatefulWidget {
  const _TransientSpeech({
    required this.id,
    required this.text,
    required this.builder,
    this.open = false,
    this.dismissOn,
    this.onVisibilityChanged,
  });

  /// A fala nova (mesmo com o mesmo texto) volta a aparecer.
  final String id;
  final String text;
  final Widget Function(BuildContext context, VoidCallback close) builder;
  final bool open;
  final Object? dismissOn;
  final ValueChanged<bool>? onVisibilityChanged;

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
    if (oldWidget.id != widget.id || oldWidget.text != widget.text) {
      _restart();
    } else if (widget.open && oldWidget.dismissOn != widget.dismissOn) {
      _close();
    }
  }

  void _restart() {
    _hide?.cancel();
    _visible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _visible) widget.onVisibilityChanged?.call(true);
    });
    _hide = Timer(AppMotion.floatingSpeech(widget.text.length), _close);
  }

  void _close() {
    _hide?.cancel();
    if (mounted && _visible) setState(() => _visible = false);
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
        onEnd: () {
          if (!_visible) widget.onVisibilityChanged?.call(false);
        },
        child: widget.builder(context, _close),
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
