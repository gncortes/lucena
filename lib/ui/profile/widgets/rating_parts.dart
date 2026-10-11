import 'package:flutter/material.dart';

import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';

/// O ⓘ do rating: o que ele mede e como muda, num painel inferior (antes um
/// parágrafo fixo no fim da tela e do cartão).
void showRatingHelp(BuildContext context) {
  final theme = Theme.of(context);
  final l10n = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileEndgameRating, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.profileRatingHint,
              key: RatingKeys.helpText,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
