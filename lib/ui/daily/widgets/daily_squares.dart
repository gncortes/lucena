import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/daily_final.dart';
import '../../../domain/models/endgame_position.dart';
import '../../core/l10n/l10n.dart';
import '../../core/keys/daily_keys.dart';

/// Os quadradinhos dos lances, em fileiras de [perRow], centradas.
class DailySquares extends StatelessWidget {
  const DailySquares({
    required this.squares,
    required this.size,
    required this.gap,
    required this.radius,
    this.perRow = 10,
    super.key,
  });

  final List<DailySquare> squares;
  final double size;
  final double gap;
  final double radius;
  final int perRow;

  @override
  Widget build(BuildContext context) => Column(
    key: DailyKeys.squares,
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: [
      for (var start = 0; start < squares.length; start += perRow)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: gap,
          children: [
            for (var i = start; i < squares.length && i < start + perRow; i++)
              DecoratedBox(
                key: DailyKeys.square(i),
                decoration: BoxDecoration(
                  color: dailySquareColor(context, squares[i]),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: SizedBox.square(dimension: size),
              ),
          ],
        ),
    ],
  );
}

/// A cor de um lance: verde certo, dourado mais devagar, vermelho estragou.
Color dailySquareColor(BuildContext context, DailySquare square) =>
    switch (square) {
      DailySquare.right => AppColors.record,
      DailySquare.slow => AppColors.goldColor,
      DailySquare.bad => Theme.of(context).colorScheme.error,
    };

/// A legenda das cores que aparecem (o amarelo só com a tablebase de
/// distância, que o app ainda não tem).
class DailyLegend extends StatelessWidget {
  const DailyLegend({required this.squares, super.key});

  final List<DailySquare> squares;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final shown = [
      DailySquare.right,
      if (squares.contains(DailySquare.slow)) DailySquare.slow,
      DailySquare.bad,
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final square in shown)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: dailySquareColor(context, square),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: const SizedBox.square(dimension: AppSpacing.md),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(switch (square) {
                DailySquare.right => l10n.dailyLegendRight,
                DailySquare.slow => l10n.dailyLegendSlow,
                DailySquare.bad => l10n.dailyLegendBad,
              }, style: style),
            ],
          ),
      ],
    );
  }
}

/// "22 de outubro".
String dailyDate(BuildContext context, DateTime date) =>
    DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(date);

/// O título do resultado; no final de empatar, empatar é segurar.
String dailyResultTitle(
  AppLocalizations l10n,
  DailyRecord record,
  PositionGoal? goal, {
  bool past = false,
}) => switch (record.outcome) {
  DailyOutcome.won => past ? l10n.dailyWonYesterday : l10n.dailyWon,
  DailyOutcome.drew when goal == PositionGoal.draw =>
    past ? l10n.dailyHeldYesterday : l10n.dailyHeld,
  DailyOutcome.drew => past ? l10n.dailyDrewYesterday : l10n.dailyDrew,
  DailyOutcome.lost => l10n.dailyLost,
};

/// "Ganhei em 5 lances", na imagem.
String dailyImageLine(AppLocalizations l10n, DailyRecord record) =>
    switch (record.outcome) {
      DailyOutcome.won => l10n.dailyShareImageWon(record.moves),
      DailyOutcome.drew => l10n.dailyShareImageDrew(record.moves),
      DailyOutcome.lost => l10n.dailyShareImageLost(record.moves),
    };
