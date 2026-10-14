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
  /// A altura da faixa do Viktor: retrato 44 e 3 dp de folga (protótipo, 50).
  static const _stripHeight = 50.0;

  /// A altura mínima da lista de lances (§8 do contrato).
  static const _listMin = 88.0;

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
                icon: const Icon(Icons.menu_book_outlined),
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
    final text = state.speech.join(' ');
    Widget speech = ScriptSpeech(texts: state.speech, metrics: metrics);
    final voice = TeacherSpeech.speechOf(context);
    if (voice != null) {
      final sound = context.select((SettingsCubit c) => c.state?.sound ?? true);
      speech = AutoSpeak(
        speech: voice,
        text: text,
        auto: sound,
        speakerId: 'master',
        child: speech,
      );
    }
    return Column(
      children: [
        speech,
        SizedBox(
          key: LessonScriptKeys.characterBar,
          height: _stripHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _viktor == null
                ? null
                : TeacherSpeech(
                    part: TeacherSpeechPart.header,
                    lessonV2: true,
                    headerAvatar: 44,
                    teacher: _viktor!,
                    text: text,
                    speechContext: SpeechContext.teaching,
                    onSoundSettings: () => showLessonSoundDialog(context),
                  ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              // O tabuleiro cabe na largura e deixa a lista com ao menos
              // 88 dp; a sobra de altura é da lista.
              final size = math.max(
                0.0,
                math.min(box.maxWidth, box.maxHeight - _listMin),
              );
              return Column(
                children: [
                  Center(
                    child: ScriptBoard(
                      state: state,
                      size: size,
                      settings: settings,
                      onMove: (uci) => unawaited(cubit.onMove(uci)),
                    ),
                  ),
                  Expanded(
                    child: ScriptMoveList(
                      moves: state.moves,
                      currentId: state.currentMoveId,
                      onTap: cubit.goToMove,
                    ),
                  ),
                ],
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
    return ExerciseActions(
      hint: Tooltip(
        message: context.l10n.lessonPreviousStep,
        child: IconButton.outlined(
          key: LessonScriptKeys.back,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(56),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          icon: const Icon(Icons.arrow_back),
          onPressed: state.canBack ? cubit.back : null,
        ),
      ),
      actions: [?secondary, ?primary],
    );
  }
}
