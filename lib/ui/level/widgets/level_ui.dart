import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/platform_rating.dart';
import '../../../domain/use_cases/rating_conversion.dart';
import '../../../routing/routes.dart';
import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../view_models/level_cubit.dart';

/// O adversário em que a Jornada começa com [rating]: "Valdini (1600)".
String levelRung(BuildContext context, LevelState state, int rating) {
  final l10n = context.l10n;
  final level = RatingConversion.startRung(rating);
  final name =
      state.startCharacter(rating)?.name ??
      OpponentKind.maia.label(l10n, level: level);
  return l10n.levelRung(name, level);
}

/// "Pelo seu blitz, a Jornada começa no … e o seu rating no Lucena começa
/// em …", pelo modo principal de [rating]; [lucena] é o número já
/// convertido.
String levelStartsAt(
  BuildContext context,
  LevelState state,
  PlatformRating rating,
  int lucena,
) => context.l10n.levelStartsAt(
  (rating.mainMode ?? RatingMode.blitz).name,
  levelRung(context, state, lucena),
  lucena,
);

/// Abre o teste de nível. Usado o resultado, o cartão do teste fica marcado;
/// com [finish] (vindo do Lichess ou do Chess.com), a escolha já termina.
Future<void> takeLevelTest(BuildContext context, {required bool finish}) async {
  final cubit = context.read<LevelCubit>();
  final used = await context.push<bool>(Routes.placementFrom('level'));
  if (used != true) return;
  await cubit.usePlacement();
  if (finish) await cubit.finish();
}

/// "Prefiro fazer o teste", embaixo do "Usar esse rating".
class PreferTestButton extends StatelessWidget {
  const PreferTestButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
    key: LevelKeys.preferTest,
    onPressed: () => takeLevelTest(context, finish: true),
    child: Text(context.l10n.levelPreferTest),
  );
}

/// Os três ratings de um site: bullet, blitz e rápidas, com "?" no
/// provisório e o número de partidas.
class PlatformRatingsGrid extends StatelessWidget {
  const PlatformRatingsGrid({required this.rating, super.key});

  final PlatformRating rating;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        for (final (i, mode) in RatingMode.values.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Cell(
              label: switch (mode) {
                RatingMode.bullet => l10n.levelRatingBullet,
                RatingMode.blitz => l10n.levelRatingBlitz,
                RatingMode.rapid => l10n.levelRatingRapid,
              },
              rating: rating.of(mode),
            ),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.rating});

  final String label;
  final ModeRating? rating;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rating = this.rating;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Column(
        children: [
          Text(label, style: muted),
          Text(
            rating == null
                ? l10n.levelRatingNone
                : rating.provisional
                ? l10n.levelRatingProvisional(rating.rating)
                : '${rating.rating}',
            style: context.cardTitle?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (rating != null)
            Text(l10n.levelGamesCount(rating.games), style: muted),
        ],
      ),
    );
  }
}
