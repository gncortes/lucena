import 'package:flutter/material.dart';

import '../../../domain/models/endgame_position.dart' show PositionGoal;
import '../../../domain/models/pace.dart';
import '../../../domain/models/player_rating.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/goal_style.dart';
import '../../history/widgets/history_labels.dart';

/// O cartão verde do bônus de rating de um speedrun (clássico e Maratona).
///
/// Dois usos, o mesmo visual (artboard da Maratona, contrato lote 1):
/// - [SpeedrunRatingBonusCard.offer]: antes de concluir, "Conclua para ganhar
///   +N de rating" com a dica do ritmo. Com `points <= 0` (já pago ou sem
///   bônus) não ocupa espaço.
/// - [SpeedrunRatingBonusCard.earned]: depois de concluir, "+N de rating
///   (antes → depois)". Com `bonus.points <= 0` não ocupa espaço.
///
/// Os números ("+N" e "antes → depois") ficam sempre LTR, também em árabe.
class SpeedrunRatingBonusCard extends StatelessWidget {
  /// A oferta de [points] ao concluir, valendo no grupo [group] de ritmo.
  const SpeedrunRatingBonusCard.offer({
    required int this.points,
    required PaceCategory this.group,
    super.key,
  }) : bonus = null;

  /// O [bonus] já pago.
  const SpeedrunRatingBonusCard.earned({
    required SpeedrunBonus this.bonus,
    super.key,
  }) : points = null,
       group = null;

  final int? points;
  final PaceCategory? group;
  final SpeedrunBonus? bonus;

  bool get _isOffer => bonus == null;

  @override
  Widget build(BuildContext context) {
    final amount = _isOffer ? points! : bonus!.points;
    if (amount <= 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = GoalStyle.of(context, PositionGoal.win);
    final title = _isolate(
      _isOffer
          ? l10n.speedrunRatingBonusOffer(amount)
          : l10n.speedrunRatingBonusEarned(
              amount,
              bonus!.before.rounded,
              bonus!.after.rounded,
            ),
    );
    final hint = _isOffer
        ? l10n.speedrunRatingBonusOfferHint(group!.label(l10n))
        : null;
    return MergeSemantics(
      child: Card(
        key: _isOffer
            ? SpeedrunKeys.ratingBonusOffer
            : SpeedrunKeys.ratingBonusEarned,
        color: style.container,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Círculo de 40 com o ícone de 24 (artboard da Maratona).
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.trending_up,
                    size: AppIconSize.standard,
                    color: style.color,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.cardTitle?.copyWith(
                        color: style.onContainer,
                      ),
                    ),
                    if (hint != null) ...[
                      // 2 no artboard.
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: style.onContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "+N" e "antes → depois" isolados como LTR dentro do texto.
  static String _isolate(String text) => text.replaceAllMapped(
    RegExp(r'\d+ → \d+|\+\d+'),
    (match) => HistoryLabels.ltr(match[0]!),
  );
}
