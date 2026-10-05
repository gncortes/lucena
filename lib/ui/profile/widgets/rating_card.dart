import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/player_rating.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/rating_cubit.dart';

/// O rating de finais: o número, se ainda é provisório, a curva das partidas e
/// o que ele mede.
class RatingCard extends StatelessWidget {
  const RatingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final state = context.watch<RatingCubit>().state;
    final current = state.current;
    if (current == null) return const SizedBox.shrink();
    return Card(
      key: ProfileKeys.ratingCard,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileEndgameRating,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                // O número grande e, ao lado, a variação da última partida.
                RatingValue(
                  rating: current.rounded,
                  change: state.lastChange,
                  large: true,
                  valueKey: ProfileKeys.ratingValue,
                  changeKey: ProfileKeys.ratingDelta,
                ),
                if (state.provisional)
                  Chip(
                    label: Text(l10n.profileRatingProvisional),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
              ],
            ),
            Text(
              state.history.isEmpty
                  ? l10n.profileRatingStart
                  : l10n.profileRatingGames(state.history.length),
              key: ProfileKeys.ratingGames,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (state.history.length > 1) ...[
              const SizedBox(height: 12),
              ExcludeSemantics(
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: CustomPaint(
                    key: ProfileKeys.ratingChart,
                    painter: _Curve(
                      [for (final entry in state.history) entry.rating],
                      line: colors.primary,
                      fill: colors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.profileRatingHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A curva do rating partida a partida.
class _Curve extends CustomPainter {
  _Curve(this.ratings, {required this.line, required this.fill});

  final List<PlayerRating> ratings;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [for (final rating in ratings) rating.rating];
    final low = values.reduce(math.min) - 10;
    final high = values.reduce(math.max) + 10;
    Offset point(int index) => Offset(
      size.width * index / (values.length - 1),
      size.height * (1 - (values[index] - low) / (high - low)),
    );
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var index = 1; index < values.length; index++) {
      path.lineTo(point(index).dx, point(index).dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(area, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_Curve old) => old.ratings != ratings;
}
