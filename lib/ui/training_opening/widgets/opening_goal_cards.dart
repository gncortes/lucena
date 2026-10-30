import 'package:flutter/material.dart';

import '../../core/theme/app_shape.dart';

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
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final goal = saved.day?.goals.where((g) => g.items.isNotEmpty).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final entry in activeOpeningTracks(saved, resources))
          Builder(
            builder: (context) {
              final bank = resources.openings[entry.key]!;
              final progress = OpeningTrechoRules.currentProgress(
                entry.value,
                bank,
              );
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
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  bank.first.black ? t.sideBlack : t.sideWhite,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            t.trainingOpeningCount(progress.done, bank.length),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      Row(
                        spacing: 6,
                        children: [
                          for (final (i, part) in bank.indexed)
                            Expanded(
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color:
                                      entry.value.doneTrechos.containsKey(
                                        part.id,
                                      )
                                      ? AppColors.record
                                      : available && i == index
                                      ? colors.primary
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppShape.small,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child:
                                    entry.value.doneTrechos.containsKey(part.id)
                                    ? Icon(
                                        Icons.check,
                                        size: AppIconSize.small,
                                        color: colors.onPrimary,
                                      )
                                    : Text(
                                        '${i + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: available && i == index
                                                  ? colors.onPrimary
                                                  : colors.onSurfaceVariant,
                                            ),
                                      ),
                              ),
                            ),
                        ],
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
                                  t.trainingOpeningTrain(
                                    index + 1,
                                    bank[index].title,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      if (!available || progress.done == bank.length)
                        Row(
                          spacing: 8,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: AppIconSize.button,
                              color: AppColors.record,
                            ),
                            Expanded(
                              child: Text(
                                progress.done == bank.length
                                    ? t.trainingOpeningAllFirm
                                    : t.trainingOpeningDoneToday,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.record,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
