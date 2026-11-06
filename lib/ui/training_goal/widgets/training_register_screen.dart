import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/goal/tournament_record.dart';
import '../../../domain/use_cases/training/goal/goal_actions.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_format.dart';
import 'goal_page.dart';

/// Registrar desempenho (H-TRE-14). O rascunho é gravado a cada campo;
/// fechar o app e voltar mantém tudo.
class TrainingRegisterScreen extends StatefulWidget {
  const TrainingRegisterScreen({
    required this.onBack,
    required this.onRegistered,
    super.key,
  });
  final VoidCallback onBack, onRegistered;

  @override
  State<TrainingRegisterScreen> createState() => _TrainingRegisterScreenState();
}

class _TrainingRegisterScreenState extends State<TrainingRegisterScreen> {
  final _name = TextEditingController();
  final _points = TextEditingController();
  final _rounds = TextEditingController();
  final _before = TextEditingController();
  final _after = TextEditingController();
  final _notes = TextEditingController();
  TournamentDraft _draft = const TournamentDraft();
  bool _loaded = false, _submitted = false;

  @override
  void dispose() {
    for (final c in [_name, _points, _rounds, _before, _after, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(TournamentDraft d) {
    _draft = d;
    _name.text = d.name;
    _points.text = d.points;
    _rounds.text = d.rounds;
    _before.text = d.ratingBefore;
    _after.text = d.ratingAfter;
    _notes.text = d.notes;
    _loaded = true;
  }

  void _change(TournamentDraft next) {
    setState(() => _draft = next);
    context.read<TrainingGoalCubit>().saveDraft(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    return GoalPage(
      centerTitle: false,
      screenKey: TrainingGoalKeys.registerScreen,
      title: t.treinoRegisterTitle,
      onBack: widget.onBack,
      builder: (context, view) {
        if (!_loaded) _fill(view.registerDraft);
        final error = _submitted ? draftError(_draft, today: view.today) : null;
        final before = int.tryParse(_draft.ratingBefore);
        final after = int.tryParse(_draft.ratingAfter);
        return [
          TextField(
            key: TrainingGoalKeys.registerName,
            controller: _name,
            decoration: InputDecoration(labelText: t.treinoFieldTournament),
            onChanged: (v) => _change(_draft.copyWith(name: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          InputDecorator(
            key: TrainingGoalKeys.registerDate,
            decoration: InputDecoration(labelText: t.treinoFieldDate),
            child: Text(
              _draft.date.isEmpty ? '' : civilLong(context, _draft.date),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.md),
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: TextField(
                  key: TrainingGoalKeys.registerPoints,
                  controller: _points,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: t.treinoFieldPoints,
                    errorText: error == DraftError.points
                        ? t.treinoPointsRequired
                        : error == DraftError.pointsTooHigh
                        ? t.treinoPointsTooHigh
                        : null,
                  ),
                  onChanged: (v) => _change(_draft.copyWith(points: v)),
                ),
              ),
              Expanded(
                child: TextField(
                  key: TrainingGoalKeys.registerRounds,
                  controller: _rounds,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: t.treinoFieldRounds,
                    errorText: error == DraftError.rounds
                        ? t.treinoRoundsRequired
                        : error == DraftError.roundsTooMany
                        ? t.treinoRoundsMax
                        : null,
                  ),
                  onChanged: (v) => _change(_draft.copyWith(rounds: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: TextField(
                  key: TrainingGoalKeys.registerRatingBefore,
                  controller: _before,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: t.treinoFieldRatingBefore,
                  ),
                  onChanged: (v) => _change(_draft.copyWith(ratingBefore: v)),
                ),
              ),
              Expanded(
                child: TextField(
                  key: TrainingGoalKeys.registerRatingAfter,
                  controller: _after,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: t.treinoFieldRatingAfter,
                  ),
                  onChanged: (v) => _change(_draft.copyWith(ratingAfter: v)),
                ),
              ),
            ],
          ),
          if (before != null && after != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                t.treinoRatingDelta(
                  '${after - before >= 0 ? '+' : ''}${after - before}',
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            t.treinoFieldPace,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final p in TournamentPace.values)
                ChoiceChip(
                  key: TrainingGoalKeys.registerPace(p.name),
                  label: Text(switch (p) {
                    TournamentPace.classical => t.treinoPaceClassical,
                    TournamentPace.rapid => t.treinoPaceRapid,
                    TournamentPace.blitz => t.treinoPaceBlitz,
                  }),
                  selected: _draft.pace == p,
                  onSelected: (_) => _change(_draft.copyWith(pace: p)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.treinoFieldEntity,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final e in TournamentEntity.values)
                ChoiceChip(
                  key: TrainingGoalKeys.registerEntity(e.name),
                  label: Text(switch (e) {
                    TournamentEntity.fide => t.treinoEntityFide,
                    TournamentEntity.cbx => t.treinoEntityCbx,
                    TournamentEntity.online => t.treinoEntityOnline,
                    TournamentEntity.other => t.treinoEntityOther,
                  }),
                  selected: _draft.entity == e,
                  onSelected: (_) => _change(_draft.copyWith(entity: e)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            t.treinoFeelingTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final (i, label) in [
                t.treinoFeeling1,
                t.treinoFeeling2,
                t.treinoFeeling3,
                t.treinoFeeling4,
                t.treinoFeeling5,
              ].indexed)
                ChoiceChip(
                  key: TrainingGoalKeys.registerFeeling(i + 1),
                  label: Text(label),
                  selected: _draft.feeling == i + 1,
                  onSelected: (_) => _change(_draft.copyWith(feeling: i + 1)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: TrainingGoalKeys.registerNotes,
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(labelText: t.treinoNotes),
            onChanged: (v) => _change(_draft.copyWith(notes: v)),
          ),
        ];
      },
      footer: (context, view) =>
          BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
            builder: (context, state) => BusyButton(
              buttonKey: TrainingGoalKeys.registerSave,
              label: t.treinoSave,
              busy: state.saving,
              onPressed: () async {
                setState(() => _submitted = true);
                if (draftError(_draft, today: view.today) != null) return;
                final messenger = ScaffoldMessenger.of(context);
                if (await cubit.register(_draft)) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(t.treinoRegistered)),
                  );
                  widget.onRegistered();
                }
              },
            ),
          ),
    );
  }
}
