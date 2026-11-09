import 'package:flutter/material.dart';

import '../../core/motion/barra_que_enche.dart';
import '../../core/motion/lista_em_ordem.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/meta_dobrada.dart';
import '../../core/motion/valor_que_anima.dart';

import '../../../domain/use_cases/training/training_goal_counts.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/day_goals.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/use_cases/demo_goals.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/course_guide_cubit.dart';
import '../../training_goal/widgets/training_goal_card.dart';
import 'course_guide_copy.dart';
import 'training_streak_summary.dart';
import '../../training_opening/widgets/opening_goal_cards.dart';
import '../../course_entry/widgets/course_content_states.dart';

class TrainingGoalsTab extends StatelessWidget {
  const TrainingGoalsTab({
    required this.onGoal,
    required this.onPlan,
    this.onOpening,
    this.onLockedGoal,
    this.lessonSummary,
    this.footer,
    this.chapterDoneInvite,
    this.focus,
    super.key,
  });

  /// Bloco no alto da lista: a parte do Pilares que o Treinador de partidas
  /// mandou estudar (T87).
  final Widget? focus;
  final ValueChanged<TrainingGoal> onGoal;
  final VoidCallback onPlan;
  final ValueChanged<String>? onOpening;

  /// Na demonstração do Pilares (H-VEN-12, frente Venda): só as lições do
  /// Capítulo 1 ficam abertas ([DemoGoals]); o toque numa meta trancada vem
  /// para cá, e o resumo "Hoje" conta só as abertas, sem a linha do plano.
  final ValueChanged<TrainingGoal>? onLockedGoal;

  /// O resumo das lições da demo ("Capítulo 1 · Lição grátis").
  final String? lessonSummary;

  /// Bloco no fim da lista; na demo, toma o lugar do quadro de boas-vindas.
  final Widget? footer;

  /// Na demo, com o Capítulo 1 concluído e sem lição aberta hoje
  /// (PropV2MetaDemoFimCap1B): o convite vai na seção Lição e toma o lugar do
  /// [footer], para a aba ter um convite só.
  final Widget? chapterDoneInvite;

  bool get _demo => onLockedGoal != null;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final day = state.training?.day;
      if (day == null) return const SizedBox.shrink();
      final t = context.l10n;
      final counts = _demo
          ? DemoGoals.counts(state.training!)
          : trainingGoalCounts(state.training!);
      final cubit = context.read<CourseGuideCubit>();
      final chapterDone =
          _demo &&
          chapterDoneInvite != null &&
          day.studyDay &&
          DemoGoals.chapterOneDone(state.training!, state.resources!) &&
          !day.goals.any(
            (g) =>
                (g.kind == GoalKind.lesson || g.kind == GoalKind.extraLesson) &&
                !DemoGoals.isLocked(g),
          );
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
      final hasOfflineLesson = day.goals.any(
        (goal) =>
            !goal.done &&
            (goal.kind == GoalKind.lesson ||
                goal.kind == GoalKind.extraLesson) &&
            state.resources!.lessons.any(
              (lesson) =>
                  lesson.id == goal.ref &&
                  state.resources!.offlineChapters.contains(lesson.groupId),
            ),
      );
      final introductorySpacing =
          !hasOfflineLesson &&
          cubit.config.progressKind != TrainingProgressKind.modulesAndPieces &&
          (!day.studyDay || state.training!.completedLessons.length == 1);
      final goalGap = introductorySpacing ? 12.0 : 8.0;
      final schoolFirstLessons =
          cubit.config.progressKind == TrainingProgressKind.modulesAndPieces &&
          state.training!.completedLessons.isEmpty;
      final escola = cubit.config.course == TrainingCourse.escola;
      final contents = <Widget>[];
      if (hasOfflineLesson) {
        contents.add(const TrainingGoalsOfflineNotice());
      }
      if (focus case final f?) contents.add(f);
      contents.add(
        _TodayPanel(
          tab: this,
          state: state,
          day: day,
          counts: counts,
          chapterDone: chapterDone,
          offer: offer,
        ),
      );
      if (!day.studyDay) {
        final lesson = state.nextLesson;
        contents.add(_SectionLabel(t.trainingSectionIfStudy));
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
          _InfoPanel(courseGuideCopy(context, cubit.config.dayOffInfoKey)),
        );
      } else if (day.doubled) {
        // H-ANI-29: os cartões em fila e "META DOBRADA" por último.
        final pending = day.goals.where((g) => !g.done).toList();
        final done = day.goals.where((g) => g.done).toList();
        contents.add(
          MetaDobradaEmOrdem(
            selo: _SectionLabel(t.trainingSectionDoubled),
            cartoes: [
              for (final g in pending)
                _GoalTile(tab: this, state: state, goal: g),
              for (final g in done)
                _GoalTile(
                  tab: this,
                  state: state,
                  goal: g,
                  completedCopy: true,
                ),
            ],
            montar: (selo, cartoes) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: goalGap,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [selo, ...cartoes.take(pending.length)],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    _SectionLabel(t.trainingSectionDoneToday),
                    ...cartoes.skip(pending.length),
                  ],
                ),
              ],
            ),
          ),
        );
      } else if (day.allDone && (!offer || escola)) {
        if (escola) {
          // Metas feitas (H-ANI-17): 90 ms entre uma e outra.
          contents.add(
            ListaEmOrdem.feitos(
              itens: [
                for (final goal in day.goals)
                  _GoalTile(tab: this, state: state, goal: goal),
              ],
              montar: (itens) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: goalGap,
                children: itens,
              ),
            ),
          );
        } else {
          for (final goal in day.goals) {
            contents.add(_GoalTile(tab: this, state: state, goal: goal));
          }
        }
      } else {
        for (final section in sections) {
          final goals = day.goals
              .where((g) => _sectionOf(g.kind) == section)
              .toList();
          if (chapterDone && section == GoalSection.lessons && goals.isEmpty) {
            contents.add(
              _GoalsSection(
                header: _SectionLabel(t.trainingSectionLesson),
                headerGap: goalGap,
                children: [chapterDoneInvite!],
              ),
            );
            continue;
          }
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
            GoalSection.bots => t.trainingSectionBots,
            GoalSection.stars => t.trainingSectionStars,
          };
          contents.add(
            _GoalsSection(
              header: !firstLesson || section != GoalSection.lessons
                  ? _SectionLabel(label)
                  : null,
              headerGap: schoolFirstLessons ? 0 : goalGap,
              children: [
                for (final (index, g) in goals.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : goalGap),
                    child: _GoalTile(tab: this, state: state, goal: g),
                  ),
                if (schoolFirstLessons) const SizedBox(height: 8),
              ],
            ),
          );
        }
        if (!_demo &&
            (cubit.config.progressKind !=
                    TrainingProgressKind.modulesAndPieces ||
                state.training!.completedLessons.isEmpty) &&
            state.training!.cycles.isEmpty &&
            state.training!.openings.isEmpty) {
          contents.add(
            _InfoPanel(courseGuideCopy(context, cubit.config.firstInfoKey)),
          );
        }
      }
      if (footer case final footer? when !chapterDone) contents.add(footer);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: TrainingGoalCard(
                  course: cubit.config.course,
                  place: TrainingGoalCardPlace.goals,
                ),
              ),
            ),
            for (final item in contents)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  firstLesson && item is _GoalsSection ? 16 : goalGap,
                ),
                sliver: item is _GoalsSection
                    ? item
                    : SliverToBoxAdapter(child: item),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      );
    },
  );

  String _lessonTitle(
    BuildContext context,
    CourseGuideState state,
    TrainingLesson lesson,
  ) {
    if (lesson.kind == TrainingLessonKind.test) return lesson.title;
    final modules =
        context.read<CourseGuideCubit>().config.progressKind ==
        TrainingProgressKind.modulesAndPieces;
    final lessons = state.resources!.lessons
        .where(
          (l) =>
              l.visible &&
              l.kind != TrainingLessonKind.test &&
              (modules
                  ? l.groupId == lesson.groupId
                  : l.partId == lesson.partId),
        )
        .toList();
    return context.l10n.trainingLessonLabel(
      lessons.indexWhere((l) => l.id == lesson.id) + 1,
      trainingMasteryLessonTitle(context, lesson),
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
}

/// A note on the primary container, with the info icon.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => _Panel(
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
}

/// A section label above the goal cards.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 20 / 12,
        letterSpacing: 0,
      ),
    ),
  );
}

/// The goals tab card: white (or primary container when [highlight]).
class _Panel extends StatelessWidget {
  const _Panel({
    required this.children,
    this.highlight = false,
    this.spacing = 10,
    super.key,
  });

  final List<Widget> children;
  final bool highlight;
  final double spacing;

  @override
  Widget build(BuildContext context) => Material(
    color: highlight
        ? Theme.of(context).colorScheme.primaryContainer
        : AppColors.white,
    borderRadius: BorderRadius.circular(AppShape.large),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    ),
  );
}

/// Keeps a section's heading visible only while that section is scrolling.
class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.header,
    required this.headerGap,
    required this.children,
  });

  final Widget? header;
  final double headerGap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      if (header != null)
        SliverPersistentHeader(
          pinned: true,
          delegate: _GoalsHeader(
            extent:
                4 + 20 * MediaQuery.textScalerOf(context).scale(1) + headerGap,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Align(alignment: Alignment.topLeft, child: header!),
            ),
          ),
        ),
      SliverList.list(children: children),
    ],
  );
}

class _GoalsHeader extends SliverPersistentHeaderDelegate {
  _GoalsHeader({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);
  @override
  bool shouldRebuild(_GoalsHeader oldDelegate) =>
      extent != oldDelegate.extent || child != oldDelegate.child;
}

/// O painel de hoje: oferta de dobrar, dia de folga, tudo feito ou resumo.
class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.tab,
    required this.state,
    required this.day,
    required this.counts,
    required this.chapterDone,
    required this.offer,
  });

  final TrainingGoalsTab tab;
  final CourseGuideState state;
  final DayGoals day;
  final ({int total, int remaining}) counts;
  final bool chapterDone;
  final bool offer;

  @override
  Widget build(BuildContext context) {
    if (offer) {
      return _DoubleOffer(state: state, day: day);
    } else if (!day.studyDay) {
      return _DayOff(tab: tab, day: day);
    } else if (day.allDone) {
      return _AllDone(state: state);
    } else {
      return _TodaySummary(
        tab: tab,
        state: state,
        day: day,
        counts: counts,
        chapterDone: chapterDone,
      );
    }
  }
}

/// A oferta de dobrar as metas de hoje.
class _DoubleOffer extends StatelessWidget {
  const _DoubleOffer({required this.state, required this.day});

  final CourseGuideState state;
  final DayGoals day;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<CourseGuideCubit>();
    return _Panel(
      highlight: true,
      spacing: 8,
      key: TrainingKeys.doubleOffer,
      children: [
        Text(
          t.trainingDoubleOfferTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          courseGuideCopy(
            context,
            cubit.config.doubleOfferBodyKey,
            count: cubit.config.option(day.plan.minutes).lessonsPerDay,
          ),
        ),
        if (cubit.doubleMinutes() case final minutes when minutes > 0)
          Text(
            t.trainingDoubleOfferMinutes(minutes),
            key: TrainingKeys.doubleMinutes,
          ),
        FilledButton(
          key: TrainingKeys.doubleButton,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(kButtonHeight),
          ),
          onPressed: state.saving ? null : cubit.doubleGoals,
          child: Text(t.trainingDoubleAction),
        ),
      ],
    );
  }
}

/// O dia de folga, com a linha do plano.
class _DayOff extends StatelessWidget {
  const _DayOff({required this.tab, required this.day});

  final TrainingGoalsTab tab;
  final DayGoals day;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _Panel(
      children: [
        Text(
          t.trainingDayOffTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(t.trainingDayOffBody),
        _PlanLine(day: day, onPlan: tab.onPlan),
      ],
    );
  }
}

/// Tudo feito hoje: a fala do professor ou o painel simples.
class _AllDone extends StatelessWidget {
  const _AllDone({required this.state});

  final CourseGuideState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CourseGuideCubit>();
    return state.teacher == null
        ? _Panel(
            children: [
              Text(courseGuideCopy(context, cubit.config.allDoneSpeechKey)),
            ],
          )
        : Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme
                  .copyWith(bodyLarge: Theme.of(context).textTheme.bodyMedium),
            ),
            child: TeacherSpeech(
              canvasHeader: true,
              canvasTrainingBalloon: true,
              unifiedSound: true,
              showSpeedBadge: false,
              teacher: state.teacher!,
              avatarSize: 40,
              text: courseGuideCopy(context, cubit.config.allDoneSpeechKey),
              speechContext: SpeechContext.teaching,
            ),
          );
  }
}

/// O resumo do dia: o contador, a barra e a sequência.
class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.tab,
    required this.state,
    required this.day,
    required this.counts,
    required this.chapterDone,
  });

  final TrainingGoalsTab tab;
  final CourseGuideState state;
  final DayGoals day;
  final ({int total, int remaining}) counts;
  final bool chapterDone;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<CourseGuideCubit>();
    final escola = cubit.config.course == TrainingCourse.escola;
    return _Panel(
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
            // H-ANI-18: conta o que já foi feito, junto com a barra;
            // "Faltam" desce de M até N. Na demo sem lição aberta, o
            // contador (0 de 0) dá lugar a "Capítulo 1 concluído".
            if (chapterDone)
              Text(
                t.venDemoGoalsChapterDone,
                key: TrainingKeys.goalsChapterDone,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              )
            else
              ValorQueAnima(
                valor: (counts.total - counts.remaining).toDouble(),
                // Dobrar nasce de um toque na própria tela: o número real
                // aparece já no primeiro quadro.
                contarNaEntrada: !day.doubled,
                duracao: LucenaMotion.numeroConta,
                builder: (context, feito) => Text(
                  t.trainingGoalsLeft(
                    counts.total - feito.round(),
                    counts.total,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 6,
          child: escola
              ? BarraQueEnche(
                  altura: 6,
                  corDoTrilho: Theme.of(context).colorScheme.outlineVariant,
                  valor: counts.total == 0
                      ? 0
                      : (counts.total - counts.remaining) / counts.total,
                )
              : BarraQueEnche(
                  altura: 6,
                  corDoTrilho: Theme.of(context).colorScheme.outlineVariant,
                  valor: chapterDone
                      ? 1
                      : counts.total == 0
                      ? 0
                      : (counts.total - counts.remaining) / counts.total,
                ),
        ),
        if (!tab._demo && state.streak != null) ...[
          const Divider(height: 1),
          TrainingStreakSummary(state: state.streak!),
          const Divider(height: 1),
        ],
        if (!tab._demo) _PlanLine(day: day, onPlan: tab.onPlan),
      ],
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.day, required this.onPlan});

  final DayGoals day;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
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
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.tab,
    required this.state,
    required this.goal,
    this.completedCopy = false,
  });

  final TrainingGoalsTab tab;
  final CourseGuideState state;
  final TrainingGoal goal;
  final bool completedCopy;

  @override
  Widget build(BuildContext context) {
    if (goal.kind == GoalKind.openings && tab.onOpening != null) {
      return OpeningGoalCards(
        saved: state.training!,
        resources: state.resources!,
        onTrain: tab.onOpening!,
      );
    }
    final t = context.l10n;
    final lesson = state.resources!.lessons
        .where((l) => l.id == goal.ref)
        .firstOrNull;
    final training = state.training!;
    final cycle = training.cycles[goal.ref];
    final level = switch (goal.itemId) {
      'medium' => t.challengeLevelMedium,
      'hard' => t.challengeLevelHard,
      _ => t.challengeLevelEasy,
    };
    final title = switch (goal.kind) {
      GoalKind.openings => t.trainingOpeningsTitle,
      GoalKind.stars => t.starChallengeTitle(goal.ref.split('.').last),
      GoalKind.speedrun => t.trainingSpeedrunGoalTitle,
      GoalKind.lesson || GoalKind.extraLesson =>
        lesson == null ? '' : tab._lessonTitle(context, state, lesson),
      _ => lesson == null ? '' : trainingMasteryLessonTitle(context, lesson),
    };
    final locked = tab._demo && !goal.done && DemoGoals.isLocked(goal);
    final summary = switch (goal.kind) {
      GoalKind.lesson || GoalKind.extraLesson
          when tab.lessonSummary != null && !goal.done =>
        tab.lessonSummary!,
      GoalKind.lesson =>
        goal.done
            ? t.trainingLessonDoneToday
            : lesson != null &&
                  state.resources!.offlineChapters.contains(lesson.groupId)
            ? t.trainingLessonNeedsInternet
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
      GoalKind.stars =>
        goal.done
            ? t.trainingStarGoalDone(level, goal.stars)
            : t.trainingStarGoal(level, goal.stars),
      GoalKind.bot =>
        goal.done
            ? t.trainingBotGoalDone(
                t.trainingBotNameCoco,
                int.tryParse(goal.items['rung'] ?? '') ?? 1000,
              )
            : t.trainingBotGoal(
                t.trainingBotNameCoco,
                int.tryParse(goal.items['rung'] ?? '') ?? 1000,
              ),
      GoalKind.speedrun => t.trainingSpeedrunGoal(
        (int.tryParse(goal.items['initialSeconds'] ?? '') ?? 900) ~/ 60,
        t.trainingBotNameCoco,
      ),
    };
    return AnimatedSwitcher(
      duration: AppMotion.of(context).component,
      child: CourseItemTile(
        key: locked
            ? PurchaseKeys.demoGoalsLockedTile(goal.kind.name, goal.ref)
            : TrainingKeys.goalTile(
                goal.kind.name,
                completedCopy
                    ? '${goal.ref}:${goal.itemId ?? goal.kind.name}'
                    : goal.ref,
              ),
        state: locked
            ? CourseItemState.locked
            : goal.done
            ? CourseItemState.approved
            // Com o destaque do Treinador no alto, ele é o único em azul.
            : tab.focus == null && goal.key == training.day?.next?.key
            ? CourseItemState.next
            : CourseItemState.open,
        title: title,
        summary: summary,
        difficulty: goal.kind == GoalKind.stars || goal.stars == 0
            ? null
            : goal.stars,
        onTap: goal.done
            ? null
            : () => locked ? tab.onLockedGoal!(goal) : tab.onGoal(goal),
      ),
    );
  }
}
