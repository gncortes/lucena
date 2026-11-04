import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/training/goal/training_objective.dart';
import '../../../domain/use_cases/training/goal/tournament_rules.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_format.dart';
import 'goal_page.dart';

/// "Seu objetivo" (H-TRE-06): torneio com data a partir de amanhã, ou só melhorar.
class TrainingGoalScreen extends StatefulWidget {
  const TrainingGoalScreen({
    required this.onBack,
    required this.onContinue,
    super.key,
  });
  final VoidCallback onBack;

  /// Depois de gravar o objetivo; recebe a data do torneio (ou nulo).
  final void Function(String? tournamentDate) onContinue;

  @override
  State<TrainingGoalScreen> createState() => _TrainingGoalScreenState();
}

class _TrainingGoalScreenState extends State<TrainingGoalScreen> {
  ObjectiveKind? _kind;
  String? _date;
  bool _pastError = false;

  Future<void> _pick(String today) async {
    final first = DateTime.parse(earliestTournamentDate(today));
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365 * 2)),
      initialDate: _date == null ? first : DateTime.parse(_date!),
      helpText: context.l10n.treinoDatePickerHelp,
    );
    if (picked == null || !mounted) return;
    final key = civilKey(picked);
    setState(() {
      _date = isValidTournamentDate(key, today) ? key : null;
      _pastError = !isValidTournamentDate(key, today);
    });
  }

  Future<void> _calendar() async {
    final date = _date;
    if (date == null) return;
    final day = DateTime.parse(date);
    try {
      // Intent do calendário do aparelho; sem pacote novo.
      await AndroidIntent(
        action: 'android.intent.action.INSERT',
        data: 'content://com.android.calendar/events',
        arguments: <String, dynamic>{
          'title': context.l10n.treinoTournamentDefault,
          'beginTime': day.millisecondsSinceEpoch,
          'endTime': day.add(const Duration(days: 1)).millisecondsSinceEpoch,
          'allDay': true,
        },
      ).launch();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
  }

  bool get _ready =>
      _kind == ObjectiveKind.improve ||
      (_kind == ObjectiveKind.tournament && _date != null);

  Future<void> _continue(TrainingGoalCubit cubit) async {
    final kind = _kind;
    if (kind == null || !_ready) return;
    final date = kind == ObjectiveKind.tournament ? _date : null;
    if (await cubit.setObjective(kind: kind, date: date) && mounted) {
      widget.onContinue(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    return GoalPage(
      screenKey: TrainingGoalKeys.goalScreen,
      title: t.treinoGoalTitle,
      onBack: widget.onBack,
      builder: (context, view) {
        final today = view.today;
        final tomorrow = earliestTournamentDate(today);
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        final date = _date;
        return [
          Text(t.treinoGoalIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          _Option(
            optionKey: TrainingGoalKeys.goalTournament,
            icon: Icons.stadium_outlined,
            title: t.treinoGoalTournament,
            subtitle: t.treinoGoalTournamentSub,
            selected: _kind == ObjectiveKind.tournament,
            onTap: () => setState(() => _kind = ObjectiveKind.tournament),
            extra: _kind != ObjectiveKind.tournament
                ? null
                : [
                    const Divider(height: 1),
                    // Linha que abre o seletor: ícone, rótulo, data e seta.
                    InkWell(
                      key: TrainingGoalKeys.goalDateRow,
                      onTap: () => _pick(today),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            spacing: AppSpacing.lg,
                            children: [
                              Icon(Icons.event, color: muted),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.treinoGoalDateRow,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(color: muted),
                                    ),
                                    Text(
                                      date == null
                                          ? t.treinoGoalPickDate
                                          : civilLong(context, date),
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    if (date != null)
                                      Text(
                                        t.treinoDaysLeft(
                                          daysUntil(today, date),
                                        ),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: muted),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_pastError)
                      Text(
                        t.treinoDatePast,
                        key: TrainingGoalKeys.goalDateError,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    if (date == tomorrow)
                      Text(
                        t.treinoTomorrowWarning,
                        key: TrainingGoalKeys.goalTomorrowWarning,
                      ),
                    if (date != null)
                      Center(
                        child: TextButton.icon(
                          key: TrainingGoalKeys.goalAddToCalendar,
                          onPressed: _calendar,
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text(t.treinoAddToCalendar),
                        ),
                      ),
                  ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Option(
            optionKey: TrainingGoalKeys.goalImprove,
            icon: Icons.trending_up,
            title: t.treinoGoalImprove,
            subtitle: t.treinoGoalImproveSub,
            selected: _kind == ObjectiveKind.improve,
            onTap: () => setState(() => _kind = ObjectiveKind.improve),
          ),
        ];
      },
      footer: (context, view) =>
          BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
            builder: (context, state) => BusyButton(
              buttonKey: TrainingGoalKeys.goalContinue,
              label: t.treinoContinue,
              busy: state.saving,
              onPressed: _ready ? () => _continue(cubit) : null,
            ),
          ),
    );
  }
}

/// CompOpcaoLista (rádio com ícone). Com [extra], o que a opção marcada abre
/// fica dentro do mesmo cartão (a data do torneio no PropV2MetaInicio).
class _Option extends StatelessWidget {
  const _Option({
    required this.optionKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.extra,
  });
  final Key optionKey;
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  final List<Widget>? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final header = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          spacing: AppSpacing.lg,
          children: [
            Icon(icon, color: colors.primary),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected ? colors.primary : colors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
    final more = extra;
    return Semantics(
      key: optionKey,
      selected: selected,
      child: LucenaCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (more != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: more,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
