import '../../../domain/models/survey.dart';

import 'dart:async';

import '../../../domain/models/lesson_content.dart';
import '../../core/widgets/empty_state.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson_script.dart';
import '../../../routing/routes.dart';
import '../../core/keys/lesson_script_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/exercise_actions.dart';
import '../../core/widgets/game_board_hero.dart';
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/script_speech_sheet.dart';
import '../../core/widgets/speech_balloon.dart';
import '../../core/widgets/square_flash.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../../voice/view_models/speech_cubit.dart';
import '../view_models/lesson_script_cubit.dart';
import 'curiosities_sheet.dart';
import 'script_demo_controls.dart';
import 'script_board.dart';
import 'script_move_list.dart';
import 'script_page.dart';
import 'script_speech.dart';

/// A tela da lição roteirizada (T70): as três etapas da parte são variações
/// desta mesma tela. De cima para baixo: a barra, o balão do Viktor, a faixa
/// dele, o tabuleiro, a lista de lances e o rodapé.
class LessonScriptScreen extends StatefulWidget {
  const LessonScriptScreen({
    this.title,
    this.preview,
    this.previewTeacher,
    this.previewTitle,
    this.homeHero = false,
    super.key,
  });

  /// O nome da parte, que vai na barra.
  final Future<String?>? title;
  final LessonScriptState? preview;
  final Character? previewTeacher;
  final String? previewTitle;
  final bool homeHero;

  @override
  State<LessonScriptScreen> createState() => _LessonScriptScreenState();
}

class _LessonScriptScreenState extends State<LessonScriptScreen>
    with WidgetsBindingObserver {
  /// Reserva também os 4 dp do anel em cada lado do botão principal.
  /// Fica igual aos controles de demonstração, mesmo quando eles saem.
  static const _footerContentHeight = ScriptDemoButton.mainSize + AppSpacing.sm;

  Character? _viktor;
  bool _started = false;
  bool _leaving = false;
  bool _canPop = false;
  bool _contentUnavailable = false;

  Future<void> _startContent(LessonScriptCubit cubit) async {
    try {
      await cubit.start();
    } on LessonContentUnavailable {
      cubit.unavailable();
      if (mounted) setState(() => _contentUnavailable = true);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      // A missing download must not change an existing saved checkpoint.
      if (!_contentUnavailable) {
        await context.read<LessonScriptCubit>().leave();
      }
    } catch (_) {
      _leaving = false;
      if (mounted) {
        showLucenaSnackBar(context, context.l10n.lessonSaveRetry);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _canPop = true);
    // O PopScope precisa receber canPop antes da segunda tentativa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  /// A casa que o aluno tocou na fala, realçada no tabuleiro.
  final _flash = SquareFlash();

  @override
  void initState() {
    super.initState();
    _viktor = widget.previewTeacher;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadViktor());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flash.dispose();
    super.dispose();
  }

  bool _background = false;

  /// Segundo plano mantém tudo: a demonstração e a voz param onde estão e
  /// seguem na volta.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _background) return;
    _background = background;
    final cubit = context.read<LessonScriptCubit>();
    final speech = TeacherSpeech.speechOf(context);
    if (background) {
      cubit.pauseForBackground();
      unawaited(speech?.pauseForBackground());
    } else {
      cubit.resumeFromBackground();
      unawaited(speech?.resumeFromBackground());
    }
  }

  Future<void> _loadViktor() async {
    final all = await context.read<CharacterRepository>().characters();
    if (!mounted) return;
    for (final character in all) {
      if (character.id == 'master') setState(() => _viktor = character);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = context.read<LessonScriptCubit>();
    final width = MediaQuery.sizeOf(context).width;
    final metrics = ScriptSpeechMetrics.of(context);
    // A tela diz ao Cubit se os balões cabem; antes de abrir, para o 1º
    // trecho já vir junto.
    cubit.setSpeechFits((texts) => metrics.fits(context, width, texts));
    if (!_started) {
      _started = true;
      unawaited(_startContent(cubit));
    }
  }

  void _onState(BuildContext context, LessonScriptState state) {
    final outcome = state.outcome;
    if (outcome == null) return;
    final cubit = context.read<LessonScriptCubit>();
    // Escola (curso de iniciante, T71): a próxima aula do curso, ou a
    // escola na última.
    if (!cubit.endgame) {
      final lesson = outcome.next;
      if (lesson == null || outcome.last) {
        // A Escola concluída: os próximos passos.
        context.go(Routes.nextStepsSchool);
      } else {
        // A aula concluída, com o convite "Sua opinião" e a próxima aula.
        context.pushReplacement(
          Routes.lessonFinished(
            SurveyKind.school,
            cubit.lessonId,
            next: lesson,
            origin: cubit.origin,
          ),
        );
      }
      return;
    }
    final next = outcome.nextPart;
    if (next == null) {
      // Os capítulos todos feitos: a aula concluída, antes do teste final.
      context.pushReplacement(
        Routes.lessonFinished(
          SurveyKind.endgames,
          cubit.lessonId,
          next: outcome.next,
          origin: cubit.origin,
        ),
      );
    } else {
      context.pushReplacement(
        Routes.endgameLessonScript(
          cubit.lessonId,
          part: next,
          origin: cubit.origin,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LessonScriptCubit>();
    final screen = BlocConsumer<LessonScriptCubit, LessonScriptState>(
      listenWhen: (a, b) => a.outcome != b.outcome,
      listener: _onState,
      builder: (context, state) => Scaffold(
        key: LessonScriptKeys.screen,
        appBar: LucenaAppBar(
          leading: ModalRoute.of(context)?.canPop == true
              ? const BackButton(key: LessonScriptKeys.close)
              : null,
          // Exceção de D2 só na lição: o livro de Curiosidades só aparece
          // na posição que tem curiosidade, e o título fica à esquerda em
          // todas as etapas, com ou sem ele, para não pular (Gabriel,
          // 14/10/2026; canvas `T70-etapa1-estados`).
          centerTitle: false,
          title: FutureBuilder<String?>(
            future: widget.title,
            initialData: widget.previewTitle,
            builder: (context, snapshot) => Text(
              snapshot.data?.isNotEmpty == true
                  ? snapshot.data!
                  : widget.previewTitle ?? '',
            ),
          ),
          actions: [
            if (state.curiosities != null)
              IconButton(
                key: LessonScriptKeys.bookButton,
                tooltip: context.l10n.curiositiesTitle,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.auto_stories_outlined),
                onPressed: () => _openCuriosities(context, state.curiosities!),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _contentUnavailable
              ? Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: EmptyState(
                      icon: Icons.auto_stories_outlined,
                      message: context.l10n.lessonsUnavailableMessage,
                    ),
                  ),
                )
              : state.ready || widget.preview != null
              ? IgnorePointer(
                  ignoring: !state.ready,
                  child: _body(
                    context,
                    cubit,
                    state.ready ? state : widget.preview!,
                  ),
                )
              : const SizedBox(),
        ),
      ),
    );
    // Outro passo (posição ou fala nova): a casa marcada pela fala sai.
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: BlocListener<LessonScriptCubit, LessonScriptState>(
        listenWhen: (a, b) => a.fen != b.fen || !listEquals(a.speech, b.speech),
        listener: (_, _) => _flash.clear(),
        child: screen,
      ),
    );
  }

  void _openCuriosities(BuildContext context, ScriptCuriosities data) {
    // A folha lê a chave de fala; as falas já vêm resolvidas no estado.
    const text = 'curiosities.text';
    const quote = 'curiosities.quote';
    unawaited(
      showCuriositiesSheet(
        context,
        Curiosities(
          t: text,
          quote: data.quote == null ? null : quote,
          quoteAuthor: data.quoteAuthor,
          references: [
            for (final ref in data.references) CuriosityRef(inline: ref),
          ],
        ),
        texts: ScriptTexts({text: data.text, quote: ?data.quote}),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    LessonScriptCubit cubit,
    LessonScriptState state,
  ) {
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final marks = context.select(
      (SettingsCubit c) => c.state?.lessonMarks ?? true,
    );
    final text = SpeechText.plainOf(context, state.speech.join(' '));
    // Todo botão citado na fala é link e faz o mesmo que ele, enquanto o
    // botão está no rodapé (Gabriel, 14/10/2026).
    VoidCallback? link(ScriptAction action) =>
        state.primary == action || state.secondary == action
        ? () => unawaited(cubit.onAction(action))
        : null;
    final onMainLine = link(ScriptAction.linhaPrincipal);
    final onShowAnswer = link(ScriptAction.verResposta);
    final viktor = _viktor;
    final voice = TeacherSpeech.speechOf(context);
    final sound = context.select((SettingsCubit c) => c.state?.sound ?? true);
    // O clique no balão abre a fala inteira, sempre.
    final onOpen = viktor == null || state.machineThinking
        ? null
        : () => unawaited(
            showScriptSpeechSheet(
              context,
              viktor: viktor,
              title: context.l10n.teacherName(viktor.name),
              texts: state.speech,
              onMainLine: onMainLine,
              onShowAnswer: onShowAnswer,
              onSquareTap: _flash.show,
              // O som da aula, como na faixa do Viktor (T84).
              action: LessonVoiceButton(
                audible:
                    sound &&
                    (voice?.state.settings.enabled ?? false) &&
                    (voice?.state.availableFor(
                          Localizations.localeOf(context).toLanguageTag(),
                        ) ??
                        false),
                speed: voice?.state.settings.speed ?? 1,
                onPressed: () => showLessonSoundDialog(context),
              ),
            ),
          );
    Widget speechOf(ScriptSpeechMetrics metrics) {
      Widget speech = ScriptSpeech(
        texts: state.speech,
        metrics: metrics,
        typing: state.machineThinking,
        onMainLine: onMainLine,
        onShowAnswer: onShowAnswer,
        onSquareTap: _flash.show,
        onOpen: onOpen,
      );
      if (voice != null && cubit.state.ready) {
        speech = AutoSpeak(
          speech: voice,
          text: text,
          auto: sound,
          speakerId: 'master',
          child: speech,
        );
        // Na demonstração, o passo espera a voz dizer a fala dele; sem som
        // ou sem voz, vale o tempo de leitura.
        speech = BlocListener<SpeechCubit, SpeechState>(
          bloc: voice,
          listenWhen: (a, b) =>
              a.speaking != b.speaking || a.settings != b.settings,
          listener: (context, speaking) => cubit.demoVoice(
            speaking:
                sound && speaking.settings.enabled && speaking.isSpeaking(text),
          ),
          child: speech,
        );
      }
      return speech;
    }

    final strip = SizedBox(
      key: LessonScriptKeys.characterBar,
      height: ScriptPage.stripHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: viktor == null
            ? null
            : TeacherSpeech(
                part: TeacherSpeechPart.header,
                lessonV2: true,
                headerAvatar: 40,
                avatarHeroTag: scriptViktorHeroTag,
                teacher: viktor,
                text: text,
                speechContext: SpeechContext.teaching,
                onSoundSettings: () => showLessonSoundDialog(context),
                // Ao lado do som: mostrar ou esconder as marcações.
                headerAction: IconButton(
                  key: LessonScriptKeys.marksToggle,
                  tooltip: marks
                      ? context.l10n.lessonHideMarks
                      : context.l10n.lessonShowMarks,
                  isSelected: marks,
                  icon: const Icon(Icons.layers_clear_outlined),
                  selectedIcon: const Icon(Icons.layers_outlined),
                  onPressed: () => context.read<SettingsCubit>().setLessonMarks(
                    shown: !marks,
                  ),
                ),
              ),
      ),
    );
    Widget board(double size) {
      final board = ScriptBoard(
        state: state,
        size: size,
        settings: settings,
        showMarks: marks,
        flash: _flash,
        onMove: (uci) => unawaited(cubit.onMove(uci)),
        onSquare: (square) => unawaited(cubit.onSquare(square)),
      );
      return widget.homeHero
          ? GameBoardHero(orientation: state.orientation, child: board)
          : board;
    }

    return Column(
      children: [
        Expanded(
          child: ScriptPage(
            pageKey: LessonScriptKeys.page,
            speechBuilder: speechOf,
            strip: strip,
            boardBuilder: board,
            list: ScriptMoveList(
              moves: state.moves,
              currentId: state.currentMoveId,
              onTap: cubit.goToMove,
            ),
          ),
        ),
        _footer(context, cubit, state),
      ],
    );
  }

  ExerciseAction? _action(
    BuildContext context,
    LessonScriptCubit cubit,
    ScriptAction? action, {
    required bool primary,
  }) {
    if (action == null) return null;
    final l10n = context.l10n;
    final (label, key) = switch (action) {
      ScriptAction.continuar => (l10n.lessonContinue, LessonScriptKeys.primary),
      ScriptAction.proximaEtapa => (
        l10n.lessonNextStage,
        LessonScriptKeys.primary,
      ),
      ScriptAction.tentarDeNovo => (l10n.lessonRetry, LessonScriptKeys.primary),
      ScriptAction.voltarInicio => (
        l10n.lessonBackToStart,
        LessonScriptKeys.primary,
      ),
      ScriptAction.verResposta => (
        l10n.lessonShowAnswer,
        LessonScriptKeys.showAnswer,
      ),
      ScriptAction.linhaPrincipal => (
        l10n.lessonMainLine,
        LessonScriptKeys.mainLine,
      ),
      ScriptAction.reverIdeia => (
        l10n.lessonReviewIdea,
        LessonScriptKeys.reviewIdea,
      ),
      ScriptAction.proximaParte => (
        l10n.lessonContinue,
        LessonScriptKeys.nextPart,
      ),
    };
    return ExerciseAction(
      label: label,
      key: key,
      primary: primary,
      onPressed: () => unawaited(cubit.onAction(action)),
    );
  }

  Widget _footer(
    BuildContext context,
    LessonScriptCubit cubit,
    LessonScriptState state,
  ) {
    final secondary = _action(context, cubit, state.secondary, primary: false);
    final primary = _action(context, cubit, state.primary, primary: true);
    final colors = Theme.of(context).colorScheme;
    final demo = state.demo;
    // Demonstração (etapa 2): ↻ ⏮ ⏸/▶ e o ⏭ com o anel no lugar dos
    // botões; no fim, só ↻ e o botão principal (canvas, E12). Teoria (etapa
    // 1): nas falas de "Continuar", ⏸/▶ e o ⏭ com o anel.
    final repeat = ScriptDemoButton(
      buttonKey: LessonScriptKeys.demoRepeat,
      icon: Icons.replay_rounded,
      tooltip: context.l10n.lessonDemoReplay,
      onPressed: () => unawaited(cubit.demoRepeat()),
    );
    final controls = demo == null || demo.ended || primary == null
        ? null
        : ScriptDemoControls(
            playing: demo.playing,
            speaking: demo.speaking,
            full: demo.full,
            progress: demo.progress,
            remaining: demo.remaining,
            tick: demo.tick,
            canStepBack: demo.canStepBack,
            mainTooltip: primary.label,
            onRepeat: () => unawaited(cubit.demoRepeat()),
            onStepBack: cubit.demoStepBack,
            onToggle: cubit.demoToggle,
            onNext: () => primary.onPressed?.call(),
          );
    final back = state.canBack
        ? FloatingActionButton(
            key: LessonScriptKeys.back,
            heroTag: null,
            shape: const CircleBorder(),
            elevation: 2,
            backgroundColor: colors.surface,
            foregroundColor: colors.primary,
            tooltip: context.l10n.lessonPreviousStep,
            onPressed: cubit.back,
            child: const Icon(Icons.arrow_back),
          )
        : null;
    return ExerciseActions(
      // Mesmo fundo da tela, sem linha em cima (Gabriel, 14/10/2026).
      color: Theme.of(context).scaffoldBackgroundColor,
      // O voltar redondo da lição (`lesson_screen.dart`, Gabriel 14/10/2026):
      // só aparece quando há para onde voltar.
      // Com ou sem controles, guarda também a altura do anel: o tabuleiro
      // não pula ao terminar/repetir a demonstração ou trocar de fase.
      hint: controls == null
          ? SizedBox(
              height: _footerContentHeight,
              child: back == null ? null : Center(child: back),
            )
          : Expanded(child: Row(children: [?back, const Spacer(), controls])),
      leading: demo != null && demo.ended ? repeat : null,
      hug: true,
      actions: controls == null ? [?secondary, ?primary] : const [],
    );
  }
}
