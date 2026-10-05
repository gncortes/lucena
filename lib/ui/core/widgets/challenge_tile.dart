import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_position.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../board/board_settings_ui.dart';
import '../l10n/l10n.dart';
import 'goal_style.dart';

/// Uma posição do catálogo numa lista: miniatura vista pelo lado que joga, o
/// material, o objetivo e, à direita, o que vier em [trailing].
class ChallengeTile extends StatelessWidget {
  const ChallengeTile({
    required this.position,
    required this.onTap,
    this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  static const height = 88.0;

  final EndgamePosition position;
  final VoidCallback? onTap;

  /// Sem [title], o material da posição em figurino.
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final turn = position.fen.split(' ')[1] == 'b' ? Side.black : Side.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: StaticChessboard(
                size: height - 16,
                orientation: turn,
                fen: position.fen,
                settings: StaticChessboardSettings(
                  colorScheme: board.colors.scheme,
                  pieceAssets: board.pieces.assets,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  animationDuration: Duration.zero,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  title ??
                      SubcategoryMaterialText(
                        position.subcategory,
                        style: theme.textTheme.titleMedium,
                      ),
                  Row(
                    children: [
                      Icon(
                        GoalStyle.of(context, position.goal).icon,
                        size: 14,
                        color: GoalStyle.of(context, position.goal).color,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          goalLabel(l10n, position.goal),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: GoalStyle.of(context, position.goal).color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ?subtitle,
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
