import 'package:flutter/material.dart';

import '../../core/theme/app_shape.dart';
import '../../core/theme/canvas_symbols.dart';

import '../../../domain/models/training/day_goals.dart';
import '../../../domain/models/training/opening_track.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/training/opening_parts.dart';
import '../../../domain/use_cases/training/opening_trecho_rules.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';

class OpeningGoalCards extends StatelessWidget {
  const OpeningGoalCards({
    required this.saved,
    required this.resources,
    required this.onTrain,
    super.key,
  });
  final TrainingState saved;
  final TrainingResources resources;
  final ValueChanged<String> onTrain;
  @override
  Widget build(BuildContext context) {
    final goal = saved.day?.goals.where((g) => g.items.isNotEmpty).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final entry in activeOpeningTracks(saved, resources))
          _OpeningTrackCard(
            entry: entry,
            saved: saved,
            resources: resources,
            goal: goal,
            onTrain: onTrain,
          ),
      ],
    );
  }
}

/// O cartão de um tema de abertura: título, partes feitas e o botão do trecho.
class _OpeningTrackCard extends StatelessWidget {
  const _OpeningTrackCard({
    required this.entry,
    required this.saved,
    required this.resources,
    required this.goal,
    required this.onTrain,
  });

  final MapEntry<String, OpeningTrack> entry;
  final TrainingState saved;
  final TrainingResources resources;
  final TrainingGoal? goal;
  final ValueChanged<String> onTrain;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    final bank = resources.openings[entry.key]!;
    final progress = OpeningTrechoRules.currentProgress(entry.value, bank);
    final id = goal?.items[entry.key];
    final index = bank.indexWhere((p) => p.id == id);
    final doneToday =
        id != null && entry.value.doneTrechos[id] == saved.day?.date;
    final available = index >= 0 && !doneToday;
    final title = bank.first.lines.isNotEmpty
        ? bank.first.title
        : resources.lessons
                  .where((l) => l.id == entry.key)
                  .firstOrNull
                  ?.title ??
              bank.first.title;
    return Card(
      key: TrainingKeys.openingCard(entry.key),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            _TrackHeader(
              title: title,
              black: bank.first.black,
              done: progress.done,
              total: bank.length,
            ),
            _TrackParts(
              track: entry.value,
              bank: bank,
              available: available,
              index: index,
            ),
            if (available)
              TextButton(
                key: TrainingKeys.trainTrecho(entry.key),
                onPressed: () => onTrain(entry.key),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.trainingOpeningTrain(index + 1, bank[index].title),
                      ),
                    ),
                    const Icon(
                      CanvasSymbols.chevronRight,
                      size: AppIconSize.button,
                    ),
                  ],
                ),
              ),
            if (!available || progress.done == bank.length)
              _TrackDone(
                trackId: entry.key,
                allDone: progress.done == bank.length,
              ),
          ],
        ),
      ),
    );
  }
}

/// O título do tema, o lado e quantas partes estão feitas.
class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.title,
    required this.black,
    required this.done,
    required this.total,
  });

  final String title;
  final bool black;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                black ? t.sideBlack : t.sideWhite,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(height: 16 / 12, color: colors.onSurface),
              ),
            ],
          ),
        ),
        Text(
          t.trainingOpeningCount(done, total),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// As partes do tema, uma casa por parte.
class _TrackParts extends StatelessWidget {
  const _TrackParts({
    required this.track,
    required this.bank,
    required this.available,
    required this.index,
  });

  final OpeningTrack track;
  final List<OpeningTrecho> bank;
  final bool available;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      spacing: 6,
      children: [
        for (final (i, part) in bank.indexed)
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: track.doneTrechos.containsKey(part.id)
                    ? AppColors.record
                    : available && i == index
                    ? colors.primary
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppShape.small),
              ),
              alignment: Alignment.center,
              child: track.doneTrechos.containsKey(part.id)
                  ? Icon(
                      CanvasSymbols.check,
                      size: AppIconSize.small,
                      color: colors.onPrimary,
                    )
                  : Text(
                      '${i + 1}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: available && i == index
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

/// O aviso de que o tema está firme ou já treinado hoje.
class _TrackDone extends StatelessWidget {
  const _TrackDone({required this.trackId, required this.allDone});

  final String trackId;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      spacing: 8,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: AppIconSize.button,
          color: AppColors.record,
        ),
        Expanded(
          child: Text(
            allDone ? t.trainingOpeningAllFirm : t.trainingOpeningDoneToday,
            key: allDone ? TrainingKeys.openingAllPartsDone(trackId) : null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.record,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
