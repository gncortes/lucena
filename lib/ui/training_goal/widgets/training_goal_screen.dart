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
        return [
          Text(t.treinoGoalIntro),
          const SizedBox(height: AppSpacing.lg),
          _Option(
            optionKey: TrainingGoalKeys.goalTournament,
            title: t.treinoGoalTournament,
            subtitle: t.treinoGoalTournamentSub,
            selected: _kind == ObjectiveKind.tournament,
            onTap: () => setState(() => _kind = ObjectiveKind.tournament),
          ),
          if (_kind == ObjectiveKind.tournament) ...[
            const SizedBox(height: AppSpacing.sm),
            LucenaCard(
              onTap: () => _pick(today),
              child: Row(
                key: TrainingGoalKeys.goalDateRow,
                children: [
                  Expanded(child: Text(t.treinoGoalDateRow)),
                  Text(
                    _date == null
                        ? t.treinoGoalPickDate
                        : civilLong(context, _date!),
                  ),
                ],
              ),
            ),
            if (_pastError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  t.treinoDatePast,
                  key: TrainingGoalKeys.goalDateError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_date == tomorrow)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  t.treinoTomorrowWarning,
                  key: TrainingGoalKeys.goalTomorrowWarning,
                ),
              ),
            if (_date != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: TrainingGoalKeys.goalAddToCalendar,
                  onPressed: _calendar,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(t.treinoAddToCalendar),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _Option(
            optionKey: TrainingGoalKeys.goalImprove,
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

class _Option extends StatelessWidget {
  const _Option({
    required this.optionKey,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final Key optionKey;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      child: LucenaCard(
        onTap: onTap,
        child: Row(
          key: optionKey,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? theme.colorScheme.primary : null,
            ),
          ],
        ),
      ),
    );
  }
}
