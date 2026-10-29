import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/day_goals.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_content.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/course_guide_cubit.dart';
import 'course_guide_copy.dart';

class TrainingGoalsTab extends StatelessWidget {
  const TrainingGoalsTab({
    required this.onGoal,
    required this.onPlan,
    super.key,
  });
  final ValueChanged<TrainingGoal> onGoal;
  final VoidCallback onPlan;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final day = state.training?.day;
      if (day == null) return const SizedBox.shrink();
      final t = context.l10n;
      final cubit = context.read<CourseGuideCubit>();
      final extra = day.goals.any((g) => g.kind == GoalKind.extraLesson);
      final offer =
          day.allDone &&
          day.studyDay &&
          (extra || !cubit.config.doubleRequiresExtraLesson) &&
          !day.doubled;
      final firstLesson =
          day.goals.length == 1 &&
          day.goals.single.kind == GoalKind.lesson &&
          !day.goals.single.done &&
          state.training!.completedLessons.isEmpty &&
          state.training!.cycles.isEmpty &&
          state.training!.openings.isEmpty;
      final sections = cubit.config.sections;
      final contents = <Widget>[];
      if (offer) {
        contents.add(
          _panel(
            context,
            highlight: true,
            key: TrainingKeys.doubleOffer,
            children: [
              Text(
                t.trainingDoubleOfferTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(courseGuideCopy(context, cubit.config.doubleOfferBodyKey)),
              FilledButton(
                key: TrainingKeys.doubleButton,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(kButtonHeight),
                ),
                onPressed: state.saving ? null : cubit.doubleGoals,
                child: Text(t.trainingDoubleAction),
              ),
            ],
          ),
        );
      } else if (!day.studyDay) {
        contents.add(
          _panel(
            context,
            children: [
              Text(
                t.trainingDayOffTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(t.trainingDayOffBody),
              _planLine(context, day),
            ],
          ),
        );
      } else if (day.allDone) {
        contents.add(
          state.teacher == null
              ? _panel(
                  context,
                  children: [
                    Text(
                      courseGuideCopy(context, cubit.config.allDoneSpeechKey),
                    ),
                  ],
                )
              : Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.copyWith(
                      bodyLarge: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  child: TeacherSpeech(
                    teacher: state.teacher!,
                    avatarSize: 40,
                    text: courseGuideCopy(
                      context,
                      cubit.config.allDoneSpeechKey,
                    ),
                    speechContext: SpeechContext.teaching,
                  ),
                ),
        );
      } else {
        contents.add(
          _panel(
            context,
            key: TrainingKeys.goalsSummary,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.trainingGoalsToday,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    t.trainingGoalsLeft(day.remaining, day.goals.length),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 6,
                child: AnimatedProgress(
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  value: day.goals.isEmpty
                      ? 0
                      : (day.goals.length - day.remaining) / day.goals.length,
                ),
              ),
              _planLine(context, day),
            ],
          ),
        );
      }
      if (!day.studyDay) {
        final lesson = state.nextLesson;
        contents.add(_section(context, t.trainingSectionIfStudy));
        if (lesson != null) {
          contents.add(
            CourseItemTile(
              key: TrainingKeys.goalTile(GoalKind.lesson.name, lesson.id),
              state: CourseItemState.open,
              title: _lessonTitle(context, state, lesson),
              summary: t.trainingLessonNew(cubit.config.lessonMinutes),
              onTap: () =>
                  onGoal(TrainingGoal(kind: GoalKind.lesson, ref: lesson.id)),
            ),
          );
        }
        contents.add(
          _infoPanel(
            context,
            courseGuideCopy(context, cubit.config.dayOffInfoKey),
          ),
        );
      } else if (day.doubled) {
        contents.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(context, t.trainingSectionDoubled),
              for (final g in day.goals.where((g) => !g.done))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _goal(context, state, g),
                ),
            ],
          ),
        );
        contents.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(context, t.trainingSectionDoneToday),
              for (final g in day.goals.where((g) => g.done))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _goal(context, state, g, completedCopy: true),
                ),
            ],
          ),
        );
      } else if (day.allDone && !offer) {
        for (final goal in day.goals) {
          contents.add(_goal(context, state, goal));
        }
      } else {
        for (final section in sections) {
          final goals = day.goals
              .where((g) => _sectionOf(g.kind) == section)
              .toList();
          if (goals.isEmpty) continue;
          final label = switch (section) {
            GoalSection.lessons =>
              goals.length == 1
                  ? t.trainingSectionLesson
                  : t.trainingSectionLessons,
            GoalSection.reinforce => t.trainingSectionReinforce,
            GoalSection.exercises =>
              goals.length >= 7
                  ? t.trainingSectionExercisesN(goals.length)
                  : t.trainingSectionExercises,
            GoalSection.openings => t.trainingSectionOpenings,
            GoalSection.bots || GoalSection.stars => '',
          };
          contents.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!firstLesson || section != GoalSection.lessons)
                  _section(context, label),
                for (final g in goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _goal(context, state, g),
                  ),
              ],
            ),
          );
        }
        if (state.training!.cycles.isEmpty &&
            state.training!.openings.isEmpty) {
          contents.add(
            _infoPanel(
              context,
              courseGuideCopy(context, cubit.config.firstInfoKey),
            ),
          );
        }
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (final item in contents)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: item),
        ],
      );
    },
  );

  Widget _planLine(BuildContext context, DayGoals day) {
    final t = context.l10n;
    final days = day.plan.weekdays == 62
        ? t.trainingWeekdaysDefault
        : t.trainingWeekdaysCustom(
            day.plan.weekdayMask.split('').where((bit) => bit == '1').length,
          );
    return InkWell(
      onTap: onPlan,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 8,
          children: [
            Icon(
              Icons.edit_calendar_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            Expanded(child: Text(t.trainingPlanLine(days))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _goal(
    BuildContext context,
    CourseGuideState state,
    TrainingGoal goal, {
    bool completedCopy = false,
  }) {
    final t = context.l10n;
    final lesson = state.resources!.lessons
        .where((l) => l.id == goal.ref)
        .firstOrNull;
    final training = state.training!;
    final cycle = training.cycles[goal.ref];
    final title = switch (goal.kind) {
      GoalKind.openings => t.trainingOpeningsTitle,
      GoalKind.stars || GoalKind.bot || GoalKind.speedrun => '',
      GoalKind.lesson || GoalKind.extraLesson =>
        lesson == null ? '' : _lessonTitle(context, state, lesson),
      _ => lesson?.title ?? '',
    };
    final summary = switch (goal.kind) {
      GoalKind.lesson =>
        goal.done
            ? t.trainingLessonDoneToday
            : t.trainingLessonNew(
                context.read<CourseGuideCubit>().config.lessonMinutes,
              ),
      GoalKind.extraLesson => t.trainingLessonExtraDone,
      GoalKind.exercise => t.trainingOneExercise,
      GoalKind.reinforce => t.trainingReinforceLeft(
        (cycle?.reinforcement.length ?? 0) - (cycle?.reinforceDays.length ?? 0),
      ),
      GoalKind.redo => t.trainingRedoLesson,
      GoalKind.openings => t.trainingOpeningsSummary(
        goal.items.length,
        goal.items.entries
            .where(
              (e) =>
                  training.openings[e.key]?.doneTrechos[e.value] ==
                  training.day!.date,
            )
            .length,
        goal.items.length,
      ),
      GoalKind.stars || GoalKind.bot || GoalKind.speedrun => '',
    };
    return AnimatedSwitcher(
      duration: AppMotion.of(context).component,
      child: CourseItemTile(
        key: TrainingKeys.goalTile(
          goal.kind.name,
          completedCopy
              ? '${goal.ref}:${goal.itemId ?? goal.kind.name}'
              : goal.ref,
        ),
        state: goal.done
            ? CourseItemState.approved
            : goal.key == training.day?.next?.key
            ? CourseItemState.next
            : CourseItemState.open,
        title: title,
        summary: summary,
        difficulty: goal.kind == GoalKind.stars || goal.stars == 0
            ? null
            : goal.stars,
        onTap: goal.done ? null : () => onGoal(goal),
      ),
    );
  }

  String _lessonTitle(
    BuildContext context,
    CourseGuideState state,
    TrainingLesson lesson,
  ) {
    if (lesson.kind == TrainingLessonKind.test) return lesson.title;
    final lessons = state.resources!.lessons
        .where(
          (l) =>
              l.visible &&
              l.kind != TrainingLessonKind.test &&
              l.partId == lesson.partId,
        )
        .toList();
    return context.l10n.trainingLessonLabel(
      lessons.indexWhere((l) => l.id == lesson.id) + 1,
      lesson.title,
    );
  }

  static GoalSection _sectionOf(GoalKind kind) => switch (kind) {
    GoalKind.lesson || GoalKind.extraLesson => GoalSection.lessons,
    GoalKind.reinforce || GoalKind.redo => GoalSection.reinforce,
    GoalKind.exercise => GoalSection.exercises,
    GoalKind.openings => GoalSection.openings,
    GoalKind.bot || GoalKind.speedrun => GoalSection.bots,
    GoalKind.stars => GoalSection.stars,
  };
  static Widget _infoPanel(BuildContext context, String text) => _panel(
    context,
    highlight: true,
    children: [
      Row(
        spacing: 12,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          Expanded(child: Text(text)),
        ],
      ),
    ],
  );

  static Widget _section(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
  static Widget _panel(
    BuildContext context, {
    required List<Widget> children,
    bool highlight = false,
    Key? key,
  }) => Material(
    key: key,
    color: highlight
        ? Theme.of(context).colorScheme.primaryContainer
        : AppColors.white,
    borderRadius: BorderRadius.circular(AppShape.large),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: children,
      ),
    ),
  );
}
