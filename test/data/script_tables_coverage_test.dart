import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/tablebase/script_table_repository.dart';

const _scripts = AssetScriptTableRepository.scriptsDir;

/// Os prefixos dos cursos de meio-jogo.
const _middlegameCourses = ['pilares.', 'torneio.'];

bool _isMiddlegameCourse(String scriptPath) {
  final normalized = scriptPath.replaceAll(r'\\', '/');
  final index = normalized.indexOf(_scripts);
  if (index < 0) return false;
  final relative = normalized.substring(index + _scripts.length);
  return _middlegameCourses.any(relative.startsWith);
}

int _pieces(Position position) => position.board.occupied.squares.length;

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

List<Map<String, dynamic>> _steps(Map<String, dynamic> example) {
  final out = <Map<String, dynamic>>[
    ...(example['entrada'] as List? ?? const []).cast(),
    ...(example['linha'] as List? ?? const []).cast(),
  ];
  final question = example['pergunta'] as Map<String, dynamic>?;
  if (question != null) {
    for (final key in ['certo', 'revela']) {
      if (question[key] is Map) out.add(question[key] as Map<String, dynamic>);
    }
    for (final group in ['alternativos', 'erros']) {
      for (final value in (question[group] as Map? ?? const {}).values) {
        if (value is List) out.addAll(value.cast());
        if (value is Map) out.add(value as Map<String, dynamic>);
      }
    }
  }
  return out;
}

/// O mesmo critério de `judged` da ferramenta.
/// No curso de meio-jogo ([middlegame]), só o que o app julga.
bool _judged(Map<String, dynamic> example, {bool middlegame = false}) {
  final goal = example['objetivo'] as String? ?? 'ganhar';
  if (goal != 'ganhar' && goal != 'empatar') return false;
  final question = example['pergunta'] as Map<String, dynamic>?;
  final practice = example['pratica'] as Map<String, dynamic>?;
  if (question != null && (question['juiz'] ?? 'kpk') != 'kpk') return false;
  if (practice != null && (practice['tipo'] ?? 'jogo') != 'jogo') return false;
  if (middlegame && question == null && practice == null) return false;
  final fens = [example['fen'] as String, ..._steps(example).map(_fenOf)];
  return fens.any((fen) => _pieces(_pos(fen)) > 3);
}

String _fenOf(Map<String, dynamic> step) => step['fen'] as String;

void main() {
  group('cursos de meio-jogo', () {
    test('só pilares.* e torneio.* são de meio-jogo', () {
      expect(
        _isMiddlegameCourse('${_scripts}pilares.c1/knightFork.json'),
        isTrue,
      );
      expect(
        _isMiddlegameCourse('${_scripts}torneio.t1/knightFork.json'),
        isTrue,
      );
      expect(
        _isMiddlegameCourse('${_scripts}pawns.opposition/direct.json'),
        isFalse,
      );
      expect(_isMiddlegameCourse('outra/pilares.c1/knightFork.json'), isFalse);
    });

    test('demonstração e prática "lance" ficam fora; jogo e kpk, não', () {
      const fen = 'r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1';
      final demo = {'id': 'demo', 'fen': fen};
      final lance = {
        'id': 'lance',
        'fen': fen,
        'pratica': {'tipo': 'lance'},
      };
      final game = {'id': 'jogo', 'fen': fen, 'pratica': <String, Object>{}};
      final kpk = {'id': 'kpk', 'fen': fen, 'pergunta': <String, Object>{}};
      expect(_judged(demo, middlegame: true), isFalse);
      expect(_judged(lance, middlegame: true), isFalse);
      expect(_judged(game, middlegame: true), isTrue);
      expect(_judged(kpk, middlegame: true), isTrue);
      expect(_judged(demo), isTrue, reason: 'final: a demonstração segue');
    });
  });
}
