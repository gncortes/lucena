import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../domain/use_cases/subcategory_material.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
import '../view_models/catalog_cubit.dart';
import '../../core/widgets/empty_state.dart';

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
  'knight' => l10n.catalogCategoryKnight,
  'rookPieces' => l10n.catalogCategoryRookPieces,
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
  'knight' => '♘',
  'rookPieces' => '♖♗',
  _ => '♙',
};

/// O nome do final por extenso ("Dama contra torre"). Os finais mais
/// conhecidos têm nome próprio; os outros têm o nome montado do material
/// ("Torre e dois peões contra bispo e peão").
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
      _ => _materialName(l10n, subcategory),
    };

String _materialName(AppLocalizations l10n, String subcategory) {
  final (first, second) = SubcategoryMaterial.of(subcategory);
  final name = l10n.endgameMaterialVs(
    _sideName(l10n, first),
    _sideName(l10n, second),
  );
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

// O plural do gerador de traduções só aceita =0, =1 e =2; de três peças em
// diante o número por extenso vem de uma chave à parte.
const _numberWords = {3: 'three', 4: 'four', 5: 'five'};

/// As peças de um lado por extenso ("torre, bispo e dois peões").
String _sideName(AppLocalizations l10n, List<Role> roles) {
  final counts = <Role, int>{};
  for (final role in roles) {
    counts[role] = (counts[role] ?? 0) + 1;
  }
  final names = [
    for (final MapEntry(key: role, value: count) in counts.entries)
      l10n.endgameMaterialPiece(
        role.name,
        count,
        l10n.endgameMaterialNumber(_numberWords[count] ?? 'other', count),
      ),
  ];
  if (names.length == 1) return names.single;
  final init = names
      .sublist(0, names.length - 1)
      .reduce((a, b) => l10n.endgameMaterialList(a, b));
  return l10n.endgameMaterialAnd(init, names.last);
}

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
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
  Widget build(BuildContext context) => EmptyState(
    style: EmptyStateStyle.text,
    message: context.l10n.catalogEmpty,
    messageKey: CatalogKeys.empty,
  );
}
