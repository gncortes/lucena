import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/push/push_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../../domain/use_cases/training/goal/tournament_rules.dart';
import '../../../routing/route_names.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_card.dart';
import '../../reminders/view_models/reminders_cubit.dart';
import '../../training_goal/view_models/training_goal_cubit.dart';
import '../../training_goal/widgets/goal_format.dart';
import '../../training_goal/widgets/plan_widgets.dart';
import 'training_load_error.dart';

/// A aba Guia (H-TRE-05): o objetivo e o plano do curso, semana a semana.
class TrainingGuideTab extends StatelessWidget {
  const TrainingGuideTab({super.key, required this.course});
  final TrainingCourse course;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => TrainingGoalCubit(
      repository: context.read<TrainingRepository>(),
      config: TrainingCourseConfig.fromName(course.name)!,
      now: context.read<Now>(),
      analytics: context.analytics,
      afterSave: (_) => context.read<RemindersCubit>().refresh(),
    )..load(),
    child: _GuideBody(course: course),
  );
}

class _GuideBody extends StatefulWidget {
  const _GuideBody({required this.course});
  final TrainingCourse course;

  @override
  State<_GuideBody> createState() => _GuideBodyState();
}

class _GuideBodyState extends State<_GuideBody> with WidgetsBindingObserver {
  bool _pushAllowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPush();
  }

  Future<void> _checkPush() async {
    try {
      final allowed = await context.read<PushRepository>().permitted();
      if (mounted) setState(() => _pushAllowed = allowed);
    } on Object {
      // Sem permissão conhecida, o aviso não aparece.
    }
  }

  Map<String, String> get _params => {'course': widget.course.name};

  void _go(String name, {Map<String, String>? extra}) =>
      context.pushNamed(name, pathParameters: {..._params, ...?extra});

  Future<void> _enablePush() async {
    final push = context.read<PushRepository>();
    if (!await push.requestPermission()) await push.openSystemSettings();
    await _checkPush();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingGoalCubit>();
    return BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
      builder: (context, state) {
        final view = state.view;
        if (view == null) {
          if (state.failed) {
            return trainingLoadError(context, state.failure, cubit.load);
          }
          return const LoadSkeletonScreen();
        }
        return ListView(
          key: TrainingGoalKeys.guideTab,
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            if (!view.hasObjective)
              ..._empty(context)
            else if (!view.hasPlan)
              ..._noPlan(context)
            else if (!view.hasTournament)
              ..._improve(context, view)
            else
              ..._tournament(context, view, cubit),
            ..._tournaments(context, view),
          ],
        );
      },
    );
  }

  List<Widget> _empty(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return [
      Column(
        key: TrainingGoalKeys.guideEmpty,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            t.treinoNoGoalTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(t.treinoNoGoalGuideBody, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          BusyButton(
            buttonKey: TrainingGoalKeys.guideDefine,
            label: t.treinoDefineGoal,
            onPressed: () => _go(RouteNames.trainingGoal),
          ),
        ],
      ),
    ];
  }

  List<Widget> _noPlan(BuildContext context) {
    final t = context.l10n;
    return [
      Text(
        t.treinoGuidePlanHeader,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      BusyButton(
        buttonKey: TrainingGoalKeys.guideDefine,
        label: t.treinoContinue,
        onPressed: () => _go(RouteNames.trainingDiagnostic),
      ),
    ];
  }

  Widget _header(BuildContext context, GoalView view) {
    final t = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            t.treinoGuidePlanHeader,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TextButton(
          key: TrainingGoalKeys.guideChange,
          onPressed: () => _go(RouteNames.trainingGoal),
          child: Text(t.treinoGuideChange),
        ),
      ],
    );
  }

  List<Widget> _improve(BuildContext context, GoalView view) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final open = view.openChapters;
    final current = open.firstOrNull;
    final next = open.skip(1).firstOrNull;
    final more = open.length > 2 ? open.length - 2 : 0;
    Widget line(String label, String text, {Key? key}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LucenaCard(
        child: Column(
          key: key,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(text, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
    return [
      _header(context, view),
      Text(
        t.treinoGoalImproveLine(
          view.chapters.length - open.length,
          view.chapters.length,
        ),
        key: TrainingGoalKeys.guideImprove,
      ),
      const SizedBox(height: AppSpacing.md),
      if (current != null) ...[
        line(
          t.treinoImproveNow,
          t.treinoChapterLine(view.chapterNumber(current.id), current.title),
        ),
      ],
      if (next != null)
        line(
          t.treinoImproveNext,
          t.treinoChapterLine(view.chapterNumber(next.id), next.title),
        ),
      if (more > 0) Text(t.treinoImproveMore(more)),
    ];
  }

  List<Widget> _tournament(
    BuildContext context,
    GoalView view,
    TrainingGoalCubit cubit,
  ) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final name = view.tournamentName.isEmpty
        ? t.treinoTournamentDefault
        : view.tournamentName;
    final phase = view.phase!;
    final plan = view.plan!;
    final doneWeeks = [
      for (final w in plan.weeks)
        if (view.weekDone(w)) w,
    ];
    final late = view.late;
    return [
      _header(context, view),
      Text(
        t.treinoGuideTournamentLine(
          name,
          civilLong(context, view.tournamentDate!),
        ),
      ),
      if (phase == TournamentPhase.before)
        Text(
          t.treinoTournamentIn(view.daysLeft!),
          key: TrainingGoalKeys.guideNode,
          style: theme.textTheme.titleMedium,
        ),
      const SizedBox(height: AppSpacing.md),
      if (phase == TournamentPhase.before && !_pushAllowed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LucenaCard(
            child: Column(
              key: TrainingGoalKeys.guidePushDenied,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.treinoPushDenied),
                TextButton(
                  key: TrainingGoalKeys.guidePushEnable,
                  onPressed: _enablePush,
                  child: Text(t.treinoPushEnable),
                ),
              ],
            ),
          ),
        ),
      if (phase == TournamentPhase.day)
        LucenaCard(
          child: Column(
            key: TrainingGoalKeys.guideTournamentDay,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.treinoTournamentDay, style: theme.textTheme.titleMedium),
              Text(t.treinoTodayDate(civilLong(context, view.today))),
              if (view.openChapters.isEmpty)
                Text(t.treinoPlanDone, key: TrainingGoalKeys.guidePlanDone),
            ],
          ),
        ),
      if (view.awaitingRegister) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          t.treinoHowWas(
            name.toLowerCase() == t.treinoTournamentDefault.toLowerCase()
                ? t.treinoTournamentLower
                : name,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BusyButton(
          buttonKey: TrainingGoalKeys.guideRegister,
          label: t.treinoRegisterPerformance,
          onPressed: () => _go(RouteNames.trainingTournamentRegister),
        ),
      ],
      if (view.tournamentRegistered && phase != TournamentPhase.before) ...[
        const SizedBox(height: AppSpacing.sm),
        BusyButton(
          label: t.treinoNextGoalTitle,
          style: BusyButtonStyle.tonal,
          onPressed: () => _go(RouteNames.trainingNextGoal),
        ),
      ],
      if (late.isNotEmpty && phase == TournamentPhase.before)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LucenaCard(
            child: Column(
              key: TrainingGoalKeys.guideLate,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.treinoLateBadge,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                Text(
                  t.treinoLateBody(
                    view.chapterNumber(late.first.chapter.id),
                    late.first.week,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: TrainingGoalKeys.guideLateDismiss,
                      onPressed: cubit.dismissLateChapters,
                      child: Text(t.treinoNotNow),
                    ),
                    FilledButton(
                      key: TrainingGoalKeys.guideLateReplan,
                      onPressed: cubit.replanNow,
                      child: Text(t.treinoReplan),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      if (doneWeeks.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(t.treinoWeeksDone(doneWeeks.length)),
        ),
      for (final (i, w) in plan.weeks.indexed)
        if (!view.weekDone(w))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: WeekCard(
              key: TrainingGoalKeys.guideWeek(i),
              view: view,
              week: w,
              index: i,
              current: i == view.weekIndex,
              onTap: () =>
                  _go(RouteNames.trainingWeek, extra: {'week': '${i + 1}'}),
            ),
          ),
    ];
  }

  List<Widget> _tournaments(BuildContext context, GoalView view) {
    final t = context.l10n;
    return [
      const SizedBox(height: AppSpacing.lg),
      if (view.tournaments.isNotEmpty)
        ListTile(
          key: TrainingGoalKeys.guideMyTournaments,
          contentPadding: EdgeInsets.zero,
          title: Text(t.treinoMyTournaments),
          trailing: Text(t.treinoSeeAll),
          onTap: () => _go(RouteNames.trainingTournaments),
        )
      else if (view.hasObjective)
        TextButton(
          key: TrainingGoalKeys.guideMyTournaments,
          onPressed: () => _go(RouteNames.trainingTournamentRegister),
          child: Text(t.treinoRegisterTournament),
        ),
    ];
  }
}
