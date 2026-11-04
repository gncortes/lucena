import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/load_error.dart';
import '../../core/widgets/skeleton.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/dependencies.dart' show showsDevTools;
import '../../../domain/models/app_theme_mode.dart';
import '../../../domain/models/board_settings.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_appearance_widgets.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme_mode_ui.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/motion/barra_que_enche.dart';
import '../../core/motion/transicao_eixo_x.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/widgets/app_bar_progress.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/viktor_conversation.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../settings/widgets/open_link_dialog.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../../voice/widgets/voice_pickers.dart';
import '../view_models/tour_cubit.dart';
import 'tour_account_step.dart';
import 'tour_level_step.dart';
import 'tour_region_step.dart';
import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/chesscom/chesscom_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/lichess/lichess_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/analytics/analytics_context.dart';
import '../../level/view_models/level_cubit.dart';
import '../../core/widgets/sound_off_icon.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/nickname_field.dart';

/// O tour da primeira abertura (canvas `PropV2TourB*`, layout "Conversa"): o
/// Viktor fala num balão e embaixo vem o que o passo mostra ou pede: o
/// tabuleiro, o tema, a voz e o nome, o nível, a região e a conta.
class TourScreen extends StatelessWidget {
  const TourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TourCubit>();
    return BlocConsumer<TourCubit, TourState>(
      listenWhen: (previous, current) => current.finished && !previous.finished,
      listener: (context, state) {
        // O tour só termina ao sair da Conta: dali vai ao Início.
        context.go(Routes.home);
      },
      builder: (context, state) {
        if (state.failure case final failure?) {
          return LoadErrorScreen(
            kind: LoadErrorKind.fromFailure(failure),
            onAction: () =>
                cubit.load(Localizations.localeOf(context).languageCode),
          );
        }
        if (!state.ready) {
          return const Scaffold(key: TourKeys.screen, body: SkeletonList());
        }
        final step = state.step;
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
                // Na Conta não há o que pular.
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
                // H-ANI-13: enche na primeira entrada e segue a cada passo.
                child: KeyedSubtree(
                  key: TourKeys.progress,
                  child: BarraQueEnche(
                    valor: state.progress,
                    altura: AppBarProgress.height,
                  ),
                ),
              ),
            ),
            // O nível usa o `LevelCubit` (criado só quando o passo abre).
            body: BlocProvider(
              create: (context) => LevelCubit(
                onboarding: context.read<OnboardingRepository>(),
                profile: context.read<ProfileRepository>(),
                characters: context.read<CharacterRepository>(),
                lichess: context.read<LichessRepository>(),
                chessCom: context.read<ChessComRepository>(),
                home: context.read<HomeLayoutRepository>(),
                inTour: true,
                analytics: context.analytics,
                accounts: context.read<AccountRepository>(),
                sync: context.read<SyncScheduler>(),
                now: context.read<Now>(),
              )..load(),
              child: Column(
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
                            speech: _speech(l10n, state),
                            viktorKey: TourKeys.viktor,
                            speechKey: TourKeys.speech,
                          ),
                          ClipRect(
                            // Corta só os lados (a troca desliza); a sombra dos
                            // botões passa da borda de baixo.
                            clipper: _SideClipper(),
                            // H-ANI-03: avançar entra pela direita; voltar,
                            // pela esquerda.
                            child: TransicaoEixoX(
                              voltar: !state.forward,
                              alinhamento: Alignment.topCenter,
                              child: Padding(
                                key: currentKey,
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.lg,
                                ),
                                // Cada passo é um quadro do canvas: a entrada
                                // (H-ANI-13/16) só roda na primeira visita.
                                child: EntradaDaTela(
                                  id: tourQuadro(step),
                                  child: switch (step) {
                                    TourStep.board => const _BoardStep(),
                                    TourStep.theme => const _ThemeStep(),
                                    TourStep.voice => _VoiceStep(state: state),
                                    TourStep.level => const TourLevelStep(),
                                    TourStep.region => const TourRegionStep(),
                                    TourStep.account => const TourAccountStep(),
                                  },
                                ),
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
          ),
        );
      },
    );
  }
}

/// O id do quadro do canvas de cada passo do tour.
String tourQuadro(TourStep step) => switch (step) {
  TourStep.board => 'PropV2TourBTabuleiro',
  TourStep.theme => 'PropV2TourBTema',
  TourStep.voice => 'PropV2TourBVoz',
  TourStep.level => 'PropV2TourBNivel',
  TourStep.region => 'PropV2TourBRegiao',
  TourStep.account => 'PropV2TourBConta',
};

String _speech(AppLocalizations l10n, TourState state) => switch (state.step) {
  TourStep.board => l10n.tourSpeechBoard,
  TourStep.voice =>
    state.linkSetupDone
        ? (state.hasVoices
              ? l10n.tourSpeechVoiceLink
              : l10n.tourSpeechVoiceLinkNone)
        : (state.hasVoices ? l10n.tourSpeechVoice : l10n.tourSpeechVoiceNone),
  TourStep.theme => l10n.tourSpeechTheme,
  TourStep.level => l10n.tourSpeechLevel,
  TourStep.region => l10n.tourSpeechRegion,
  TourStep.account => l10n.tourSpeechAccount,
};

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
    // O nível tem o "Continuar" dele; a conta, os botões dentro do passo.
    return switch (state.step) {
      TourStep.level => const TourLevelFooter(),
      TourStep.account => const SizedBox.shrink(),
      _ => ActionsFooter(
        children: [
          FilledButton(
            key: TourKeys.nextButton,
            onPressed: cubit.next,
            child: Text(l10n.tourNext),
          ),
        ],
      ),
    };
  }
}

/// 1. Cores e peças do tabuleiro, com uma amostra que muda na hora. Um
/// seletor "Cores | Peças" troca o carrossel de baixo.
class _BoardStep extends StatefulWidget {
  const _BoardStep();

  @override
  State<_BoardStep> createState() => _BoardStepState();
}

class _BoardStepState extends State<_BoardStep> {
  bool _pieces = false;

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
        // Tabuleiro de ponta a ponta, sem as letras e os números da borda.
        LayoutBuilder(
          builder: (context, constraints) => Center(
            child: BoardPreview(
              boardKey: TourKeys.boardPreview,
              size: constraints.maxWidth,
              board: board.copyWith(coordinates: false),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _sideInset),
          child: SegmentedButton<bool>(
            key: TourKeys.boardTabs,
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(l10n.tourTabColors, key: TourKeys.boardTabColors),
              ),
              ButtonSegment(
                value: true,
                label: Text(l10n.boardPieces, key: TourKeys.boardTabPieces),
              ),
            ],
            selected: {_pieces},
            onSelectionChanged: (value) =>
                setState(() => _pieces = value.first),
          ),
        ),
        if (_pieces)
          PieceStyleCarousel(
            selected: board.pieces,
            colors: board.colors,
            keyOf: TourKeys.boardPieces,
            onSelected: (pieces) =>
                settings.setBoard(board.copyWith(pieces: pieces)),
          )
        else
          BoardColorsCarousel(
            selected: board.colors,
            keyOf: TourKeys.boardColors,
            onSelected: (colors) =>
                settings.setBoard(board.copyWith(colors: colors)),
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

/// 2. O tema do app: do sistema, claro ou escuro (a mesma preferência das
/// Configurações).
class _ThemeStep extends StatelessWidget {
  const _ThemeStep();

  static const _gap = 8.0;

  Key _key(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => TourKeys.themeSystem,
    AppThemeMode.light => TourKeys.themeLight,
    AppThemeMode.dark => TourKeys.themeDark,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>();
    final selected = context.select(
      (SettingsCubit cubit) => cubit.state?.themeMode ?? AppThemeMode.system,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sideInset),
      child: Row(
        children: [
          for (final (i, mode) in AppThemeMode.values.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(
              child: VoiceCard(
                key: _key(mode),
                icon: mode.icon,
                label: mode.label(l10n),
                selected: selected == mode,
                onTap: () => settings.setThemeMode(mode),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 3. O nome do jogador e a voz do Viktor.
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
          const _TourVoiceGrid(),
          const SizedBox(height: AppSpacing.lg),
          _NameField(initial: state.nickname),
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
                      key: TourKeys.voiceCard(i + 1),
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
                    key: TourKeys.voiceNone,
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
