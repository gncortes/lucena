import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';
import 'package:lucena/ui/core/widgets/character_portrait.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../config/dependencies.dart' show showsDevTools;
import '../../../domain/models/board_settings.dart';
import '../../../routing/routes.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_bar_progress.dart';
import '../../core/widgets/round_footer_button.dart';
import '../../core/widgets/viktor_conversation.dart';
import '../../lesson_script/widgets/script_board.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../settings/widgets/open_link_dialog.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/voice_pickers.dart';
import '../view_models/tour_cubit.dart';
import '../../core/keys/voice_keys.dart';
import '../../core/widgets/sound_off_icon.dart';
import '../../core/widgets/nickname_field.dart';

/// O tour da primeira abertura (canvas `PropV2TourB*`, layout "Conversa"): o
/// Viktor fala num balão e embaixo vem o que o passo mostra ou pede: o
/// tabuleiro, a voz e o nome, as aulas, a ajuda, as partidas e o nível.
class TourScreen extends StatelessWidget {
  const TourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TourCubit>();
    return BlocConsumer<TourCubit, TourState>(
      listenWhen: (previous, current) => current.finished && !previous.finished,
      listener: (context, state) {
        // A pergunta do objetivo e o nível fecham a primeira abertura. Quem
        // veio de um link já jogou: a conta, opcional, vem antes (decisão 1a
        // da E1.11).
        context.go(state.linkSetupDone ? Routes.account : Routes.goal);
      },
      builder: (context, state) {
        if (!state.ready) return const Scaffold(key: TourKeys.screen);
        final step = state.step;
        final total = state.steps.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Avançando, o passo novo entra pelo fim da linha e o velho sai pelo
        // começo; voltando, ao contrário.
        final sign = (state.forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
        final currentKey = TourKeys.step(step);
        return PopScope(
          canPop: !state.hasPrevious,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(cubit.back());
          },
          child: Scaffold(
            key: TourKeys.screen,
            // Barra de 64, como a lição e o teste (LucenaAppBar).
            appBar: LucenaAppBar(
              automaticallyImplyLeading: false,
              leading: state.hasPrevious
                  ? IconButton(
                      key: TourKeys.backButton,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l10n.tourBack,
                      onPressed: cubit.back,
                    )
                  : const SizedBox(width: 56, key: TourKeys.backSlot),
              actions: [
                // Só em rc: o QA abre um link de desafio sem App Links, até
                // na primeira abertura (E1.14).
                if (showsDevTools && state.position == 0)
                  IconButton(
                    key: TourKeys.openLink,
                    icon: const Icon(Icons.link),
                    tooltip: l10n.devOpenLinkTitle,
                    onPressed: () => showOpenLinkDialog(context),
                  ),
                if (!step.isLast)
                  // O texto do botão fica a 16 da borda (o botão tem 12 de
                  // folga por dentro).
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs,
                    ),
                    child: TextButton(
                      key: TourKeys.skipButton,
                      onPressed: cubit.skip,
                      child: Text(l10n.tourSkip),
                    ),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(AppBarProgress.height),
                child: Semantics(
                  label: l10n.tourStep(state.position + 1, total),
                  child: AppBarProgress(
                    key: TourKeys.progress,
                    value: (state.position + 1) / total,
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: TourKeys.scroll,
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ViktorConversation(
                          viktor: state.viktor,
                          speech: state.speech,
                          viktorKey: TourKeys.viktor,
                          speechKey: TourKeys.speech,
                        ),
                        ClipRect(
                          // Corta só os lados (a troca desliza); a sombra dos
                          // botões passa da borda de baixo.
                          clipper: _SideClipper(),
                          child: AnimatedSwitcher(
                            duration: AppMotion.of(context).component,
                            switchInCurve: AppMotion.enter,
                            switchOutCurve: AppMotion.exit,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topCenter,
                              children: [...previous, ?current],
                            ),
                            transitionBuilder: (child, animation) {
                              final entering = child.key == currentKey;
                              final offset = Tween(
                                begin: Offset(
                                  (entering ? 1 : -1) * sign * 0.35,
                                  0,
                                ),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offset,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              key: currentKey,
                              padding: const EdgeInsets.only(
                                top: AppSpacing.lg,
                              ),
                              child: switch (step) {
                                TourStep.board => const _BoardStep(),
                                TourStep.voice => _VoiceStep(state: state),
                                TourStep.school => const _SchoolStep(),
                                TourStep.help => const _HelpStep(),
                                TourStep.play => _PlayStep(state: state),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _TourFooter(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Recorta só os lados do passo: em cima e embaixo sobra 16 dp para a sombra.
class _SideClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -16, size.width, size.height + 16);

  @override
  bool shouldReclip(_SideClipper oldClipper) => false;
}

/// A lateral das ilustrações (canvas: 20).
const _sideInset = 20.0;

/// O botão de baixo: "Continuar" (ou "Começar" no último passo).
class _TourFooter extends StatelessWidget {
  const _TourFooter({required this.state});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TourCubit>();
    final last = state.step.isLast;
    return ActionsFooter(
      children: [
        FilledButton(
          key: last ? TourKeys.startButton : TourKeys.nextButton,
          onPressed: last ? cubit.finish : cubit.next,
          child: Text(l10n.tourNext),
        ),
      ],
    );
  }
}

/// Uma figura do passo: só se olha (a fala já diz tudo).
class _Figure extends StatelessWidget {
  const _Figure({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _sideInset),
        child: child,
      ),
    ),
  );
}

/// Anel verde do tabuleiro de ensino, da lição.
Set<Shape> _rings(List<String> squares) => {
  for (final square in squares)
    Circle(color: ScriptShapes.green, orig: Square.fromName(square)),
};

/// 1. Cores e peças do tabuleiro, com uma amostra que muda na hora.
class _BoardStep extends StatelessWidget {
  const _BoardStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final sound = context.select(
      (SettingsCubit cubit) => cubit.state?.sound ?? true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BoardPreview(
            boardKey: TourKeys.boardPreview,
            size: 216,
            // Amostra pequena: só as cores e as peças, sem as letras e os
            // números da borda.
            appearance: board.appearance.copyWith(coordinates: false),
            animated: board.animation,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SectionTitle(l10n.boardColors),
        BoardColorsCarousel(
          selected: board.colors,
          keyOf: TourKeys.boardColors,
          labelOf: (colors) => colors.label(l10n),
          onSelected: (colors) =>
              settings.setBoard(board.copyWith(colors: colors)),
        ),
        SectionTitle(l10n.boardPieces),
        PieceStyleCarousel(
          selected: board.pieces,
          colors: board.colors,
          keyOf: TourKeys.boardPieces,
          onSelected: (pieces) =>
              settings.setBoard(board.copyWith(pieces: pieces)),
        ),
        SwitchListTile(
          key: TourKeys.boardSound,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          title: Text(l10n.settingsSound),
          subtitle: Text(l10n.settingsSoundHint),
          value: sound,
          onChanged: (value) => settings.setSound(enabled: value),
        ),
      ],
    );
  }
}

/// 2. O nome do jogador e a voz do Viktor.
class _VoiceStep extends StatelessWidget {
  const _VoiceStep({required this.state});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (!state.hasVoices) {
      // Sem voz no idioma: só o nome e o aviso de como ter uma voz.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sideInset),
            child: _NameField(initial: state.nickname),
          ),
          // O aviso já traz 16 de margem: mais 4 para chegar aos 20.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: SystemVoicesHelp(missing: true),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sideInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NameField(initial: state.nickname),
          const SizedBox(height: AppSpacing.lg),
          const _TourVoiceGrid(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.tourVoiceHint,
            key: TourKeys.voiceHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// As vozes do idioma e "sem voz", três por linha, sem margem (o tour dá a
/// dele). Clicar escolhe a voz e já a deixa ouvir. Sem o tom: ele só se muda
/// nas Configurações.
class _TourVoiceGrid extends StatelessWidget {
  const _TourVoiceGrid();

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final speech = context.read<SpeechCubit>();
    final language = voiceLanguage(context);
    final l10n = context.l10n;
    return BlocBuilder<SpeechCubit, SpeechState>(
      buildWhen: (a, b) =>
          a.settings != b.settings ||
          a.voices != b.voices ||
          a.loaded != b.loaded,
      builder: (context, state) {
        if (!state.loaded) return const SizedBox.shrink();
        final voices = state.voicesFor(language);
        final current = state.voiceOf(SpeechCubit.teacherId, language)?.voice;
        final enabled = state.settings.enabled;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 2 * _gap) / 3;
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final (i, voice) in voices.indexed)
                  SizedBox(
                    width: width,
                    child: VoiceCard(
                      key: VoiceKeys.voice(voice.id),
                      icon: Icons.record_voice_over_outlined,
                      label: voiceLabel(context, voice, i),
                      detail: voiceGenderLabel(context, voice),
                      selected: enabled && voice == current,
                      onTap: () {
                        speech.setTeacherVoice(voice.id);
                        speech.preview(
                          l10n.voiceTeacherSample,
                          characterId: SpeechCubit.teacherId,
                          voiceId: voice.id,
                          language: language,
                        );
                      },
                    ),
                  ),
                SizedBox(
                  width: width,
                  child: VoiceCard(
                    key: VoiceKeys.none,
                    leading: enabled
                        ? SoundOffIcon(
                            size: 30,
                            color: Theme.of(context).colorScheme.onSurface,
                          )
                        : null,
                    label: l10n.voiceNone,
                    selected: !enabled,
                    onTap: () => speech.setEnabled(enabled: false),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// "Como devo chamar você?": o apelido do perfil, gravado enquanto o jogador
/// digita. Vazio, fica o apelido padrão.
class _NameField extends StatefulWidget {
  const _NameField({required this.initial});

  final String initial;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NicknameField(
      fieldKey: TourKeys.nameField,
      controller: _controller,
      label: l10n.tourNameLabel,
      hint: l10n.profileNicknameDefault,
      autocorrect: false,
      onChanged: context.read<TourCubit>().setNickname,
    );
  }
}

/// 3. Como são as aulas: ideia, exemplos e prática.
class _SchoolStep extends StatelessWidget {
  const _SchoolStep();

  /// A posição da figura: rei contra rei, em oposição.
  static const _fen = '8/8/4k3/8/4K3/8/8/8 w - - 0 1';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final stages = [
      (Icons.lightbulb, l10n.tourStageIdea, l10n.tourStageIdeaBody),
      (Icons.visibility, l10n.tourStageExamples, l10n.tourStageExamplesBody),
      (Icons.touch_app, l10n.tourStagePractice, l10n.tourStagePracticeBody),
    ];
    return _Figure(
      child: Column(
        children: [
          PositionBoard(
            fen: _fen,
            size: 176,
            radius: AppShape.small,
            shapes: _rings(const ['e5', 'd5', 'f5']),
          ),
          const SizedBox(height: AppSpacing.xl),
          Stack(
            key: TourKeys.stages,
            children: [
              // O fio que liga os círculos: de 1/6 a 5/6, atrás deles, na
              // altura do centro (canvas: y 27).
              Positioned.fill(
                top: 26,
                bottom: null,
                child: FractionallySizedBox(
                  widthFactor: 2 / 3,
                  child: SizedBox(
                    height: 2,
                    child: ColoredBox(color: colors.primaryContainer),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, (icon, title, body)) in stages.indexed)
                    Expanded(
                      child: _Stage(
                        icon: icon,
                        title: title,
                        body: body,
                        first: i == 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.icon,
    required this.title,
    required this.body,
    required this.first,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: first ? colors.primary : colors.primaryContainer,
          foregroundColor: first ? colors.onPrimary : colors.onPrimaryContainer,
          child: Icon(icon, size: AppIconSize.large),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 4. Como pedir ajuda: a lâmpada e "Ver resposta".
class _HelpStep extends StatelessWidget {
  const _HelpStep();

  /// A posição da figura: rei e peão, com o rei na frente.
  static const _fen = '4k3/8/4K3/4P3/8/8/8/8 w - - 0 1';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Figure(
      child: Column(
        children: [
          PositionBoard(
            fen: _fen,
            size: 200,
            radius: AppShape.small,
            shapes: _rings(const ['d6', 'f6']),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            key: TourKeys.helpButtons,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundFooterButton(
                icon: Icons.lightbulb_outline,
                tooltip: l10n.lessonHint,
                onPressed: () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, kButtonHeightCompact),
                ),
                onPressed: () {},
                icon: const Icon(Icons.visibility),
                label: Text(l10n.lessonShowAnswer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 5. As partidas: quatro adversários, o Stockfish e o rating do jogador.
class _PlayStep extends StatelessWidget {
  const _PlayStep({required this.state});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = context.select((ProfileCubit c) => c.state?.rating);
    final opponents = [
      for (final character in state.characters)
        if (character.id != 'master' && character.id != 'stockfish') character,
    ]..sort((a, b) => a.level.compareTo(b.level));
    return _Figure(
      child: Column(
        children: [
          Row(
            key: TourKeys.opponents,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final character in opponents.take(4))
                _Opponent(
                  avatar: CharacterPortrait(
                    character: character,
                    size: CharacterAvatar.speech,
                    radius: AppShape.small,
                  ),
                  name: character.name,
                  rating: '${character.level}',
                ),
              _Opponent(
                avatar: Container(
                  width: CharacterAvatar.speech,
                  height: CharacterAvatar.speech,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppShape.small),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    size: AppIconSize.large,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                name: l10n.setupOpponentStockfish,
                rating: l10n.tourStockfishMax,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (rating != null)
            Container(
              key: TourKeys.ratingChip,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: AppIconSize.button,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.homeRating(rating),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Opponent extends StatelessWidget {
  const _Opponent({
    required this.avatar,
    required this.name,
    required this.rating,
  });

  final Widget avatar;
  final String name;
  final String rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          avatar,
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
          Text(
            rating,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
