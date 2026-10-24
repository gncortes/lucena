import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/course/chapter_lesson_list.dart';
import '../../core/widgets/course/course_chapter_layout.dart';
import '../../core/widgets/course/course_continue_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/endgame_lesson_cubit.dart';

/// Um capítulo de finais (canvas `PropV2FinaisLicao`, padrão T1 dos cursos):
/// a parte e o título, o cartão com as lições e os exercícios práticos, e o
/// botão fixo que leva à lição recomendada.
class EndgameLessonScreen extends StatelessWidget {
  const EndgameLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<EndgameLessonCubit, EndgameLessonState>(
      builder: (context, state) {
        final lesson = state.lesson;
        return Scaffold(
          key: EndgameLessonKeys.screen,
          // O número e o título da aula, que pode ser longo, vêm no corpo.
          appBar: LucenaAppBar(
            actions: [
              if (lesson != null)
                IconButton(
                  key: EndgameLessonKeys.infoButton,
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.endgameInfoTooltip,
                  onPressed: () => context.push(Routes.endgameInfo(lesson.id)),
                ),
            ],
          ),
          body: !state.ready
              ? const SizedBox.shrink()
              : state.missing || lesson == null
              ? Center(
                  child: Text(
                    l10n.lessonMissing,
                    key: EndgameLessonKeys.missing,
                  ),
                )
              : _Body(state: state, lesson: lesson),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final texts = state.texts;
    final parts = lesson.lesson.sections;
    final done = state.partsDone;
    final recommended = state.recommendedPart;
    return CourseChapterLayout(
      listKey: EndgameLessonKeys.list,
      // A parte e a posição nela ("Finais de peão · capítulo 2 de 3"): o
      // número no curso inteiro diz pouco.
      place: l10n.endgameModulePlace(
        texts.plain('endgames.module.${lesson.module}') ?? lesson.module,
        state.moduleNumber,
        state.moduleCount,
      ),
      title: texts.lessonTitle(lesson.id),
      notice: lesson.failed || lesson.inReview
          ? _InReview(failed: lesson.failed)
          : null,
      list: ChapterLessonList(
        rows: [
          for (final (index, part) in parts.indexed)
            _PartRow(
              lesson: lesson,
              state: state,
              part: part,
              number: index + 1,
              kind: done.contains(part.id)
                  ? ChapterRowKind.done
                  : recommended?.id == part.id
                  ? ChapterRowKind.recommended
                  : ChapterRowKind.other,
            ),
        ],
        exercises: state.exerciseCount == 0
            ? null
            : ChapterLessonRow(
                key: EndgameLessonKeys.exercises,
                kind: ChapterRowKind.exercises,
                number: '',
                title: l10n.chapterExercisesCount(state.exerciseCount),
                // Como hoje: a introdução até resolver todos; depois, o
                // resultado com a lista.
                onTap: () => context.push(
                  state.allSolved
                      ? Routes.endgameExercisesDone(lesson.id)
                      : Routes.endgameExercisesIntro(lesson.id),
                ),
              ),
      ),
      footer: _ContinueBar(state: state, lesson: lesson),
    );
  }
}

/// O aviso de que a aula ainda está em revisão e pode mudar ou, com
/// [failed], de que a revisão a reprovou e ela será refeita.
class _InReview extends StatelessWidget {
  const _InReview({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = failed
        ? colors.errorContainer
        : colors.secondaryContainer;
    final foreground = failed
        ? colors.onErrorContainer
        : colors.onSecondaryContainer;
    return Card(
      key: failed ? EndgameLessonKeys.reviewFailed : EndgameLessonKeys.inReview,
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              failed ? Icons.cancel_outlined : Icons.rate_review_outlined,
              size: AppIconSize.button,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                failed
                    ? context.l10n.endgameLessonFailed
                    : context.l10n.endgameLessonInReview,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma lição do capítulo na lista: abre o roteiro dela, retomando a etapa
/// em que o aluno saiu (nada trava).
class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.lesson,
    required this.state,
    required this.part,
    required this.number,
    required this.kind,
  });

  final EndgameLesson lesson;
  final EndgameLessonState state;
  final LessonPart part;
  final int number;
  final ChapterRowKind kind;

  @override
  Widget build(BuildContext context) {
    final texts = state.texts;
    final ongoing = state.ongoingPart == part.id;
    return ChapterLessonRow(
      key: EndgameLessonKeys.part(part.id),
      kind: kind,
      number: '$number',
      title:
          texts.partTitle(lesson.id, part.id) ??
          context.l10n.endgameLessonPartLesson,
      summary: texts.partSummary(lesson.id, part.id),
      onTap: () => context.push(
        Routes.endgameLessonScript(
          lesson.id,
          part: lesson.lesson.parts.isEmpty ? null : part.id,
          stage: ongoing && lesson.lesson.parts.isNotEmpty
              ? state.ongoingStep
              : 0,
        ),
      ),
    );
  }
}

/// O botão fixo embaixo, o destaque único: leva à lição recomendada; com
/// todas feitas, aos exercícios práticos; com tudo resolvido, ao treino da
/// posição.
class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.state, required this.lesson});

  final EndgameLessonState state;
  final EndgameLesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final part = state.recommendedPart;
    final exercise = state.nextExercise;
    final practice = lesson.practice;
    final String label;
    final VoidCallback onPressed;
    if (part != null) {
      final number = '${lesson.lesson.sections.indexOf(part) + 1}';
      // A lição começada é retomada na etapa em que o aluno saiu (decisão 4
      // do Gabriel).
      final resume = lesson.lesson.parts.isEmpty
          ? state.lessonOngoing && state.ongoingStep > 0
          : state.ongoingPart == part.id;
      label = resume
          ? l10n.chapterContinueLesson(number)
          : l10n.chapterStartLesson(number);
      onPressed = () => context.push(
        Routes.endgameLessonScript(
          lesson.id,
          part: lesson.lesson.parts.isEmpty ? null : part.id,
          stage: resume && lesson.lesson.parts.isNotEmpty
              ? state.ongoingStep
              : 0,
        ),
      );
    } else if (exercise != null) {
      final started =
          state.progress.stars.isNotEmpty || state.progress.exercise != null;
      label = started ? l10n.endgameResumeTest : l10n.endgameContinueTest;
      onPressed = () => context.push(Routes.endgameExercisesIntro(lesson.id));
    } else {
      label = l10n.endgameTrain;
      onPressed = () => context.push(
        Routes.setup(
          practice.fen,
          goal: practice.goal.code,
          position: practice.positionId,
        ),
      );
    }
    return CourseContinueFooter(
      buttonKey: EndgameLessonKeys.continueButton,
      label: label,
      onPressed: onPressed,
    );
  }
}
