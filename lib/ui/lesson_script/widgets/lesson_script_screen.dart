import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_colors.dart';
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
import '../../core/theme/app_button_text.dart';
import '../../core/theme/canvas_symbols.dart';
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
    this.onAnalyze,
    super.key,
  });

  /// O nome da parte, que vai na barra.
  final Future<String?>? title;
  final LessonScriptState? preview;
  final Character? previewTeacher;
  final String? previewTitle;
  final bool homeHero;
  final ValueChanged<String>? onAnalyze;

  @override
  State<LessonScriptScreen> createState() => _LessonScriptScreenState();
}

class _LessonScriptScreenState extends State<LessonScriptScreen>
    with WidgetsBindingObserver {
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
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router?.canPop() == true) {
        router!.pop();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        router?.go(Routes.home);
      }
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
    final media = MediaQuery.of(context);
    final region =
        media.size.height -
        media.padding.vertical -
        64 -
        96 -
        (cubit.endgame ? 0 : 12);
    var lines = 2;
    for (final candidate in [(4, 40), (3, 40), (2, 40), (2, 0)]) {
      if (region >= 42 + 22.5 * candidate.$1 + 58 + width + candidate.$2) {
        lines = candidate.$1;
        break;
      }
    }
    final metrics = ScriptSpeechMetrics.canvas(lines);
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
          leading: IconButton(
            key: LessonScriptKeys.close,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => unawaited(_leave()),
            icon: const Icon(CanvasSymbols.arrowBack),
          ),
          toolbarHeight: 64,
          centerTitle: state.curiosities == null,
          title: FutureBuilder<String?>(
            future: widget.title,
            initialData: widget.previewTitle,
            builder: (context, snapshot) => Text(
              snapshot.data?.isNotEmpty == true
                  ? snapshot.data!
                  : widget.previewTitle ?? '',
              maxLines: 2,
              textWidthBasis: TextWidthBasis.longestLine,
              overflow: TextOverflow.ellipsis,
              textAlign: state.curiosities == null
                  ? TextAlign.center
                  : TextAlign.start,
              style: const TextStyle(fontSize: 22, height: 28 / 22),
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
              : cubit.practiceIssue != null
              ? Center(
                  child: EmptyState(
                    style: EmptyStateStyle.error,
                    icon: Icons.error_outline,
                    message:
                        cubit.practiceIssue ==
                            ScriptPracticeIssue.opponentUnavailable
                        ? context.l10n.practiceOpponentUnavailable
                        : context.l10n.practiceSolutionUnavailable,
                    actionLabel: context.l10n.lessonRetry,
                    actionKey: LessonScriptKeys.primary,
                    onAction: () => unawaited(cubit.retryPracticeIssue()),
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
    final savedMarks = context.select(
      (SettingsCubit c) => c.state?.lessonMarks ?? true,
    );
    // The explicit solution must remain visible without rewriting preferences.
    final marks = savedMarks || cubit.showingPracticeSolution;
    final texts =
        cubit.showingPracticeSolution &&
            (state.touching || state.arrows.isNotEmpty)
        ? [
            state.touching
                ? context.l10n.practiceSolutionTarget
                : context.l10n.practiceSolutionFollow,
          ]
        : state.speech;
    final text = SpeechText.plainOf(context, texts.join(' '));
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
              canvasLayout: true,
              viktor: viktor,
              title: context.l10n.teacherName(viktor.name),
              texts: texts,
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
        texts: texts,
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
      height: ScriptPage.canvasStripHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: viktor == null
            ? null
            : TeacherSpeech(
                part: TeacherSpeechPart.header,
                lessonV2: true,
                canvasHeader: true,
                headerAvatar: 40,
                avatarHeroTag: scriptViktorHeroTag,
                teacher: viktor,
                text: text,
                speechContext: SpeechContext.teaching,
                onSoundSettings: () => showLessonSoundDialog(context),
                // Ao lado do som: mostrar ou esconder as marcações.
                headerAction: SizedBox.square(
                  dimension: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -4,
                        top: -4,
                        width: 48,
                        height: 48,
                        child: IconButton(
                          key: LessonScriptKeys.marksToggle,
                          tooltip: marks
                              ? context.l10n.lessonHideMarks
                              : context.l10n.lessonShowMarks,
                          isSelected: marks,
                          icon: const Icon(CanvasSymbols.layersClear),
                          selectedIcon: const Icon(CanvasSymbols.layers),
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(48),
                            minimumSize: const Size.square(48),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: cubit.showingPracticeSolution
                              ? null
                              : () => context
                                    .read<SettingsCubit>()
                                    .setLessonMarks(shown: !savedMarks),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
    Widget board(double size) {
      final board = ScriptBoard(
        canvasFeedback: true,
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

    return LayoutBuilder(
      builder: (context, box) {
        final progressHeight = !cubit.endgame && cubit.progressSteps > 0
            ? 12.0
            : 0.0;
        final geometry = ScriptCanvasMetrics.forSize(
          Size(
            box.maxWidth,
            (box.maxHeight - 96 - progressHeight)
                .clamp(0, double.infinity)
                .toDouble(),
          ),
        );
        // Canvas list padding is 4 + 8 dp above choices. At least 44 dp of
        // each response must remain hittable within the page, below the board.
        final choicesInFooter =
            cubit.answerChoices.isNotEmpty &&
            geometry.availableListHeight < 12 + 44;
        return Column(
          children: [
            if (!cubit.endgame && cubit.progressSteps > 0)
              Semantics(
                label: context.l10n.tourStep(
                  cubit.progressValue.ceil(),
                  cubit.progressSteps,
                ),
                child: Padding(
                  key: LessonScriptKeys.progress,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      for (var i = 0; i < cubit.progressSteps; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppShape.tiny),
                            child: LinearProgressIndicator(
                              value: (cubit.progressValue - i)
                                  .clamp(0, 1)
                                  .toDouble(),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(
                                AppShape.tiny,
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ScriptPage(
                canvasLayout: true,
                actionsBelowBoard:
                    cubit.answerChoices.isNotEmpty && !choicesInFooter,
                pageKey: LessonScriptKeys.page,
                speechBuilder: speechOf,
                strip: strip,
                boardBuilder: board,
                list: cubit.answerChoices.isNotEmpty
                    ? choicesInFooter
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: _answerChoices(cubit),
                            )
                    : ScriptMoveList(
                        moves: state.moves,
                        currentId:
                            !cubit.endgame &&
                                state.phase == ScriptPhase.praticaFim
                            ? null
                            : state.currentMoveId,
                        onTap: cubit.goToMove,
                      ),
              ),
            ),
            _footer(context, cubit, state, choicesInFooter: choicesInFooter),
          ],
        );
      },
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
        cubit.endgame ? stateLabel(cubit.state, context) : l10n.lessonContinue,
        LessonScriptKeys.primary,
      ),
      ScriptAction.tentarDeNovo => (l10n.lessonRetry, LessonScriptKeys.primary),
      ScriptAction.voltarInicio => (
        l10n.lessonBackToStart,
        LessonScriptKeys.primary,
      ),
      ScriptAction.verResposta => (
        l10n.trainingSeeSolution,
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
      label:
          action == ScriptAction.continuar &&
              cubit.state.stageId == 'demos' &&
              cubit.state.phase == ScriptPhase.fimExemplo
          ? l10n.lessonNextModelGame
          : label,
      key: key,
      primary: primary,
      onPressed: () => unawaited(cubit.onAction(action)),
    );
  }

  Widget _answerChoices(LessonScriptCubit cubit) => Row(
    spacing: 12,
    children: [
      for (final (index, label) in cubit.answerChoices.indexed)
        Expanded(
          child: SizedBox(
            height: kButtonHeight,
            child: OutlinedButton(
              key: LessonScriptKeys.answerChoice(index),
              onPressed: () => unawaited(cubit.answerChoice(index)),
              child: Text(label),
            ),
          ),
        ),
    ],
  );

  String stateLabel(LessonScriptState state, BuildContext context) =>
      switch (state.stageId) {
        'ideia' => context.l10n.lessonModelGames,
        'demos' => context.l10n.trainingPartPractice,
        _ => context.l10n.lessonNextStage,
      };

  Widget _footer(
    BuildContext context,
    LessonScriptCubit cubit,
    LessonScriptState state, {
    bool choicesInFooter = false,
  }) {
    final secondary = _action(context, cubit, state.secondary, primary: false);
    final primary = _action(context, cubit, state.primary, primary: true);
    final demo = state.demo;
    // Demonstração (etapa 2): ↻ ⏮ ⏸/▶ e o ⏭ com o anel no lugar dos
    // botões; no fim, só ↻ e o botão principal (canvas, E12). Teoria (etapa
    // 1): nas falas de "Continuar", ⏸/▶ e o ⏭ com o anel.
    final repeat = ScriptDemoButton(
      buttonKey: LessonScriptKeys.demoRepeat,
      icon: CanvasSymbols.replay,
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
            canvasLayout: true,
          );
    final back = state.canBack && state.stageId != 'pratica'
        ? _CanvasLessonFab(
            key: LessonScriptKeys.back,
            tooltip: context.l10n.lessonPreviousStep,
            onPressed: cubit.back,
            child: const Icon(CanvasSymbols.arrowBack),
          )
        : null;
    Widget actionButton(ExerciseAction action) {
      final style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(0, kButtonHeightCompact),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 384 ? 12 : 22,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          AppButtonText.footer(context)?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            letterSpacing: .1,
          ),
        ),
      );
      final label = Text(
        action.label,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      return action.primary
          ? FilledButton(
              key: action.key,
              style: style,
              onPressed: action.onPressed,
              child: label,
            )
          : OutlinedButton(
              key: action.key,
              style: style,
              onPressed: action.onPressed,
              child: label,
            );
    }

    if (choicesInFooter) {
      return SizedBox(
        key: LessonScriptKeys.footer,
        height: 96,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _answerChoices(cubit),
        ),
      );
    }
    return SizedBox(
      key: LessonScriptKeys.footer,
      height: 96,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          spacing: 12,
          children: [
            ?back,
            if (cubit.canHint)
              _CanvasLessonFab(
                key: LessonScriptKeys.hint,
                tooltip: context.l10n.lessonHint,
                onPressed: () => unawaited(cubit.hint()),
                child: const Icon(CanvasSymbols.lightbulb),
              ),
            if (cubit.canAnalyze && widget.onAnalyze != null)
              _CanvasLessonFab(
                key: LessonScriptKeys.analyze,
                tooltip: context.l10n.lessonAnalyzePosition,
                onPressed: () => widget.onAnalyze!(state.fen),
                child: const Icon(CanvasSymbols.search),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    controls ??
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        if (demo?.ended == true) repeat,
                        if (secondary != null)
                          Flexible(child: actionButton(secondary)),
                        if (primary != null)
                          Flexible(child: actionButton(primary)),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasLessonFab extends StatelessWidget {
  const _CanvasLessonFab({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    super.key,
  });
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.trainingFabShadowUmbra,
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: AppColors.trainingFabShadowPenumbra,
          offset: Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Material(
      color: AppColors.trainingFabSurface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(56),
          minimumSize: const Size.square(56),
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        icon: child,
      ),
    ),
  );
}
