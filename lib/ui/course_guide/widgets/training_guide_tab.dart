import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../view_models/course_guide_cubit.dart';
import '../view_models/push_permission_cubit.dart';

import 'package:go_router/go_router.dart';

import '../../../config/view_models/push_permission.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../../domain/use_cases/training/goal/plan_chapters.dart';
import '../../../domain/use_cases/training/goal/tournament_rules.dart';
import '../../../routing/route_names.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_card.dart';
import '../../reminders/view_models/reminders_cubit.dart';
import '../../training_goal/view_models/training_goal_cubit.dart';
import '../../training_goal/widgets/goal_format.dart';
import '../../training_goal/widgets/goal_page.dart';
import '../../training_goal/widgets/plan_widgets.dart';
import 'training_load_error.dart';
import '../../core/motion/entrada_em_cascata.dart';

/// A aba Guia (H-TRE-05): o objetivo e o plano do curso, semana a semana.
class TrainingGuideTab extends StatelessWidget {
  const TrainingGuideTab({super.key, required this.course});
  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    final guide = context.read<CourseGuideCubit>();
    return BlocProvider(
      create: (context) => TrainingGoalCubit(
        repository: guide.repository,
        config: guide.config,
        now: guide.now,
        analytics: guide.analytics,
        initialResources: guide.state.partial ? null : guide.state.resources,
        afterSave: (_) async {
          try {
            await context.read<RemindersCubit>().refresh();
          } on ProviderNotFoundException {
            // Sem lembretes na árvore (por exemplo, em teste de tela).
          }
        },
      )..load(),
      child: BlocProvider(
        create: (context) => createPushPermissionCubit(context)..check(),
        child: _GuideBody(course: course),
      ),
    );
  }
}

class _GuideBody extends StatefulWidget {
  const _GuideBody({required this.course});
  final TrainingCourse course;

  @override
  State<_GuideBody> createState() => _GuideBodyState();
}

class _GuideBodyState extends State<_GuideBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PushPermissionCubit>().check();
    }
  }

  Map<String, String> get _params => {'course': widget.course.name};

  void _go(String name, {Map<String, String>? extra}) =>
      context.pushNamed(name, pathParameters: {..._params, ...?extra});

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
        if (!view.hasObjective) {
          return _Empty(onDefine: () => _go(RouteNames.trainingGoal));
        }
        // H-ANI-16: o guia entra em cascata na primeira vez.
        return _GuideContent(view: view, go: _go);
      },
    );
  }
}

/// O guia com objetivo: o plano (ou o convite a montá-lo), o torneio e as
/// semanas, cada bloco uma parte da cascata.
class _GuideContent extends StatelessWidget {
  const _GuideContent({required this.view, required this.go});

  final GoalView view;

  /// Abre uma tela do curso pelo nome da rota.
  final void Function(String name, {Map<String, String>? extra}) go;

  /// O nome do torneio; sem nome, "Torneio".
  String _tournamentName(AppLocalizations t) => view.tournamentName.isEmpty
      ? t.treinoTournamentDefault
      : view.tournamentName;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TrainingGoalCubit>();
    final filhos = [
      if (!view.hasPlan) ...[
        Text(t.treinoGuidePlanHeader, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        BusyButton(
          buttonKey: TrainingGoalKeys.guideDefine,
          label: t.treinoContinue,
          onPressed: () => go(RouteNames.trainingDiagnostic),
        ),
      ] else if (!view.hasTournament) ...[
        _Header(onChange: () => go(RouteNames.trainingGoal)),
        Text(
          t.treinoGoalImproveLine(
            view.chapters.length - view.openChapters.length,
            view.chapters.length,
          ),
          key: TrainingGoalKeys.guideImprove,
        ),
        const SizedBox(height: AppSpacing.md),
        if (view.openChapters.firstOrNull case final current?)
          _ChapterLine(label: t.treinoImproveNow, view: view, chapter: current),
        if (view.openChapters.skip(1).firstOrNull case final next?)
          _ChapterLine(label: t.treinoImproveNext, view: view, chapter: next),
        if (view.openChapters.length > 2)
          Text(t.treinoImproveMore(view.openChapters.length - 2)),
      ] else ...[
        _Header(onChange: () => go(RouteNames.trainingGoal)),
        Text(
          t.treinoGuideTournamentLine(
            _tournamentName(t),
            civilLong(context, view.tournamentDate!),
          ),
        ),
        if (view.phase == TournamentPhase.before)
          Text(
            t.treinoTournamentIn(view.daysLeft!),
            key: TrainingGoalKeys.guideNode,
            style: theme.textTheme.titleMedium,
          ),
        const SizedBox(height: AppSpacing.md),
        if (view.phase == TournamentPhase.before &&
            !context.watch<PushPermissionCubit>().state)
          const _PushDenied(),
        if (view.phase == TournamentPhase.day) _TournamentDay(view: view),
        if (view.awaitingRegister) ...[
          const SizedBox(height: AppSpacing.sm),
          _HowWas(name: _tournamentName(t)),
          const SizedBox(height: AppSpacing.sm),
          BusyButton(
            buttonKey: TrainingGoalKeys.guideRegister,
            label: t.treinoRegisterPerformance,
            onPressed: () => go(RouteNames.trainingTournamentRegister),
          ),
        ],
        if (view.tournamentRegistered &&
            view.phase != TournamentPhase.before) ...[
          const SizedBox(height: AppSpacing.sm),
          BusyButton(
            label: t.treinoNextGoalTitle,
            style: BusyButtonStyle.tonal,
            onPressed: () => go(RouteNames.trainingNextGoal),
          ),
        ],
        if (view.state.previousStudyPlan != null)
          _UndoAdjust(onPressed: cubit.undoLastAdjust),
        if (view.late.isNotEmpty && view.phase == TournamentPhase.before)
          _LateCard(view: view),
        if (view.plan!.weeks.where(view.weekDone).length case final done
            when done > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(t.treinoWeeksDone(done)),
          ),
        for (final (i, w) in view.plan!.weeks.indexed)
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
                    go(RouteNames.trainingWeek, extra: {'week': '${i + 1}'}),
              ),
            ),
      ],
      const SizedBox(height: AppSpacing.lg),
      if (view.tournaments.isNotEmpty || view.hasObjective)
        _MyTournaments(
          any: view.tournaments.isNotEmpty,
          onSeeAll: () => go(RouteNames.trainingTournaments),
          onRegister: () => go(RouteNames.trainingTournamentRegister),
        ),
    ];
    return ListView(
      key: TrainingGoalKeys.guideTab,
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        EntradaEmCascata(
          itens: [
            for (final (i, filho) in filhos.indexed)
              i == 0 ? ItemDaCascata.titulo(filho) : ItemDaCascata.texto(filho),
          ],
        ),
      ],
    );
  }
}

/// Um capítulo do plano num cartão: o rótulo (agora, depois) e o capítulo.
class _ChapterLine extends StatelessWidget {
  const _ChapterLine({
    required this.label,
    required this.view,
    required this.chapter,
  });

  final String label;
  final GoalView view;
  final PlanChapter chapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = context.l10n.treinoChapterLine(
      view.chapterNumber(chapter.id),
      chapter.title,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LucenaCard(
        child: Column(
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
  }
}

/// "Como foi o torneio?": com o nome padrão, "o torneio" em minúsculas.
class _HowWas extends StatelessWidget {
  const _HowWas({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Text(
      t.treinoHowWas(
        name.toLowerCase() == t.treinoTournamentDefault.toLowerCase()
            ? t.treinoTournamentLower
            : name,
      ),
    );
  }
}

/// Desfazer o último ajuste do plano, à direita.
class _UndoAdjust extends StatelessWidget {
  const _UndoAdjust({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        key: TrainingGoalKeys.adjustUndo,
        onPressed: onPressed,
        child: Text(context.l10n.treinoUndoAdjust),
      ),
    );
  }
}

/// "Meus torneios" com "Ver todos"; sem torneio ainda, o botão de registrar.
class _MyTournaments extends StatelessWidget {
  const _MyTournaments({
    required this.any,
    required this.onSeeAll,
    required this.onRegister,
  });

  /// Já há torneio registrado.
  final bool any;
  final VoidCallback onSeeAll;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (any) {
      return ListTile(
        key: TrainingGoalKeys.guideMyTournaments,
        contentPadding: EdgeInsets.zero,
        title: Text(t.treinoMyTournaments),
        trailing: Text(t.treinoSeeAll),
        onTap: onSeeAll,
      );
    }
    return TextButton(
      key: TrainingGoalKeys.guideMyTournaments,
      onPressed: onRegister,
      child: Text(t.treinoRegisterTournament),
    );
  }
}

/// Lembretes negados antes do torneio: o aviso e o botão de ativar.
class _PushDenied extends StatelessWidget {
  const _PushDenied();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: LucenaCard(
        child: Column(
          key: TrainingGoalKeys.guidePushDenied,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.treinoPushDenied),
            TextButton(
              key: TrainingGoalKeys.guidePushEnable,
              onPressed: context.read<PushPermissionCubit>().enable,
              child: Text(t.treinoPushEnable),
            ),
          ],
        ),
      ),
    );
  }
}

/// O dia do torneio: o aviso, a data e, com o plano feito, o "tudo pronto".
class _TournamentDay extends StatelessWidget {
  const _TournamentDay({required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return LucenaCard(
      child: Column(
        key: TrainingGoalKeys.guideTournamentDay,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.treinoTournamentDay,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(t.treinoTodayDate(civilLong(context, view.today))),
          if (view.openChapters.isEmpty)
            Text(t.treinoPlanDone, key: TrainingGoalKeys.guidePlanDone),
        ],
      ),
    );
  }
}

/// Capítulos atrasados: o aviso, "Agora não" e "Replanejar".
class _LateCard extends StatelessWidget {
  const _LateCard({required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TrainingGoalCubit>();
    final late = view.late;
    return Padding(
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
    );
  }
}

/// PropV2GuiaSemObjetivo: o convite num cartão e o botão fixo embaixo.
class _Empty extends StatelessWidget {
  const _Empty({required this.onDefine});

  final VoidCallback onDefine;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: TrainingGoalKeys.guideTab,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              LucenaCard(
                key: TrainingGoalKeys.guideEmpty,
                padding: const EdgeInsets.all(24),
                // H-ANI-16: ícone, título e convite em cascata.
                child: EntradaEmCascata(
                  montar: (itens) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: itens,
                  ),
                  itens: [
                    ItemDaCascata.selo(
                      Icon(
                        Icons.stadium_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    ItemDaCascata.titulo(
                      Text(
                        t.treinoNoGoalTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ItemDaCascata.texto(Text(t.treinoNoGoalGuideBody)),
                  ],
                ),
              ),
            ],
          ),
        ),
        GoalFooter(
          child: BusyButton(
            buttonKey: TrainingGoalKeys.guideDefine,
            label: t.treinoDefineGoal,
            onPressed: onDefine,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
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
          onPressed: onChange,
          child: Text(t.treinoGuideChange),
        ),
      ],
    );
  }
}
