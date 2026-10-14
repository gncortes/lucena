import 'dart:async';
import 'dart:math' as math;

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
import '../../core/widgets/exercise_actions.dart';
import '../../core/widgets/lesson_sound_dialog.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../voice/widgets/auto_speak.dart';
import '../view_models/lesson_script_cubit.dart';
import 'curiosities_sheet.dart';
import 'script_board.dart';
import 'script_move_list.dart';
import 'script_speech.dart';
import 'script_speech_sheet.dart';

/// A tela da lição roteirizada (T70): as três etapas da parte são variações
/// desta mesma tela. De cima para baixo: a barra, o balão do Viktor, a faixa
/// dele, o tabuleiro, a lista de lances e o rodapé.
class LessonScriptScreen extends StatefulWidget {
  const LessonScriptScreen({this.title, super.key});

  /// O nome da parte, que vai na barra.
  final Future<String?>? title;

  @override
  State<LessonScriptScreen> createState() => _LessonScriptScreenState();
}

class _LessonScriptScreenState extends State<LessonScriptScreen> {
  /// A altura da faixa do Viktor: retrato 40, nos botões de 48 dp do lado
  /// (protótipo, 50).
  static const _stripHeight = 50.0;

  /// A folga entre o bico do balão e o retrato (Gabriel, 14/10/2026).
  static const _tailGap = 6.0;

  /// Na tela baixa, a folga mínima entre o tabuleiro e o rodapé.
  static const _compactGap = 4.0;

  Character? _viktor;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadViktor());
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
      unawaited(cubit.start());
    }
  }

  void _onState(BuildContext context, LessonScriptState state) {
    final outcome = state.outcome;
    if (outcome == null) return;
    final cubit = context.read<LessonScriptCubit>();
    final next = outcome.nextPart;
    if (next == null) {
      context.go(Routes.endgameLesson(cubit.lessonId));
    } else {
      context.pushReplacement(
        Routes.endgameLessonSteps(cubit.lessonId, part: next),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LessonScriptCubit>();
    return BlocConsumer<LessonScriptCubit, LessonScriptState>(
      listenWhen: (a, b) => a.outcome != b.outcome,
      listener: _onState,
      builder: (context, state) => Scaffold(
        key: LessonScriptKeys.screen,
        appBar: LucenaAppBar(
          title: FutureBuilder<String?>(
            future: widget.title,
            builder: (context, snapshot) => Text(snapshot.data ?? ''),
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
          child: state.ready ? _body(context, cubit, state) : const SizedBox(),
        ),
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
    final metrics = ScriptSpeechMetrics.of(context);
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final marks = context.select(
      (SettingsCubit c) => c.state?.lessonMarks ?? true,
    );
    final text = ScriptSpeech.plainOf(context, state.speech.join(' '));
    // Todo botão citado na fala é link e faz o mesmo que ele, enquanto o
    // botão está no rodapé (Gabriel, 14/10/2026).
    VoidCallback? link(ScriptAction action) =>
        state.primary == action || state.secondary == action
        ? () => unawaited(cubit.onAction(action))
        : null;
    final onMainLine = link(ScriptAction.linhaPrincipal);
    final onShowAnswer = link(ScriptAction.verResposta);
    final viktor = _viktor;
    // O clique no balão abre a fala inteira, sempre.
    final onOpen = viktor == null || state.machineThinking
        ? null
        : () => unawaited(
            showScriptSpeechSheet(
              context,
              viktor: viktor,
              texts: state.speech,
              onMainLine: onMainLine,
              onShowAnswer: onShowAnswer,
            ),
          );
    final voice = TeacherSpeech.speechOf(context);
    final sound = context.select((SettingsCubit c) => c.state?.sound ?? true);
    Widget speechOf(int? lines) {
      Widget speech = ScriptSpeech(
        texts: state.speech,
        metrics: metrics,
        lines: lines,
        typing: state.machineThinking,
        onMainLine: onMainLine,
        onShowAnswer: onShowAnswer,
        onOpen: onOpen,
      );
      if (voice != null) {
        speech = AutoSpeak(
          speech: voice,
          text: text,
          auto: sound,
          speakerId: 'master',
          child: speech,
        );
      }
      return speech;
    }

    final strip = SizedBox(
      key: LessonScriptKeys.characterBar,
      height: _stripHeight + _tailGap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, _tailGap, 12, 0),
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
    Widget board(double size) => ScriptBoard(
      state: state,
      size: size,
      settings: settings,
      showMarks: marks,
      onMove: (uci) => unawaited(cubit.onMove(uci)),
    );
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              // O tabuleiro tem um tamanho só: a largura cheia, desde que
              // caiba com a fala de duas linhas e o retrato acima; nunca
              // encolhe para centralizar nem para mostrar a lista. Na tela
              // baixa, o maior possível, e a lista fica abaixo da dobra
              // (Gabriel, 14/10/2026; canvas `T70-etapa1-estados`).
              final above =
                  metrics.top +
                  metrics.minHeight(context) +
                  ScriptSpeech.tailSize.height +
                  _stripHeight +
                  _tailGap;
              final room =
                  box.maxHeight - above - (metrics.compact ? _compactGap : 0);
              final size = math.max(0.0, math.min(box.maxWidth, room));
              // A fala vai até 4 linhas, ou mais se couberem acima do
              // tabuleiro centralizado; depois a letra desce até 12 sp e,
              // só então, o tabuleiro desce o necessário.
              final bubbleRoom =
                  (box.maxHeight - size) / 2 -
                  _stripHeight -
                  _tailGap -
                  ScriptSpeech.tailSize.height -
                  ScriptSpeechMetrics.minTop -
                  2 * metrics.verticalPadding;
              final lines = metrics.compact
                  ? null
                  : math.max(
                      metrics.maxLines,
                      (bubbleRoom / metrics.lineExtent(context)).floor(),
                    );
              // Centralizado na altura sempre que dá; a fala sobe no espaço
              // de cima e só empurra o tabuleiro quando não cabe ali. A
              // tela toda rola, sem barra, quando a lista passa do fundo
              // (Gabriel, 14/10/2026; canvas `T70-etapa1-estados`, R1/R2).
              return SingleChildScrollView(
                key: LessonScriptKeys.page,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (box.maxHeight - size) / 2,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(children: [speechOf(lines), strip]),
                        ),
                      ),
                      Center(child: board(size)),
                      ScriptMoveList(
                        moves: state.moves,
                        currentId: state.currentMoveId,
                        onTap: cubit.goToMove,
                      ),
                    ],
                  ),
                ),
              );
            },
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
    return ExerciseActions(
      // Mesmo fundo da tela, só com a linha em cima (Gabriel, 14/10/2026;
      // canvas `T70-etapa1-estados`, F2).
      color: Theme.of(context).scaffoldBackgroundColor,
      // O voltar redondo da lição (`lesson_screen.dart`, Gabriel 14/10/2026):
      // só aparece quando há para onde voltar.
      hint: state.canBack
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
          : null,
      actions: [?secondary, ?primary],
    );
  }
}
