import 'package:dartchess/dartchess.dart';

/// O resultado que fecha uma sub-variante na faixa (T68). Só aparece quando
/// muda em relação à linha principal. Nesta tarefa, só o empate.
enum VariationResult {
  draw('=');

  const VariationResult(this.symbol);

  /// A notação de livro (`=`), sem palavra: vale em todos os idiomas.
  final String symbol;

  static VariationResult? parse(Object? value) => switch (value) {
    'draw' => VariationResult.draw,
    _ => null,
  };
}

/// Um lance da faixa: o texto como aparece ("2.Rf5", "2...Rg7", "Rf7"), a
/// posição de depois dele e o lance (para marcar no tabuleiro).
class TreeMove {
  const TreeMove({required this.label, required this.fen, this.move});

  /// O lance com o número completo (`2...Rg7`); a faixa tira o número das
  /// pretas quando o lance não abre a linha.
  final String label;

  /// A posição depois do lance.
  final String fen;
  final Move? move;
}

/// Onde o aluno está na árvore: na linha principal ([branch] nulo, [ply]
/// lances jogados desde a partida) ou num ramo ([ply] é o lance do ramo, de
/// 1 em diante).
class TreePosition {
  const TreePosition(this.branch, this.ply);
  const TreePosition.main(int ply) : this(null, ply);
  const TreePosition.branch(String id, int ply) : this(id, ply);

  final String? branch;
  final int ply;

  @override
  bool operator ==(Object other) =>
      other is TreePosition && other.branch == branch && other.ply == ply;

  @override
  int get hashCode => Object.hash(branch, ply);

  @override
  String toString() => 'TreePosition(${branch ?? 'main'}, $ply)';
}

/// Uma alternativa à linha principal: substitui o lance `at + 1` dela.
class VariationBranch {
  VariationBranch({
    required this.id,
    required this.at,
    required List<TreeMove> moves,
    this.result,
    this.comment = '',
    Map<int, String> commentByPly = const {},
  }) : moves = List.unmodifiable(moves),
       commentByPly = Map.unmodifiable(commentByPly);

  final String id;

  /// Lances da principal jogados antes da alternativa.
  final int at;
  final List<TreeMove> moves;
  final VariationResult? result;

  /// O comentário da alternativa; o lance sem texto próprio mostra este.
  final String comment;

  /// Comentário por lance do ramo (1 é o primeiro).
  final Map<int, String> commentByPly;

  String commentAt(int ply) => commentByPly[ply] ?? comment;
}

/// Um lance numa linha da faixa, já com o lugar dele na árvore.
class VariationRowMove {
  const VariationRowMove({
    required this.label,
    required this.position,
    required this.shown,
  });

  /// O lance como aparece na linha (sem o número das pretas no meio).
  final String shown;
  final String label;
  final TreePosition position;
}

/// Uma linha da faixa: um trecho da principal, ou uma alternativa (com o
/// recuo e, no fim, o resultado).
class VariationRow {
  const VariationRow({required this.moves, this.branch, this.result});

  final List<VariationRowMove> moves;

  /// O ramo desta linha; nulo, a principal.
  final VariationBranch? branch;
  final VariationResult? result;
  bool get isBranch => branch != null;
}

/// Onde um lance fica em relação ao lance da vez (modelo para o destaque e
/// para modos que escondam os lances seguintes).
enum VariationMoveState { played, current, upcoming }

/// O que a faixa mostra: a linha principal e as alternativas (um nível).
/// Dart puro; montada por `VariationTreeBuilder`.
class VariationTree {
  VariationTree({
    required this.startFen,
    required List<TreeMove> main,
    List<VariationBranch> branches = const [],
  }) : main = List.unmodifiable(main),
       branches = List.unmodifiable(branches);

  /// A posição antes do primeiro lance da principal.
  final String startFen;
  final List<TreeMove> main;
  final List<VariationBranch> branches;

  VariationBranch? branchOf(String id) {
    for (final branch in branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  bool contains(TreePosition position) {
    if (position.branch == null) {
      return position.ply >= 0 && position.ply <= main.length;
    }
    final branch = branchOf(position.branch!);
    return branch != null &&
        position.ply >= 1 &&
        position.ply <= branch.moves.length;
  }

  String fenAt(TreePosition position) {
    if (position.branch case final id?) {
      return branchOf(id)!.moves[position.ply - 1].fen;
    }
    return position.ply == 0 ? startFen : main[position.ply - 1].fen;
  }

  Move? lastMoveAt(TreePosition position) {
    if (position.branch case final id?) {
      return branchOf(id)!.moves[position.ply - 1].move;
    }
    return position.ply == 0 ? null : main[position.ply - 1].move;
  }

  bool canPrevious(TreePosition position) =>
      position.branch != null || position.ply > 0;

  bool canNext(TreePosition position) {
    if (position.branch case final id?) {
      return position.ply < branchOf(id)!.moves.length;
    }
    return position.ply < main.length;
  }

  /// ⏮: no 1º lance do ramo, volta ao ponto de partida (`at` da principal).
  TreePosition previous(TreePosition position) {
    if (position.branch case final id?) {
      return position.ply <= 1
          ? TreePosition.main(branchOf(id)!.at)
          : TreePosition.branch(id, position.ply - 1);
    }
    return TreePosition.main(position.ply > 0 ? position.ply - 1 : 0);
  }

  /// ⏭: segue a linha do lance da vez; no fim do ramo, fica onde está.
  TreePosition next(TreePosition position) => canNext(position)
      ? TreePosition(position.branch, position.ply + 1)
      : position;

  /// O comentário próprio do lugar: só nos ramos. Na principal, nulo (quem
  /// monta a tela usa o texto da fala ou da explicação).
  String? commentAt(TreePosition position) {
    if (position.branch case final id?) {
      return branchOf(id)!.commentAt(position.ply);
    }
    return null;
  }

  /// A linha principal quebra no lance de onde cada alternativa nasce:
  /// trecho até o lance `at + 1`, as alternativas desse ponto, e o resto.
  List<VariationRow> get rows {
    final rows = <VariationRow>[];
    final points = {for (final branch in branches) branch.at}.toList()..sort();
    var from = 0;
    for (final at in points) {
      final to = (at + 1).clamp(0, main.length);
      if (to > from) rows.add(_mainRow(from, to));
      from = to > from ? to : from;
      for (final branch in branches.where((b) => b.at == at)) {
        rows.add(
          VariationRow(
            branch: branch,
            result: branch.result,
            moves: [
              for (final (index, move) in branch.moves.indexed)
                VariationRowMove(
                  label: move.label,
                  shown: index == 0 ? move.label : _inline(move.label),
                  position: TreePosition.branch(branch.id, index + 1),
                ),
            ],
          ),
        );
      }
    }
    if (from < main.length) rows.add(_mainRow(from, main.length));
    return rows;
  }

  VariationRow _mainRow(int from, int to) => VariationRow(
    moves: [
      for (var i = from; i < to; i++)
        VariationRowMove(
          label: main[i].label,
          shown: i == from ? main[i].label : _inline(main[i].label),
          position: TreePosition.main(i + 1),
        ),
    ],
  );

  /// O número das pretas só abre a linha ("2...Rg7"); no meio, não.
  static String _inline(String label) =>
      label.replaceFirst(RegExp(r'^\d+\.\.\.'), '');

  /// Os lances já jogados até [position], na ordem em que o aluno os viu.
  List<TreePosition> pathTo(TreePosition position) {
    if (position.branch case final id?) {
      return [
        for (var i = 1; i <= branchOf(id)!.at; i++) TreePosition.main(i),
        for (var k = 1; k <= position.ply; k++) TreePosition.branch(id, k),
      ];
    }
    return [for (var i = 1; i <= position.ply; i++) TreePosition.main(i)];
  }

  /// Os lances que o aluno precisa ter visto para chegar a [position] (T69,
  /// lances ocultos): como [pathTo] e, num ramo, também o lance da principal
  /// que ele troca (`at + 1`), de onde a alternativa se explica.
  List<TreePosition> revealPath(TreePosition position) {
    final id = position.branch;
    if (id == null) return pathTo(position);
    final branch = branchOf(id)!;
    return [
      for (var i = 1; i <= branch.at + 1 && i <= main.length; i++)
        TreePosition.main(i),
      for (var k = 1; k <= position.ply; k++) TreePosition.branch(id, k),
    ];
  }

  /// O estado de [move] em relação ao lance da vez [current]: já jogado, o
  /// da vez, ou ainda por jogar. Quem mostra os lances usa isto para o
  /// destaque (e, depois, para ocultar os seguintes).
  VariationMoveState stateOf(TreePosition move, TreePosition current) {
    if (move == current) return VariationMoveState.current;
    return pathTo(current).contains(move)
        ? VariationMoveState.played
        : VariationMoveState.upcoming;
  }
}
