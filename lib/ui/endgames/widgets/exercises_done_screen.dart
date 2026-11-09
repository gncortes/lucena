import '../../core/motion/entrada_de_resultado.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_colors.dart';

import 'package:flutter/material.dart';

import '../../core/widgets/skeleton.dart';

import 'endgame_load_error.dart';

import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/use_cases/now.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/share/share_button.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/widgets/about_screen.dart';
import '../view_models/endgame_lesson_cubit.dart';
import 'grade_widgets.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/keys/test_canvas_keys.dart';
import '../../core/theme/canvas_symbols.dart';
import 'exercises_intro_screen.dart' show TestCanvasMedal;

/// O resultado dos exercícios de uma aula de final, depois do último: a
/// medalha da faixa, a nota e, com a aula aprovada, o diploma.
class ExercisesDoneScreen extends StatefulWidget {
  const ExercisesDoneScreen({super.key});

  @override
  State<ExercisesDoneScreen> createState() => _ExercisesDoneScreenState();
}

class _ExercisesDoneScreenState extends State<ExercisesDoneScreen> {
  // O diploma que vira imagem ao compartilhar.
  final _card = GlobalKey();
  bool _redoing = false;

  Future<void> _redoTest(String lessonId) async {
    if (_redoing) return;
    _redoing = true;
    final cubit = context.read<EndgameLessonCubit>();
    final router = GoRouter.of(context);
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          await cubit.redoExercises();
          if (mounted) {
            router.pushReplacement(Routes.endgameExercisesIntro(lessonId));
          }
          return;
        } on Object {
          if (!mounted) return;
          if (attempt == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
            );
            await Future<void>.delayed(AppMotion.persistenceRetry);
          }
        }
      }
    } finally {
      _redoing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<EndgameLessonCubit>().state;
    if (endgameLoadError(context, state) case final error?) return error;
    if (state.lesson == null) {
      return const Scaffold(body: SafeArea(child: SkeletonList()));
    }
    final grade = state.grade;
    if (state.lesson!.id.startsWith('pilares.')) {
      return _PilaresResult(state: state, redo: _redoTest);
    }
    final below = grade == ExerciseGrade.below;
    final practice = state.lesson!.practice;
    return Scaffold(
      key: ExercisesDoneKeys.screen,
      // Compartilhar o diploma: só o ícone, no canto da barra.
      appBar: LucenaAppBar(
        leading: IconButton(
          key: ExercisesDoneKeys.close,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!below)
            ShareIconButton(
              key: ExercisesDoneKeys.share,
              boundary: _card,
              tooltip: l10n.graduationShare,
              // A marca embaixo da imagem, como no diploma da escola.
              footer: 'Lucena · ${l10n.homeTagline}',
              fileName: 'lucena-${state.lesson!.id}.png',
              text: l10n.exercisesDoneShareText(
                state.texts.lessonTitle(state.lesson!.id),
                state.score,
                state.maxScore,
                AboutScreen.websiteFor(
                  Localizations.localeOf(context).languageCode,
                ).toString(),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.screen,
                  top: AppSpacing.sm,
                  right: AppSpacing.screen,
                  bottom: AppSpacing.lg,
                ),
                children: [
                  // Passou: a medalha, a faixa, os pontos e o diploma são a
                  // imagem que vai no compartilhar.
                  if (!below)
                    _ShareCard(cardKey: _card, state: state, grade: grade)
                  else ...[
                    GradeMedal(grade: grade),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.endgameFailedTitle,
                      textAlign: TextAlign.center,
                      style: context.bigNumber,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.exercisesDoneScore(state.score, state.maxScore),
                      key: ExercisesDoneKeys.score,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (below) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.exercisesDoneNeedMore(state.passScore),
                      key: ExercisesDoneKeys.needMore,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    // O Viktor anima a tentar de novo.
                    if (state.viktor case final viktor?) ...[
                      const SizedBox(height: AppSpacing.xl),
                      TeacherSpeech(
                        key: ExercisesDoneKeys.retrySpeech,
                        speechContext: SpeechContext.teaching,
                        teacher: viktor,
                        text: l10n.exercisesDoneRetrySpeech,
                        emotion: Emotion.calm,
                        avatarSize: CharacterAvatar.speech,
                        speaks: true,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            _DoneFooter(state: state, below: below, practice: practice),
          ],
        ),
      ),
    );
  }
}

/// The result actions: redo / review the lesson when below, practice or finish.
class _DoneFooter extends StatelessWidget {
  const _DoneFooter({
    required this.state,
    required this.below,
    required this.practice,
  });

  final EndgameLessonState state;
  final bool below;
  final Practice? practice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ActionsFooter(
      stacked: true,
      children: [
        // Passou: praticar o final de verdade. Não passou: refazer.
        if (below)
          FilledButton.icon(
            key: ExercisesDoneKeys.redo,
            icon: const Icon(Icons.replay),
            onPressed: () async {
              final cubit = context.read<EndgameLessonCubit>();
              final router = GoRouter.of(context);
              final id = state.lesson!.id;
              await cubit.redoExercises();
              router.pushReplacement(Routes.endgameExercisesIntro(id));
            },
            label: Text(l10n.endgameRedoExercises),
          )
        else if (practice case final practice?)
          FilledButton.icon(
            key: ExercisesDoneKeys.practice,
            icon: const Icon(Icons.sports_esports_outlined),
            onPressed: () {
              context.pushReplacement(
                Routes.setup(
                  practice.fen,
                  goal: practice.goal.code,
                  position: practice.positionId,
                ),
              );
            },
            label: Text(l10n.exercisesDonePractice),
          ),
        // Passou: concluir. Não passou: rever a lição, do começo.
        if (below)
          OutlinedButton.icon(
            key: ExercisesDoneKeys.reviewLesson,
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              final lesson = state.lesson!;
              final first = lesson.lesson.sections.firstOrNull;
              context.pushReplacement(
                Routes.endgameLessonScript(
                  lesson.id,
                  part: lesson.lesson.parts.isEmpty ? null : first?.id,
                ),
              );
            },
            label: Text(l10n.endgameLessonReview),
          )
        else
          OutlinedButton(
            key: ExercisesDoneKeys.back,
            onPressed: () => context.pop(),
            child: Text(l10n.exercisesDoneFinish),
          ),
      ],
    );
  }
}

/// The graduation image shared on pass: medal, band, points and diploma.
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.cardKey,
    required this.state,
    required this.grade,
  });

  final GlobalKey cardKey;
  final EndgameLessonState state;
  final ExerciseGrade grade;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RepaintBoundary(
      key: cardKey,
      child: ColoredBox(
        key: ExercisesDoneKeys.shareCard,
        color: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradeMedal(grade: grade),
              const SizedBox(height: AppSpacing.sm),
              Text(
                gradeName(l10n, grade),
                key: ExercisesDoneKeys.current,
                textAlign: TextAlign.center,
                style: context.bigNumber?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.exercisesDoneScore(state.score, state.maxScore),
                key: ExercisesDoneKeys.score,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Diploma(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chapter test result of a Pilares lesson.
class _PilaresResult extends StatelessWidget {
  const _PilaresResult({required this.state, required this.redo});

  final EndgameLessonState state;
  final Future<void> Function(String lessonId) redo;

  @override
  Widget build(BuildContext context) {
    final lesson = state.lesson!;
    final completed =
        state.progress.completedTestOf(lesson) ?? const <String, bool>{};
    final answered = lesson.exercises
        .where((exercise) => completed.containsKey(exercise.id))
        .toList();
    final chapter =
        int.tryParse(_chapterNumber.firstMatch(lesson.id)?.group(1) ?? '') ??
        state.lessonNumber;
    return TestCanvasResultPage(
      chapter: chapter,
      answers: [
        for (final exercise in answered) completed[exercise.id] == true,
      ],
      themes: [
        for (final exercise in answered)
          exercise.theme == null
              ? null
              : state.texts.plain('part.${exercise.theme}.title'),
      ],
      teacher: state.viktor,
      onContinue: () => context.pop(),
      // Sem rota própria do catálogo do capítulo: abre o capítulo do guia.
      onReviewLessons: () =>
          context.pushReplacement(Routes.trainingChapter('pilares', lesson.id)),
      onReview: (index) {
        final exercise = answered[index];
        context.push(
          Routes.learningAnalysisAt(
            exercise.fen,
            moves: [
              for (final turn in exercise.line) ...[
                if (turn.accept.isNotEmpty) turn.accept.first,
                ?turn.reply,
              ],
            ],
            orientation: exercise.step.side.name,
          ),
        );
      },
      onRetry: () => redo(lesson.id),
    );
  }
}

/// The result uses observed first-answer correctness, never weighted points.
class TestCanvasResultPage extends StatelessWidget {
  const TestCanvasResultPage({
    required this.chapter,
    required this.answers,
    required this.onContinue,
    required this.onRetry,
    required this.onReview,
    this.onReviewLessons,
    this.themes = const [],
    this.teacher,
    this.speech,
    super.key,
  });
  final int chapter;
  final List<bool> answers;

  /// Theme title of each answer (same order as [answers]); null when unknown.
  final List<String?> themes;
  final Character? teacher;
  final String? speech;
  final VoidCallback onContinue, onRetry;

  /// Failed results: opens the chapter catalog. Never locks the next chapter.
  final VoidCallback? onReviewLessons;
  final ValueChanged<int> onReview;

  /// "A", "A e B", "A, B e C".
  static String _themeList(AppLocalizations t, List<String> items) =>
      items.length < 2
      ? items.join()
      : t.licaoTemasUltimo(items.take(items.length - 1).join(', '), items.last);

  String _failedSpeech(AppLocalizations t, {required bool far}) {
    final wrong = <String>[];
    for (var i = 0; i < answers.length && i < themes.length; i++) {
      final theme = themes[i];
      if (!answers[i] && theme != null && !wrong.contains(theme)) {
        wrong.add(theme);
      }
    }
    if (wrong.isEmpty) {
      return far ? t.licaoTesteFalaMuitoAbaixo : t.licaoTesteFalaAbaixo;
    }
    final list = _themeList(t, wrong);
    return far
        ? t.licaoTesteFalaMuitoAbaixoTemas(list)
        : t.licaoTesteFalaAbaixoTemas(list);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final correct = answers.where((answer) => answer).length;
    final grade = ExerciseGrade
        .values[ChapterTestScores.gradeIndex(correct, answers.length)];
    final below = grade == ExerciseGrade.below;
    final far = correct <= 3;
    final title = below
        ? (far ? t.licaoTesteRecomecar : t.licaoTesteQuaseLa)
        : grade == ExerciseGrade.passed
        ? t.testCanvasRegular
        : gradeName(t, grade);
    return Scaffold(
      key: ExercisesDoneKeys.screen,
      appBar: LucenaAppBar(
        leading: IconButton(
          key: ExercisesDoneKeys.close,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(CanvasSymbols.close),
          onPressed: onContinue,
        ),
      ),
      body: SafeArea(
        top: false,
        // H-ANI-25: medalha, título, placar, bolinhas, Viktor e botões em
        // ordem; reabrir o mesmo resultado mostra tudo pronto.
        child: EntradaDeResultado(
          id: 'teste-$chapter-${answers.map((a) => a ? 1 : 0).join()}',
          estrela: Center(
            child: TestCanvasMedal(key: TestCanvasKeys.medal, grade: grade),
          ),
          titulo: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              title,
              key: ExercisesDoneKeys.current,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          subtitulo: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${t.testCanvasTitle(chapter)} · ${t.testCanvasScore(correct, answers.length)}',
              key: ExercisesDoneKeys.score,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          bolinhas: [
            for (var i = 0; i < answers.length; i++)
              _AnswerDot(
                index: i,
                correct: answers[i],
                onReview: () => onReview(i),
              ),
          ],
          montarBolinhas: (bolinhas) => Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                SizedBox(
                  width: 294,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: bolinhas,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.testCanvasReview,
                  key: TestCanvasKeys.reviewHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 16 / 12),
                ),
              ],
            ),
          ),
          viktor: switch (teacher) {
            final teacher? => _ResultTeacher(
              teacher: teacher,
              text:
                  speech ??
                  (below
                      ? _failedSpeech(t, far: far)
                      : t.testCanvasResultSpeech(correct, answers.length)),
            ),
            null => null,
          },
          botoes: _ResultFooter(page: this, below: below),
          // A lista rola; os botões ficam presos embaixo.
          montar: (partes) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: partes.sublist(0, partes.length - 1),
                ),
              ),
              partes.last,
            ],
          ),
        ),
      ),
    );
  }
}

/// One answer bubble of the result page: opens the review of that answer.
class _AnswerDot extends StatelessWidget {
  const _AnswerDot({
    required this.index,
    required this.correct,
    required this.onReview,
  });

  final int index;
  final bool correct;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: InkWell(
          key: TestCanvasKeys.answer(index),
          customBorder: const CircleBorder(),
          onTap: onReview,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: correct
                    ? AppColors.trainingDayCorrect
                    : AppColors.trainingDayWrong,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.chessWhiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Viktor's balloon on the result page.
class _ResultTeacher extends StatelessWidget {
  const _ResultTeacher({required this.teacher, required this.text});

  final Character teacher;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.copyWith(
            bodyLarge: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 14, height: 20 / 14, letterSpacing: 0),
          ),
        ),
        child: TeacherSpeech(
          key: ExercisesDoneKeys.retrySpeech,
          canvasTrainingBalloon: true,
          teacher: teacher,
          speechContext: SpeechContext.teaching,
          text: text,
          avatarSize: 56,
          speaks: true,
          unifiedSound: true,
          canvasHeader: true,
          showSpeedBadge: false,
        ),
      ),
    );
  }
}

/// A result page button: filled when primary, outlined otherwise.
class _ResultButton extends StatelessWidget {
  const _ResultButton(
    this.label,
    this.onPressed, {
    required this.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => primary
      ? FilledButton(onPressed: onPressed, child: Text(label))
      : OutlinedButton(onPressed: onPressed, child: Text(label));
}

/// The result page buttons: review the lessons (failed) or continue, and retry.
class _ResultFooter extends StatelessWidget {
  const _ResultFooter({required this.page, required this.below});

  final TestCanvasResultPage page;
  final bool below;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ActionsFooter(
      stacked: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        if (below) ...[
          _ResultButton(
            t.licaoTesteReverLicoes,
            page.onReviewLessons ?? page.onContinue,
            primary: true,
            key: TestCanvasKeys.reviewLessons,
          ),
          _ResultButton(
            t.testCanvasRetry,
            page.onRetry,
            primary: false,
            key: ExercisesDoneKeys.redo,
          ),
        ] else ...[
          _ResultButton(
            t.testCanvasContinue,
            page.onContinue,
            primary: true,
            key: ExercisesDoneKeys.back,
          ),
          _ResultButton(
            t.testCanvasRetry,
            page.onRetry,
            primary: false,
            key: ExercisesDoneKeys.redo,
          ),
        ],
      ],
    );
  }
}

/// O diploma da aula: concedido ao aluno por concluir a aula, com o resumo do
/// que ela ensina, a faixa e os pontos, a data e o professor.
class _Diploma extends StatelessWidget {
  const _Diploma({required this.state});

  final EndgameLessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lesson = state.lesson!;
    final nickname = context.select(
      (ProfileCubit cubit) => cubit.state?.nickname ?? '',
    );
    final now = context.read<Now?>()?.call();
    final date = now == null
        ? ''
        : DateFormat.yMMMMd(Localizations.localeOf(context).toString())
              .format(now);
    final summary = state.texts.lessonSummary(lesson.id);
    return Card(
      key: ExercisesDoneKeys.diploma,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
        side: BorderSide(color: colors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShape.medium),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: AppIconSize.illustration,
                color: colors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.endgamesTitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.graduationDiploma, style: context.bigNumber),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.graduationAwardedTo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                nickname.isEmpty ? l10n.profileNicknameDefault : nickname,
                key: ExercisesDoneKeys.diplomaName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                // Resume o desempenho, sem números.
                l10n.exercisesDoneDiplomaFor(
                  state.grade.name,
                  state.texts.lessonTitle(lesson.id),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (summary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _SignatureLine(
                      value: date,
                      label: l10n.graduationDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _SignatureLine(
                      value: state.viktor?.name ?? '',
                      label: l10n.graduationTeacher,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma linha de assinatura: o valor sobre um traço e o rótulo embaixo.
class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

final _chapterNumber = RegExp(r'\.c(\d+)');
