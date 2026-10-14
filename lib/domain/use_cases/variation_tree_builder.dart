import 'package:dartchess/dartchess.dart';

import '../models/explanation.dart';
import '../models/lesson.dart';
import '../models/variation_tree.dart';
import 'speech_lines.dart';
import 'speech_links.dart';

/// Uma alternativa citada no JSON da aula (`CitedLine.branches`) com a posição
/// de onde ela sai: a explicação (LANCE CERTO) a mostra no ponto em que a
/// variante dela passa por [fen], mesmo que a linha citada seja de outro passo.
class CitedBranchSource {
  const CitedBranchSource(this.stepId, this.fen, this.branch);

  /// O passo da aula cuja fala cita a linha (chave do comentário).
  final String stepId;

  /// A posição depois de `branch.at` lances da linha citada.
  final String fen;
  final CitedBranch branch;
}

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

  /// As alternativas citadas dos [steps] da aula, cada uma com a posição de
  /// onde sai. A que não se joga, ou cuja linha não se joga até o `at`, fica
  /// de fora; a repetida (mesma posição e mesmos lances) vale a do 1º passo.
  static List<CitedBranchSource> citedSources(Iterable<LessonStep> steps) {
    final result = <CitedBranchSource>[];
    final seen = <String>{};
    for (final step in steps) {
      final start = step.fen;
      if (start == null) continue;
      for (final line in step.lines) {
        for (final branch in line.branches) {
          if (branch.at < 0 || branch.at > line.uci.length) continue;
          final fen = _play(start, line.uci.take(branch.at));
          if (fen == null) continue;
          if (!seen.add(
            '${_place(fen)}|${branch.id}|${branch.uci.join(' ')}',
          )) {
            continue;
          }
          result.add(CitedBranchSource(step.id, fen, branch));
        }
      }
    }
    return result;
  }

  /// A fala cita um lance solto que é o começo de uma alternativa da linha
  /// citada do [step] ("Com 3.g4? ... 3.g4 Rg6 4.g5 Rxg5", depois do lance
  /// errado): a linha citada inteira (para a faixa abrir a alternativa
  /// recuada, com o `?` e o `=`) e a alternativa. Nulo se a fala já é uma
  /// linha citada, ou se nenhuma alternativa sai dali.
  static ({SpeechLine line, CitedBranch branch})? lineOfBranch(
    LessonStep step,
    SpeechLine spoken, [
    Map<String, String> letters = const {},
  ]) {
    final start = step.fen;
    if (start == null || spoken.moves.isEmpty) return null;
    final ucis = [for (final move in spoken.moves) move.uci];
    if (step.lines.any((l) => l.matches(ucis))) return null;
    for (final cited in step.lines) {
      for (final branch in cited.branches) {
        if (branch.at < 0 || branch.at > cited.uci.length) continue;
        if (branch.uci.isEmpty || branch.uci.first != ucis.first) continue;
        final fen = _play(start, cited.uci.take(branch.at));
        if (fen == null || _place(fen) != _place(spoken.fens.first)) continue;
        final line = _mainLine(start, cited, letters);
        if (line != null) return (line: line, branch: branch);
      }
    }
    return null;
  }

  static SpeechLine? _mainLine(
    String start,
    CitedLine cited,
    Map<String, String> letters,
  ) {
    Position position;
    try {
      position = Chess.fromSetup(Setup.parseFen(start));
    } on FenException {
      return null;
    } on PositionSetupException {
      return null;
    }
    final fens = [position.fen];
    final moves = <Move>[];
    final links = <SpeechLink>[];
    for (final text in cited.uci) {
      final move = Move.parse(text);
      if (move == null || !position.isLegal(move)) return null;
      final (next, san) = position.makeSan(move);
      final local = _localize(san, letters);
      links.add(
        SpeechLink(
          start: links.length,
          end: links.length + 1,
          text: local,
          isMove: true,
        ),
      );
      moves.add(move);
      fens.add(next.fen);
      position = next;
    }
    return SpeechLine(links: links, fens: fens, moves: moves);
  }

  /// O rótulo do 1º lance da alternativa ("2.g4?"), como a faixa o escreve.
  static String? firstLabel(
    CitedBranchSource source, [
    Map<String, String> letters = const {},
  ]) => _replay(source.fen, source.branch, letters)?.firstOrNull?.label;

  /// A variante aberta [cursor] da explicação de [payload], com as filhas
  /// dela como alternativas (`parentPly` é o `at`) e as alternativas citadas
  /// ([cited]) que saem de uma posição dela.
  static VariationTree fromExplanation({
    required ExplanationPayload payload,
    required VariationCursor cursor,
    List<CitedBranchSource> cited = const [],
    Map<String, String> letters = const {},
    String? Function(String stepId, String id, int? ply)? comment,
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
    for (final source in cited) {
      final at = cursor.fens.indexed
          .where((e) => e.$1 <= cursor.moves.length)
          .where((e) => _place(e.$2) == _place(source.fen))
          .map((e) => e.$1)
          .firstOrNull;
      if (at == null || branches.any((b) => b.id == source.branch.id)) continue;
      final moves = _replay(cursor.fens[at], source.branch, letters);
      if (moves == null) continue;
      // O mesmo lance da principal não é alternativa.
      if (at < cursor.moves.length &&
          moves.first.move?.uci == cursor.moves[at].uci) {
        continue;
      }
      final id = source.branch.id;
      branches.add(
        VariationBranch(
          id: id,
          at: at,
          moves: moves,
          result: source.branch.result,
          comment: comment?.call(source.stepId, id, null) ?? '',
          commentByPly: {
            for (var k = 1; k <= moves.length; k++)
              k: ?comment?.call(source.stepId, id, k),
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

  /// A posição sem os contadores de lances.
  static String _place(String fen) => fen.split(' ').take(4).join(' ');

  static String? _play(String fen, Iterable<String> ucis) {
    try {
      var position = Chess.fromSetup(Setup.parseFen(fen)) as Position;
      for (final text in ucis) {
        final move = Move.parse(text);
        if (move == null || !position.isLegal(move)) return null;
        position = position.play(move);
      }
      return position.fen;
    } on FenException {
      return null;
    } on PositionSetupException {
      return null;
    }
  }

  /// A posição sem os contadores de lances, para comparar.
  static String placeOf(String fen) => _place(fen);

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
