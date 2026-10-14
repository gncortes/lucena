import '../models/variation_tree.dart';

/// Ramificação jogável do modo variante (T70, crit. 9b): o lance do aluno
/// vale se for o próximo da linha aberta ou o 1º lance de um ramo que nasce
/// na posição atual. Dart puro.
abstract final class BranchMove {
  /// A posição da árvore a que o lance [uci] leva a partir de [position], ou
  /// nulo se a árvore não tem esse lance ali (quem chama aplica a regra do
  /// Stockfish, `EngineFallback`).
  ///
  /// - Na principal: o próximo lance dela, ou o 1º de um ramo com `at` igual
  ///   ao ply atual (o ramo substitui o lance seguinte).
  /// - Num ramo: só o próximo lance dele (a árvore tem um nível só).
  static TreePosition? match(
    VariationTree tree,
    TreePosition position,
    String uci,
  ) {
    if (!tree.contains(position)) return null;
    if (position.branch case final id?) {
      final branch = tree.branchOf(id)!;
      if (position.ply >= branch.moves.length) return null;
      return branch.moves[position.ply].move?.uci == uci
          ? TreePosition.branch(id, position.ply + 1)
          : null;
    }
    if (position.ply < tree.main.length &&
        tree.main[position.ply].move?.uci == uci) {
      return TreePosition.main(position.ply + 1);
    }
    for (final branch in tree.branches) {
      if (branch.at == position.ply &&
          branch.moves.isNotEmpty &&
          branch.moves.first.move?.uci == uci) {
        return TreePosition.branch(branch.id, 1);
      }
    }
    return null;
  }
}
