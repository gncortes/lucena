import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/models/challenge_result.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import 'challenge_result_ui.dart';

/// O cartão que vira imagem: o cabeçalho azul com o resultado e, embaixo, o
/// tabuleiro final (com o último lance e o rei em xeque-mate), o adversário,
/// o convite e o link.
class ChallengeResultCard extends StatelessWidget {
  const ChallengeResultCard({
    required this.result,
    required this.opponent,
    super.key,
  });

  final ChallengeResult result;
  final String opponent;

  /// O lado da miniatura.
  static const _board = 132.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final parts = l10n.challengeImageAgainst('\u0001').split('\u0001');
    final position = GameRules.fromFen(result.finalFen);
    final king = position != null && position.isCheck
        ? position.board.kingOf(position.turn)
        : null;
    return ClipRRect(
      key: ChallengeKeys.resultCard,
      borderRadius: BorderRadius.circular(AppShape.extraLarge),
      child: ColoredBox(
        color: colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: colors.primary,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      challengeResultHeader(l10n, result),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      challengeResultSentence(l10n, result),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                spacing: AppSpacing.lg,
                children: [
                  PositionBoard(
                    fen: result.finalFen,
                    size: _board,
                    orientation: result.link.userSide,
                    lastMove: result.lastMove,
                    shapes: {
                      if (king != null) Circle(color: colors.error, orig: king),
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.sm,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: parts.first),
                              TextSpan(
                                text: opponent,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (parts.length > 1)
                                TextSpan(text: parts.sublist(1).join()),
                            ],
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          l10n.challengeCanYouFaster,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          result.link.shortAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
