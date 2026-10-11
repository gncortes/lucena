import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../domain/use_cases/subcategory_material.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
import '../view_models/catalog_cubit.dart';

/// O nome traduzido de uma categoria do catálogo. O app leva só as categorias
/// dos finais de iniciante (ver `tools/import_positions.py`); categoria nova
/// precisa de nome aqui e nos arquivos de tradução.
String categoryName(AppLocalizations l10n, String key) => switch (key) {
  'basic' => l10n.catalogCategoryBasic,
  'pawn' => l10n.catalogCategoryPawn,
  'rookPawn' => l10n.catalogCategoryRookPawn,
  'queen' => l10n.catalogCategoryQueen,
  'bishop' => l10n.catalogCategoryBishop,
  'knightBishop' => l10n.catalogCategoryKnightBishop,
  _ => key,
};

/// As peças que dão a cara de cada categoria, em figurino.
String categoryFigurines(String key) => switch (key) {
  'basic' => '♔',
  'pawn' => '♙',
  'rookPawn' => '♖♙',
  'queen' => '♕',
  'bishop' => '♗',
  'knightBishop' => '♗♘',
  _ => '♙',
};

/// O nome do final por extenso ("Dama contra torre"). Subcategoria nova
/// precisa de nome aqui e nos arquivos de tradução; sem ele, fica a chave.
String endgameName(AppLocalizations l10n, String subcategory) =>
    switch (subcategory) {
      'queen' => l10n.endgameQueen,
      'rook' => l10n.endgameRook,
      'twoRooks' => l10n.endgameTwoRooks,
      'pawnVsKing' => l10n.endgamePawnVsKing,
      'rookPawnVsRook' => l10n.endgameRookPawnVsRook,
      'queenVsRook' => l10n.endgameQueenVsRook,
      'queenVsPawn' => l10n.endgameQueenVsPawn,
      'rookVsPawn' => l10n.endgameRookVsPawn,
      'twoBishopsVsKing' => l10n.endgameTwoBishops,
      'knightBishopVsKing' => l10n.endgameKnightBishop,
      _ => subcategory,
    };

/// O que o jogador precisa fazer, em palavras.
String goalLabel(AppLocalizations l10n, PositionGoal goal) => switch (goal) {
  PositionGoal.win => l10n.goalWin,
  PositionGoal.draw => l10n.goalDraw,
};

/// A marca do tabuleiro de uma posição do catálogo, que voa do cartão dela na
/// tela da categoria para a amostra da configuração da partida.
String catalogBoardTag(String positionId) => 'catalog.board.$positionId';

/// O Hero do tabuleiro da preparação da partida: o da posição do catálogo
/// ou, sem ela, o da própria posição [fen] (o final de uma aula).
String setupBoardTag({String? positionId, required String fen}) =>
    positionId == null ? 'setup.board.$fen' : catalogBoardTag(positionId);

/// O material de uma subcategoria em figurino: as peças de um lado em
/// contorno, as do outro cheias (`♕ – ♜♟`). Vale em qualquer idioma.
class SubcategoryMaterialText extends StatelessWidget {
  const SubcategoryMaterialText(this.subcategory, {this.style, super.key});

  final String subcategory;
  final TextStyle? style;

  static const _outlined = {
    Role.king: '♔',
    Role.queen: '♕',
    Role.rook: '♖',
    Role.bishop: '♗',
    Role.knight: '♘',
    Role.pawn: '♙',
  };
  static const _filled = {
    Role.king: '♚',
    Role.queen: '♛',
    Role.rook: '♜',
    Role.bishop: '♝',
    Role.knight: '♞',
    Role.pawn: '♟',
  };

  @override
  Widget build(BuildContext context) {
    final (first, second) = SubcategoryMaterial.of(subcategory);
    final text =
        '${first.map((r) => _outlined[r]).join()}  –  '
        '${second.map((r) => _filled[r]).join()}';
    // Os desenhos das peças são sempre da esquerda para a direita.
    return Text(
      text,
      textDirection: TextDirection.ltr,
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        fontFamily: Figurine.fontFamily,
      ),
    );
  }
}

/// O filtro por objetivo, no alto das telas do catálogo.
class GoalFilterBar extends StatelessWidget {
  const GoalFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CatalogCubit>();
    final filter = context.select((CatalogCubit cubit) => cubit.state.filter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<GoalFilter>(
          showSelectedIcon: false,
          segments: [
            for (final (value, label) in [
              (GoalFilter.all, l10n.catalogFilterAll),
              (GoalFilter.win, l10n.goalWin),
              (GoalFilter.draw, l10n.goalDraw),
            ])
              ButtonSegment(
                value: value,
                label: Text(
                  label,
                  key: CatalogKeys.filter(value),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          selected: {filter},
          onSelectionChanged: (selected) => cubit.setFilter(selected.single),
        ),
      ),
    );
  }
}

/// Mensagem quando o filtro não deixa nada.
class CatalogEmpty extends StatelessWidget {
  const CatalogEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        context.l10n.catalogEmpty,
        key: CatalogKeys.empty,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
