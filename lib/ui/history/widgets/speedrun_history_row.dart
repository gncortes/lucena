import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/speedrun_history_rows.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/history_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/time_display.dart';
import '../../speedrun/widgets/speedrun_ui.dart';
import 'history_labels.dart';

/// Uma linha do Clássico ou da Maratona: a peça, o final, o ritmo e a
/// situação (bônus, recorde novo ou até onde chegou); à direita o recorde e
/// as tentativas. Tocar abre o histórico do speedrun ([onTap]).
class SpeedrunHistoryRowTile extends StatelessWidget {
  const SpeedrunHistoryRowTile({
    required this.row,
    required this.index,
    required this.characters,
    required this.onTap,
    super.key,
  });

  final SpeedrunHistoryRow row;

  /// O índice na aba (das keys).
  final int index;
  final List<Character> characters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final speedrun = row.speedrun;
    final small = theme.textTheme.bodySmall;
    final record = row.record;
    final recordText = record == null
        ? null
        : runTime(context, recordTime(speedrun, record));
    // A situação, uma só: bônus, recorde novo, até onde chegou.
    final (IconData?, Color, String?, Key?) status = switch (row) {
      SpeedrunHistoryRow(:final bonus?) => (
        Icons.trending_up,
        ChangeColors.of(context, up: true),
        HistoryLabels.ltr(l10n.speedrunRatingBonusShort(bonus)),
        HistoryKeys.rowBonus(index),
      ),
      SpeedrunHistoryRow(newRecord: true) => (
        Icons.emoji_events,
        GoalStyle.of(context, PositionGoal.win).color,
        l10n.historyNewRecord,
        null,
      ),
      SpeedrunHistoryRow(:final bestStage?) when !row.finished => (
        Icons.stairs_outlined,
        colors.onSurfaceVariant,
        l10n.speedrunBestShort(bestStage, row.stages),
        null,
      ),
      _ => (null, colors.onSurfaceVariant, null, null),
    };
    final (statusIcon, statusColor, statusText, statusKey) = status;
    return InkWell(
      key: HistoryKeys.row(index),
      onTap: onTap,
      child: Padding(
        // Padding 12 (topo, base, início) e 4 (fim), gap 12 (artboard).
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            SpeedrunPicture(speedrun, characters: characters, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Na aba Maratona o "Maratona:" do nome se repete: só o
                    // final, como no canvas.
                    speedrun.kind == SpeedrunKind.marathon
                        ? endgameName(
                            l10n,
                            speedrun.stages.first.position.subcategory,
                          )
                        : speedrunName(l10n, characters, speedrun),
                    // Duas linhas só com a fonte grande (contrato §4).
                    maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.3
                        ? 2
                        : 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.cardTitle,
                  ),
                  Text(
                    HistoryLabels.ltr(paceLabel(l10n, speedrun.time)),
                    style: small?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (statusText != null)
                    Row(
                      key: HistoryKeys.rowStatus(index),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: AppIconSize.small,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            statusText,
                            key: statusKey,
                            style: small?.copyWith(color: statusColor),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recordText != null)
                  TimeDisplay(
                    value: recordText,
                    semanticsLabel:
                        '${speedrun.kind == SpeedrunKind.marathon ? l10n.marathonBest : l10n.speedrunBest}: $recordText',
                    type: TimeDisplayType.record,
                    size: TimeDisplaySize.inline,
                    state: row.newRecord
                        ? TimeDisplayState.highlight
                        : TimeDisplayState.normal,
                  ),
                Text(
                  l10n.historyAttemptsCount(row.attempts),
                  style: small?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
