import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/home_layout.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_appearance_widgets.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../../domain/models/character.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/theme/app_accent_ui.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../home/widgets/home_path_ui.dart';
import 'tour_demos.dart';
import '../../core/widgets/accent_picker.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/theme_mode_picker.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/rating_level_sheet.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/widgets/voice_pickers.dart';
import '../view_models/tour_cubit.dart';

/// O tour da primeira abertura: o que é o app, a aparência (tema, cor do app
/// e tabuleiro), rating, Jornada, finais, adversários, speedrun e recordes, e
/// no fim o nível do jogador.
class TourScreen extends StatelessWidget {
  const TourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TourCubit>();
    return BlocConsumer<TourCubit, TourState>(
      listenWhen: (previous, current) => current.finished && !previous.finished,
      listener: (context, state) {
        // A faixa escolhida já está no perfil.
        context.read<ProfileCubit>().load();
        // O iniciante vai direto para as aulas (a tela inicial fica embaixo).
        context.go(state.toSchool ? Routes.school : Routes.home);
      },
      builder: (context, state) {
        if (!state.ready) return const Scaffold(key: TourKeys.screen);
        final step = state.step;
        final total = TourStep.values.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Avançando, o passo novo entra pelo fim da linha e o velho sai pelo
        // começo; voltando, ao contrário. Em árabe, espelhado.
        final sign = (state.forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
        final currentKey = TourKeys.step(step);
        return Scaffold(
          key: TourKeys.screen,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Semantics(
              label: l10n.tourStep(step.index + 1, total),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: StepProgress(
                        key: TourKeys.progress,
                        total: total,
                        value: step.index + 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${step.index + 1}/$total',
                      key: TourKeys.stepCounter,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (!step.isLast)
                TextButton(
                  key: TourKeys.skipButton,
                  onPressed: cubit.skip,
                  child: Text(l10n.tourSkip),
                ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // A tela toda rola: a fala do Viktor e o passo, juntos.
                Positioned.fill(
                  child: SingleChildScrollView(
                    key: TourKeys.scroll,
                    // O fim do passo sobe acima dos botões, que flutuam.
                    padding: const EdgeInsets.only(bottom: _actionsHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.viktor case final viktor?)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: TeacherSpeech(
                              key: TourKeys.viktor,
                              teacher: viktor,
                              text: state.speech,
                              emotion: step.isLast && state.toSchool
                                  ? Emotion.happy
                                  : Emotion.calm,
                              avatarSize: 64,
                              bubbleKey: TourKeys.speech,
                              speaks: true,
                            ),
                          ),
                        ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
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
                            child: switch (step) {
                              TourStep.theme => _ThemeStep(key: currentKey),
                              TourStep.board => _BoardStep(key: currentKey),
                              TourStep.sound => _SoundStep(key: currentKey),
                              TourStep.voice => _VoiceStep(key: currentKey),
                              TourStep.characterVoices => _CharacterVoicesStep(
                                key: currentKey,
                              ),
                              TourStep.level => _LevelStep(
                                key: currentKey,
                                state: state,
                              ),
                              TourStep.goals => _GoalsStep(
                                key: currentKey,
                                state: state,
                              ),
                              // Nas boas-vindas, o Viktor pergunta o nome.
                              TourStep.goal => _InfoStep(
                                key: currentKey,
                                step: step,
                                footer: _NameField(initial: state.nickname),
                              ),
                              _ => _InfoStep(
                                key: currentKey,
                                step: step,
                                characters: state.characters,
                              ),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Os botões flutuam sobre a tela, como na lição: o passo usa a
                // altura toda e passa por baixo deles.
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: _TourActions(state: state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A altura dos botões que flutuam embaixo, com a margem.
const _actionsHeight = 96.0;

/// "Voltar" e "Próximo" (ou "Começar") flutuando embaixo, sobre uma faixa que
/// esmaece até a cor do fundo: o conteúdo passa por trás sem ficar cortado
/// seco.
class _TourActions extends StatelessWidget {
  const _TourActions({required this.state});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TourCubit>();
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final step = state.step;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            background.withValues(alpha: 0),
            background.withValues(alpha: 0),
            background,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          children: [
            if (state.hasPrevious)
              FloatingActionButton(
                key: TourKeys.backButton,
                heroTag: null,
                shape: const CircleBorder(),
                elevation: 2,
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                tooltip: l10n.tourBack,
                onPressed: cubit.back,
                child: const Icon(Icons.arrow_back),
              ),
            const Spacer(),
            FloatingActionButton.extended(
              key: step.isLast ? TourKeys.startButton : TourKeys.nextButton,
              heroTag: null,
              shape: const StadiumBorder(),
              elevation: 2,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              onPressed: step.isLast ? cubit.finish : cubit.next,
              label: Text(
                step == TourStep.characterVoices
                    ? l10n.tourKeepVoices
                    : !step.isLast
                    ? l10n.tourNext
                    : state.toSchool
                    ? l10n.tourStartLessons
                    : l10n.tourStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({
    required this.step,
    this.footer,
    this.characters = const [],
    super.key,
  });

  final TourStep step;

  /// Os personagens, para a demonstração do passo.
  final List<Character> characters;

  /// O que o passo pede ao jogador, embaixo do texto.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, title, body) = switch (step) {
      TourStep.goal => (
        Icons.school_outlined,
        l10n.tourGoalTitle,
        l10n.tourGoalBody,
      ),
      TourStep.rating => (
        Icons.trending_up,
        l10n.tourRatingTitle,
        l10n.tourRatingBody,
      ),
      TourStep.journey => (
        Icons.flag_rounded,
        l10n.tourJourneyTitle,
        l10n.tourJourneyBody,
      ),
      TourStep.endgames => (
        Icons.grid_on_outlined,
        l10n.tourEndgamesTitle,
        l10n.tourEndgamesBody,
      ),
      TourStep.opponents => (
        Icons.chat_bubble_outline,
        l10n.tourOpponentsTitle,
        l10n.tourOpponentsBody,
      ),
      TourStep.speedrun => (
        Icons.timer_outlined,
        l10n.tourSpeedrunTitle,
        l10n.tourSpeedrunBody,
      ),
      TourStep.records => (
        Icons.emoji_events_outlined,
        l10n.tourRecordsTitle,
        l10n.tourRecordsBody,
      ),
      TourStep.theme ||
      TourStep.board ||
      TourStep.sound ||
      TourStep.voice ||
      TourStep.characterVoices ||
      TourStep.level ||
      TourStep.goals => (Icons.person_outline, '', ''),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          // Uma demonstração do que o passo apresenta; nos outros, o ícone.
          if (TourDemo.covers(step))
            TourDemo(step: step, characters: characters)
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 44,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (footer case final footer?) ...[
            const SizedBox(height: 28),
            footer,
          ],
        ],
      ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: TextField(
        key: TourKeys.nameField,
        controller: _controller,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        autocorrect: false,
        inputFormatters: [
          LengthLimitingTextInputFormatter(UserProfile.maxNicknameLength),
        ],
        onChanged: context.read<TourCubit>().setNickname,
        decoration: InputDecoration(
          labelText: l10n.tourNameLabel,
          hintText: l10n.profileNicknameDefault,
          helperText: l10n.tourNameHelper,
          helperMaxLines: 3,
          // O apelido padrão fica à vista enquanto o campo está vazio.
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: const Icon(Icons.person_outline),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Título de um passo de escolha, com uma explicação curta opcional.
class _ChoiceHeader extends StatelessWidget {
  const _ChoiceHeader({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = this.body;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tema claro, escuro ou o do aparelho, e a cor do app. A escolha vale na
/// hora, no app inteiro, e fica gravada.
class _ThemeStep extends StatelessWidget {
  const _ThemeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>();
    final mode = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    final chosen = context.select((SettingsCubit cubit) => cubit.state?.accent);
    // Sem cor escolhida, vale a de fábrica do tema que está na tela.
    final accent =
        chosen ??
        AppAccent.standard(
          dark: Theme.of(context).brightness == Brightness.dark,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceHeader(title: l10n.tourThemeTitle, body: l10n.tourThemeBody),
        AppearanceSectionTitle(l10n.settingsTheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ThemeModePicker(
            selected: mode,
            accent: chosen,
            keyOf: TourKeys.themeMode,
            onSelected: settings.setThemeMode,
          ),
        ),
        const SizedBox(height: 8),
        AppearanceSectionTitle(
          l10n.settingsAccent,
          value: accent.label(l10n),
          valueKey: TourKeys.accentValue,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AccentPicker(
            selected: accent,
            keyOf: TourKeys.accent,
            onSelected: settings.setAccent,
          ),
        ),
      ],
    );
  }
}

/// Com som ou sem som. A escolha vale na hora e fica gravada; ao escolher
/// "com som", o app toca o som de um lance.
class _SoundStep extends StatelessWidget {
  const _SoundStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>();
    final sound = context.select(
      (SettingsCubit cubit) => cubit.state?.sound ?? true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceHeader(title: l10n.tourSoundTitle, body: l10n.tourSoundBody),
        const SizedBox(height: 8),
        for (final enabled in const [true, false])
          ListTile(
            key: TourKeys.sound(enabled: enabled),
            selected: sound == enabled,
            leading: Icon(
              enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            ),
            title: Text(enabled ? l10n.tourSoundOn : l10n.tourSoundOff),
            trailing: Icon(
              sound == enabled
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => settings.setSound(enabled: enabled),
          ),
      ],
    );
  }
}

/// A voz do Viktor: as vozes do idioma, cada uma com o "ouvir", e "sem
/// voz".
class _VoiceStep extends StatelessWidget {
  const _VoiceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceHeader(title: l10n.tourVoiceTitle, body: l10n.tourVoiceBody),
        const SizedBox(height: 8),
        const TeacherVoiceList(withNone: true),
        const SystemVoicesHelp(),
      ],
    );
  }
}

/// As vozes dos adversários, já escolhidas pelo app; tocar num troca.
class _CharacterVoicesStep extends StatelessWidget {
  const _CharacterVoicesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceHeader(
          title: l10n.tourCharacterVoicesTitle,
          body: l10n.tourCharacterVoicesBody,
        ),
        const SizedBox(height: 8),
        const CharacterVoiceList(),
      ],
    );
  }
}

/// Cores e peças do tabuleiro, com uma amostra que muda na hora.
class _BoardStep extends StatelessWidget {
  const _BoardStep({super.key});

  static const _previewShare = 0.3;
  static const _minPreview = 120.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // A amostra fica com uma parte da altura da tela (a tela rola) e
        // nunca mais larga que ela.
        final previewSize = math.max(
          _minPreview,
          math.min(
            MediaQuery.sizeOf(context).height * _previewShare,
            constraints.maxWidth - 96,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChoiceHeader(title: l10n.tourBoardTitle),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: BoardPreview(
                  boardKey: TourKeys.boardPreview,
                  size: previewSize,
                  // Amostra pequena: só as cores e as peças, sem as letras
                  // e os números da borda.
                  board: board.copyWith(coordinates: false),
                ),
              ),
            ),
            AppearanceSectionTitle(l10n.boardColors),
            BoardColorsCarousel(
              selected: board.colors,
              keyOf: TourKeys.boardColors,
              onSelected: (colors) =>
                  settings.setBoard(board.copyWith(colors: colors)),
            ),
            AppearanceSectionTitle(l10n.boardPieces),
            PieceStyleCarousel(
              selected: board.pieces,
              colors: board.colors,
              keyOf: TourKeys.boardPieces,
              onSelected: (pieces) =>
                  settings.setBoard(board.copyWith(pieces: pieces)),
            ),
          ],
        );
      },
    );
  }
}

/// "Qual é o seu nível atual?": as faixas do perfil, e o degrau em que a
/// Jornada vai começar.
class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.state, super.key});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TourCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tourLevelTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.tourLevelBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final level in RatingLevel.values)
          RatingLevelOption(
            key: TourKeys.level(level),
            level: level,
            selected: level == state.level,
            onTap: () => cubit.setLevel(level),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Icon(
                state.toSchool ? Icons.school_outlined : Icons.flag_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.toSchool
                      ? l10n.tourLevelSchool
                      : l10n.tourLevelStart(
                          OpponentKind.maia.label(
                            l10n,
                            level: int.parse(state.startRung),
                          ),
                        ),
                  key: TourKeys.startRung,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// O que o jogador quer fazer no Lucena: os cinco caminhos na ordem do nível
/// dele, com os sugeridos já marcados. Os marcados ficam em destaque na tela
/// inicial; os outros, em "Outros modos".
class _GoalsStep extends StatelessWidget {
  const _GoalsStep({required this.state, super.key});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<TourCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tourGoalsTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.tourGoalsBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final (index, path) in state.paths.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: StaggeredEntrance(
              index: index,
              child: _GoalCard(
                key: TourKeys.goal(path),
                path: path,
                level: state.level,
                selected: state.goals.contains(path),
                // O último marcado não sai.
                enabled:
                    !(state.goals.length == 1 && state.goals.contains(path)),
                onTap: () => cubit.toggleGoal(path),
              ),
            ),
          ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.path,
    required this.level,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final HomePath path;
  final RatingLevel level;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Marcar acende o cartão com uma transição curta de cor e borda.
    return Semantics(
      checked: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? colors.secondaryContainer
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 12),
              child: Row(
                children: [
                  Icon(path.icon, color: colors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.title(l10n),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          path.body(l10n, level),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: selected,
                    onChanged: enabled ? (_) => onTap() : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
