import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/catalog_cubit.dart';
import 'catalog_ui.dart';

/// As posições de uma subcategoria. A lista só desenha as linhas que estão na
/// tela: subcategorias com centenas de posições rolam sem travar.
class SubcategoryScreen extends StatelessWidget {
  const SubcategoryScreen({
    required this.category,
    required this.subcategory,
    super.key,
  });

  final String category;
  final String subcategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positions = context.select(
      (CatalogCubit cubit) => cubit.state.visiblePositions,
    );
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return Scaffold(
      key: CatalogKeys.subcategoryScreen,
      appBar: AppBar(
        title: SubcategoryMaterialText(
          subcategory,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: positions == null
                ? const Center(child: CircularProgressIndicator())
                : positions.isEmpty
                ? const CatalogEmpty()
                : ListView.builder(
                    key: CatalogKeys.positionList,
                    itemExtent: _PositionTile.height,
                    itemCount: positions.length,
                    itemBuilder: (context, index) =>
                        _PositionTile(position: positions[index], board: board),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  const _PositionTile({required this.position, required this.board});

  static const height = 96.0;

  final EndgamePosition position;
  final BoardSettings board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final turn = position.fen.split(' ')[1] == 'b' ? Side.black : Side.white;
    return InkWell(
      key: CatalogKeys.position(position.id),
      onTap: () =>
          context.push(Routes.setup(position.fen, goal: position.goal.code)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Miniatura vista pelo lado que joga, como a partida vai abrir.
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
                children: [
                  Text(
                    l10n.catalogPositionNumber(position.number),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Tag(
                        label: goalLabel(l10n, position.goal),
                        color: position.goal == PositionGoal.win
                            ? colors.primaryContainer
                            : colors.tertiaryContainer,
                        onColor: position.goal == PositionGoal.win
                            ? colors.onPrimaryContainer
                            : colors.onTertiaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    turn == Side.white
                        ? l10n.freeBoardWhiteToMove
                        : l10n.freeBoardBlackToMove,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, required this.onColor});

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: onColor),
      ),
    );
  }
}
