import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../../domain/use_cases/training/goal/tournament_rules.dart';
import '../../../routing/route_names.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/valor_que_anima.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';
import '../../reminders/view_models/reminders_cubit.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_format.dart';

/// Onde o cartão aparece: no Início (convite quando falta objetivo) ou nas
/// Metas (sequência e dia perdido junto do objetivo).
enum TrainingGoalCardPlace { home, goals }

/// O objetivo do curso em um cartão (H-TRE-10/11): torneio com dias que
/// faltam, semana e capítulo do plano, sequência e aviso de dia perdido.
class TrainingGoalCard extends StatelessWidget {
  const TrainingGoalCard({
    required this.course,
    required this.place,
    super.key,
  });
  final TrainingCourse course;
  final TrainingGoalCardPlace place;

  @override
  Widget build(BuildContext context) {
    final guide = context.read<CourseGuideCubit>();
    return BlocProvider(
      create: (context) => TrainingGoalCubit(
        repository: guide.repository,
        config: guide.config,
        now: guide.now,
        analytics: guide.analytics,
        afterSave: (_) async {
          try {
            await context.read<RemindersCubit>().refresh();
          } on ProviderNotFoundException {
            // Sem lembretes na árvore (por exemplo, em teste de tela).
          }
        },
      )..load(),
      child: _CardBody(course: course, place: place),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.course, required this.place});
  final TrainingCourse course;
  final TrainingGoalCardPlace place;

  void _openGuide(BuildContext context) =>
      context.read<CourseGuideCubit>().selectTab(CourseGuideTab.guide);

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
      builder: (context, state) {
        final view = state.view;
        if (view == null) return const SizedBox.shrink();
        if (!view.hasObjective) {
          if (place == TrainingGoalCardPlace.goals) {
            return const SizedBox.shrink();
          }
          return _NoGoalCard(course: course);
        }
        final title = view.hasTournament
            ? switch (view.phase!) {
                TournamentPhase.before => t.treinoTournamentIn(view.daysLeft!),
                TournamentPhase.day => t.treinoTournamentDay,
                TournamentPhase.after => t.treinoHowWas(
                  view.tournamentName.isEmpty
                      ? t.treinoTournamentLower
                      : view.tournamentName,
                ),
              }
            : t.treinoGoalImprove;
        final current = view.current;
        final line = view.hasTournament && current != null && view.plan != null
            ? t.treinoGoalWeekLine(
                view.weekIndex + 1,
                view.plan!.weeks.length,
                view.chapterNumber(current.id),
              )
            : t.treinoGoalImproveLine(
                view.chapters.length - view.openChapters.length,
                view.chapters.length,
              );
        final missed =
            place == TrainingGoalCardPlace.goals &&
            view.missedDay &&
            view.needsMoreThanPlanned;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LucenaCard(
            key: TrainingGoalKeys.goalCard,
            onTap: () => _openGuide(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      // H-ANI-18: os dias até o torneio contam.
                      child: view.phase == TournamentPhase.before
                          ? ValorQueAnima(
                              valor: view.daysLeft!.toDouble(),
                              duracao: LucenaMotion.numeroConta,
                              builder: (context, agora) => Text(
                                t.treinoTournamentIn(agora.round()),
                                style: theme.textTheme.titleMedium,
                              ),
                            )
                          : Text(title, style: theme.textTheme.titleMedium),
                    ),
                    if (place == TrainingGoalCardPlace.goals && view.streak > 0)
                      ValorQueAnima(
                        valor: view.streak.toDouble(),
                        duracao: LucenaMotion.numeroConta,
                        builder: (context, agora) => Text(
                          t.treinoStreakDays(agora.round()),
                          key: TrainingGoalKeys.streak,
                        ),
                      ),
                  ],
                ),
                Text(line),
                if (missed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    key: TrainingGoalKeys.missedNotice,
                    onTap: () => _openMissed(context, view),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        view.missedNoticeActive
                            ? t.treinoMissedNotice(
                                durationText(context, view.minutesNeeded),
                              )
                            : t.treinoMissedTitle,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMissed(BuildContext context, GoalView view) async {
    final cubit = context.read<TrainingGoalCubit>();
    if (!view.missedNoticeActive) await cubit.noteMissed();
    if (!context.mounted) return;
    await showLucenaSheet<void>(
      context,
      sheetKey: TrainingGoalKeys.missedSheet,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: _MissedSheet(view: view),
      ),
    );
  }
}

class _MissedSheet extends StatefulWidget {
  const _MissedSheet({required this.view});
  final GoalView view;

  @override
  State<_MissedSheet> createState() => _MissedSheetState();
}

class _MissedSheetState extends State<_MissedSheet> {
  /// Aumentar o tempo é a primeira opção e já vem marcada.
  bool _more = true;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final view = widget.view;
    final cubit = context.read<TrainingGoalCubit>();
    final needed = durationText(context, view.minutesNeeded);
    final current = durationText(context, view.state.plan.minutes);
    final defer = view.chapterToDefer;
    Widget option(Key key, bool value, String title, String sub) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LucenaCard(
        onTap: () => setState(() => _more = value),
        child: Row(
          key: key,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(sub),
                ],
              ),
            ),
            Icon(
              _more == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.treinoMissedTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          option(
            TrainingGoalKeys.missedMore,
            true,
            t.treinoMissedIncrease(needed),
            t.treinoMissedIncreaseSub,
          ),
          option(
            TrainingGoalKeys.missedKeep,
            false,
            t.treinoMissedKeep(current),
            t.treinoMissedKeepSub(defer?.title ?? ''),
          ),
          const SizedBox(height: AppSpacing.sm),
          BusyButton(
            buttonKey: TrainingGoalKeys.missedConfirm,
            label: t.treinoConfirm,
            onPressed: () async {
              final ok = _more
                  ? await cubit.confirmMissedMore()
                  : await cubit.confirmMissedKeep();
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// O cartão "sem objetivo" da Home, com o botão para definir o objetivo.
class _NoGoalCard extends StatelessWidget {
  const _NoGoalCard({required this.course});

  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: LucenaCard(
        key: TrainingGoalKeys.goalCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.treinoNoGoalTitle, style: theme.textTheme.titleMedium),
            Text(t.treinoNoGoalHomeBody),
            const SizedBox(height: AppSpacing.md),
            BusyButton(
              buttonKey: TrainingGoalKeys.goalCardDefine,
              label: t.treinoDefineGoal,
              onPressed: () => context.pushNamed(
                RouteNames.trainingGoal,
                pathParameters: {'course': course.name},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
