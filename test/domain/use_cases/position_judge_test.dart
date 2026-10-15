import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/tablebase/engine_judge_repository.dart';
import 'package:lucena/data/repositories/tablebase/script_table_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/stockfish_service.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/models/script_table.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/judge_move.dart';
import 'package:lucena/domain/use_cases/position_judge.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_position_judge.dart';

/// Rei e peão contra rei: dentro da tabela KPK.
const _kpk = '8/8/8/4k3/8/4K3/4P3/8 w - - 0 1';

/// Dois peões brancos contra rei: fora da tabela KPK.
const _fivePieces = '8/8/8/4k3/8/2P1K3/1P6/8 w - - 0 1';

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

/// O oráculo de verdade só responde até 3 peças.
final _oracle = FakeKpkOracle(
  rule: (position) =>
      position.board.occupied.squares.length > 3 ? KpkOutcome.outside : null,
  fallback: const KpkOutcome.win(7),
);

class _Assets extends AssetService {
  const _Assets(this.files);

  final Map<String, String> files;

  @override
  Future<String> loadString(String path) async =>
      files[path] ?? (throw StateError('sem $path'));
}

class _Stockfish extends StockfishService {
  _Stockfish(this.score);

  final ({int? centipawns, int? mate})? score;
  int? depth;

  @override
  Future<({int? centipawns, int? mate})?> evaluate(
    String fen, {
    required int depth,
  }) async {
    this.depth = depth;
    return score;
  }
}

void main() {
  group('Wdl', () {
    test('parse e flipped', () {
      expect(Wdl.parse('w'), Wdl.win);
      expect(Wdl.parse('d'), Wdl.draw);
      expect(Wdl.parse('l'), Wdl.loss);
      expect(Wdl.parse('x'), isNull);
      expect(Wdl.win.flipped, Wdl.loss);
      expect(Wdl.draw.flipped, Wdl.draw);
    });
  });

  group('ScriptTable', () {
    final table = ScriptTable.fromJson({
      'versao': 1,
      'posicoes': {
        ScriptTable.keyOf(_fivePieces): 'w c3c4',
        '8/8/8/4k3/2P5/4K3/1P6/8 b - -': 'l',
      },
    });

    test('a chave ignora os relógios', () {
      expect(ScriptTable.keyOf(_fivePieces), '8/8/8/4k3/8/2P1K3/1P6/8 w - -');
      expect(table.wdl('8/8/8/4k3/8/2P1K3/1P6/8 w - - 12 40'), Wdl.win);
    });

    test('resultado e melhor lance', () {
      expect(table.best(_fivePieces), 'c3c4');
      expect(table.wdl('8/8/8/4k3/2P5/4K3/1P6/8 b - - 0 1'), Wdl.loss);
      expect(table.best('8/8/8/4k3/2P5/4K3/1P6/8 b - - 0 1'), isNull);
      expect(table.wdl(_kpk), isNull);
      expect(table.length, 2);
    });
  });

  group('LayeredJudge', () {
    test('KPK primeiro, do ponto de vista de quem joga', () async {
      final judge = LayeredJudge(_oracle, ScriptTable.empty);
      expect(await judge.evaluate(_pos(_kpk)), Wdl.win);
      expect(
        await judge.evaluate(_pos('8/8/8/4k3/8/4K3/4P3/8 b - - 0 1')),
        Wdl.loss,
      );
    });

    test('KPK empatada é empate', () async {
      final oracle = FakeKpkOracle(fallback: KpkOutcome.draw);
      final judge = LayeredJudge(oracle, ScriptTable.empty);
      expect(await judge.evaluate(_pos(_kpk)), Wdl.draw);
    });

    test('mais de 3 peças: a tabela do roteiro, sem pedir o motor', () async {
      final engine = FakePositionJudge(fallback: Wdl.draw);
      final table = ScriptTable({ScriptTable.keyOf(_fivePieces): 'l'});
      final judge = LayeredJudge(_oracle, table, engine);
      expect(await judge.evaluate(_pos(_fivePieces)), Wdl.loss);
      expect(engine.asked, isEmpty);
    });

    test('fora das tabelas: o motor', () async {
      final engine = FakePositionJudge(fallback: Wdl.win);
      final judge = LayeredJudge(_oracle, ScriptTable.empty, engine);
      expect(await judge.evaluate(_pos(_fivePieces)), Wdl.win);
      expect(engine.asked, [ScriptTable.keyOf(_fivePieces)]);
    });

    test('sem motor e fora das tabelas: não sabe', () async {
      final judge = LayeredJudge(_oracle, ScriptTable.empty);
      expect(await judge.evaluate(_pos(_fivePieces)), isNull);
    });

    test('mate e afogamento valem antes do motor', () async {
      final engine = FakePositionJudge(fallback: Wdl.win);
      final judge = LayeredJudge(_oracle, ScriptTable.empty, engine);
      // Mate do corredor: as pretas levaram mate.
      expect(
        await judge.evaluate(_pos('3R2k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1')),
        Wdl.loss,
      );
      // Afogamento com peão a mais.
      expect(
        await judge.evaluate(_pos('k7/P7/1K6/8/8/8/7P/8 b - - 0 1')),
        Wdl.draw,
      );
      expect(engine.asked, isEmpty);
    });
  });

  group('JudgeMove com o juiz', () {
    test('ofWdl: o resultado é de quem joga depois do lance', () {
      // Depois do lance do aluno, joga o adversário: derrota dele é vitória
      // do aluno.
      expect(JudgeMove.ofWdl(Wdl.loss, wantsWin: true), MoveVerdict.keeps);
      expect(JudgeMove.ofWdl(Wdl.draw, wantsWin: true), MoveVerdict.loses);
      expect(JudgeMove.ofWdl(Wdl.draw, wantsWin: false), MoveVerdict.keeps);
      expect(JudgeMove.ofWdl(Wdl.loss, wantsWin: false), MoveVerdict.keeps);
      expect(JudgeMove.ofWdl(Wdl.win, wantsWin: false), MoveVerdict.loses);
      expect(JudgeMove.ofWdl(null, wantsWin: true), MoveVerdict.keeps);
    });

    test('judgeWith avalia a posição depois do lance', () async {
      final before = _pos(_fivePieces);
      final afterC4 = before.playUnchecked(Move.parse('c3c4')!);
      final afterKd3 = before.playUnchecked(Move.parse('e3d3')!);
      final judge = LayeredJudge(
        _oracle,
        ScriptTable({
          ScriptTable.keyOf(afterC4.fen): 'l',
          ScriptTable.keyOf(afterKd3.fen): 'd',
        }),
      );
      expect(
        await JudgeMove.judgeWith(
          judge,
          before,
          Move.parse('c3c4')!,
          wantsWin: true,
        ),
        MoveVerdict.keeps,
      );
      expect(
        await JudgeMove.judgeWith(
          judge,
          before,
          Move.parse('e3d3')!,
          wantsWin: true,
        ),
        MoveVerdict.loses,
      );
    });
  });

  group('AssetScriptTableRepository', () {
    test('o asset da tabela sai do caminho do capítulo', () {
      expect(
        AssetScriptTableRepository.pathFor(
          'assets/lessons/roteiros/pawns.distantOpposition/edge.json',
        ),
        'assets/tablebase/roteiros/pawns.distantOpposition.edge.json',
      );
    });

    test('lê a tabela e, sem o asset, devolve a vazia', () async {
      final repository = AssetScriptTableRepository(
        const _Assets({
          'assets/tablebase/roteiros/a.b.json':
              '{"versao":1,"posicoes":{"8/8/8/4k3/8/2P1K3/1P6/8 w - -":"w"}}',
        }),
      );
      final table = await repository.table('assets/lessons/roteiros/a/b.json');
      expect(table.wdl(_fivePieces), Wdl.win);
      final none = await repository.table('assets/lessons/roteiros/a/c.json');
      expect(none.length, 0);
    });
  });

  group('StockfishJudgeRepository', () {
    test('mate pelo sinal', () async {
      expect(
        await StockfishJudgeRepository(_Stockfish((centipawns: null, mate: 3)))
            .evaluate(_pos(_fivePieces)),
        Wdl.win,
      );
      expect(
        await StockfishJudgeRepository(_Stockfish((centipawns: null, mate: -2)))
            .evaluate(_pos(_fivePieces)),
        Wdl.loss,
      );
    });

    test('centipeões contra o limite, na profundidade fixa', () async {
      const limit = StockfishJudgeRepository.limit;
      final win = _Stockfish((centipawns: limit + 1, mate: null));
      expect(
        await StockfishJudgeRepository(win).evaluate(_pos(_fivePieces)),
        Wdl.win,
      );
      expect(win.depth, StockfishJudgeRepository.depth);
      expect(
        await StockfishJudgeRepository(
          _Stockfish((centipawns: limit, mate: null)),
        ).evaluate(_pos(_fivePieces)),
        Wdl.draw,
      );
      expect(
        await StockfishJudgeRepository(
          _Stockfish((centipawns: -limit - 1, mate: null)),
        ).evaluate(_pos(_fivePieces)),
        Wdl.loss,
      );
    });

    test('motor sem resposta: não sabe', () async {
      expect(
        await StockfishJudgeRepository(_Stockfish(null))
            .evaluate(_pos(_fivePieces)),
        isNull,
      );
    });
  });
}
