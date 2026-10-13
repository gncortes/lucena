import 'package:dartchess/dartchess.dart';

import '../models/explanation.dart';
import '../models/lesson.dart';
import '../models/variation_tree.dart';
import 'speech_lines.dart';

/// Monta a árvore da faixa do modo variante (T68) a partir de uma das duas
/// fontes: a linha citada na fala (com as alternativas do JSON da aula) ou a
/// variante do painel de explicação (com as filhas dela). Um nível só.
abstract final class VariationTreeBuilder {
  /// A linha [line] da fala com as alternativas [branches] da `CitedLine`
  /// dela. [letters] traduz a letra inglesa da peça (`K`→`R`); [comment]
  /// acha o texto da alternativa ([ply] nulo) ou do lance dela.
  /// A alternativa que não se joga a partir do ponto, ou que sai depois do
  /// fim da linha, fica de fora.
  static VariationTree fromSpeech({
    required SpeechLine line,
    List<CitedBranch> branches = const [],
    Map<String, String> letters = const {},
    String? Function(String id, int? ply)? comment,
  }) {
    final main = <TreeMove>[
      for (final (i, move) in line.moves.indexed)
        TreeMove(
          label: _label(line.fens[i], line.links[i].text),
          fen: line.fens[i + 1],
          move: move,
        ),
    ];
    final result = <VariationBranch>[];
    for (final cited in branches) {
      if (cited.at < 0 || cited.at > line.length) continue;
      final moves = _replay(line.fens[cited.at], cited, letters);
      if (moves == null) continue;
      result.add(
        VariationBranch(
          id: cited.id,
          at: cited.at,
          moves: moves,
          result: cited.result,
          comment: comment?.call(cited.id, null) ?? '',
          commentByPly: {
            for (var k = 1; k <= moves.length; k++)
              k: ?comment?.call(cited.id, k),
          },
        ),
      );
    }
    return VariationTree(
      startFen: line.fens.first,
      main: main,
      branches: result,
    );
  }

  /// A variante aberta [cursor] da explicação de [payload], com as filhas
  /// dela como alternativas (`parentPly` é o `at`).
  static VariationTree fromExplanation({
    required ExplanationPayload payload,
    required VariationCursor cursor,
  }) {
    final variation = cursor.variation;
    final main = <TreeMove>[
      for (final (i, move) in cursor.moves.indexed)
        TreeMove(
          label: _label(cursor.fens[i], variation.movesSan[i]),
          fen: cursor.fens[i + 1],
          move: move,
        ),
    ];
    final branches = <VariationBranch>[];
    for (final child in payload.childrenOf(variation)) {
      final at = child.parentPly;
      final opened = child.open();
      if (at == null || at < 0 || at > cursor.moves.length || opened == null) {
        continue;
      }
      final moves = [
        for (final (i, move) in opened.moves.indexed)
          TreeMove(
            label: _label(opened.fens[i], child.movesSan[i]),
            fen: opened.fens[i + 1],
            move: move,
          ),
      ];
      branches.add(
        VariationBranch(
          id: child.id,
          at: at,
          moves: moves,
          result: child.result,
          comment: child.texts.firstOrNull ?? '',
          commentByPly: {
            for (final e in child.explanationByPly.entries)
              if (e.value.isNotEmpty) e.key: e.value.first,
          },
        ),
      );
    }
    return VariationTree(
      startFen: cursor.fens.first,
      main: main,
      branches: branches,
    );
  }

  /// Os lances de [cited] jogados a partir de [fen]; nulo se algum for ilegal.
  static List<TreeMove>? _replay(
    String fen,
    CitedBranch cited,
    Map<String, String> letters,
  ) {
    Position position;
    try {
      position = Chess.fromSetup(Setup.parseFen(fen));
    } on FenException {
      return null;
    } on PositionSetupException {
      return null;
    }
    final moves = <TreeMove>[];
    for (final (i, text) in cited.uci.indexed) {
      final move = Move.parse(text);
      if (move == null || !position.isLegal(move)) return null;
      final before = position.fen;
      final (next, san) = position.makeSan(move);
      final glyph = i < cited.glyphs.length ? cited.glyphs[i] : null;
      final local = _localize(san, letters);
      moves.add(
        TreeMove(
          label: _numbered(before, '$local${glyph ?? ''}'),
          fen: next.fen,
          move: move,
        ),
      );
      position = next;
    }
    return moves;
  }

  static final _number = RegExp(r'^\d+\.(?:\.\.)?');

  /// O lance com o número: o escrito pelo autor, ou o da posição [fenBefore].
  static String _label(String fenBefore, String text) =>
      _number.hasMatch(text) ? text : _numbered(fenBefore, text);

  static String _numbered(String fenBefore, String san) {
    final fields = fenBefore.split(' ');
    final black = fields.elementAtOrNull(1) == 'b';
    final number = int.tryParse(fields.elementAtOrNull(5) ?? '') ?? 1;
    return black ? '$number...$san' : '$number.$san';
  }

  static String _localize(String san, Map<String, String> letters) {
    if (letters.isEmpty || san.startsWith('O')) return san;
    String local(String letter) => letters[letter] ?? letter;
    var result = san;
    if ('KQRBN'.contains(san[0])) result = local(san[0]) + san.substring(1);
    final promotion = result.indexOf('=');
    if (promotion >= 0 && promotion + 1 < result.length) {
      result =
          result.substring(0, promotion + 1) +
          local(result[promotion + 1]) +
          result.substring(promotion + 2);
    }
    return result;
  }
}
