import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/tablebase/kpk_repository.dart';
import 'package:lucena/data/repositories/tablebase/script_table_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/script_table.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_position_judge.dart';

/// O juiz KBNK (T77, sessão 0): a prática `jogo` de bispo e cavalo com o
/// objetivo `mate` roda até o mate com a máquina defendendo pela tabela do
/// roteiro (`tools/script_tables.py`: a defesa que mais demora a levar mate),
/// e o lance que deixa a vitória escapar não passa como certo, esteja ou não
/// na tabela.

const _lesson = 'mates.bishopKnight.deletang';
const _key = '$_lesson/finalNet';

/// A etapa da prática (ideia, demos, prática).
const _practiceStage = 2;

/// Os assets lidos do disco, como o app os lê do pacote.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await io.File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      io.File(key).readAsString();
}

class _FixedTables implements ScriptTableRepository {
  _FixedTables(this._table);

  final ScriptTable _table;

  @override
  Future<ScriptTable> table(String scriptPath) async => _table;
}

final _kpk = KpkTableOracle(io.File(AssetKpkRepository.path).readAsBytesSync());

Map<String, String> _positions() {
  final path = AssetScriptTableRepository.pathFor(
    AssetLessonScriptRepository.scriptPath(_key),
  );
  final json = jsonDecode(io.File(path).readAsStringSync()) as Map;
  return (json['posicoes'] as Map).cast<String, String>();
}

class _Run {
  _Run(this.cubit, this.engine, this.opponent);

  final LessonScriptCubit cubit;
  final FakePositionJudge engine;
  final FakeOpponentRepository opponent;

  LessonScriptState get s => cubit.state;
}

Future<_Run> _open(ScriptTable table, {FakePositionJudge? engine}) async {
  final repository = AssetLessonScriptRepository(AssetService(_DiskBundle()));
  final path = AssetLessonScriptRepository.scriptPath(_key);
  final script = await repository.script(path);
  final judge = engine ?? FakePositionJudge();
  final opponent = FakeOpponentRepository();
  final cubit = LessonScriptCubit(
    lessonId: _lesson,
    partId: script.partId,
    scriptPath: path,
    language: 'pt',
    scripts: repository,
    kpk: FakeKpkRepository(_kpk),
    source: FakeLessonSource(),
    initialStage: _practiceStage,
    opponent: opponent,
    tables: _FixedTables(table),
    engineJudge: judge,
    delay: (_) => Future.value(),
    timer: (_, _) => Timer(const Duration(days: 1), () {}),
  );
  addTearDown(cubit.close);
  await cubit.start();
  return _Run(cubit, judge, opponent);
}

/// Os lances legais de [fen] em UCI, em ordem.
List<String> _legal(String fen) {
  final position = GameRules.fromFen(fen)!;
  return [
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries)
      for (final to in targets.squares) NormalMove(from: from, to: to).uci,
  ]..sort();
}

String _after(String fen, String uci) =>
    GameRules.fromFen(fen)!.play(Move.parse(uci)!).fen;

void main() {
  final positions = _positions();
  final table = ScriptTable(positions);

  test('a tabela do roteiro tem a prática KBNK', () {
    expect(table.length, greaterThan(0));
  });

  test('a prática roda até o mate, a máquina pela tabela', () async {
    final r = await _open(table);
    expect(r.s.phase, ScriptPhase.praticaVez);
    expect(r.s.movable, Side.white);
    for (var i = 0; i < 40 && r.s.phase == ScriptPhase.praticaVez; i++) {
      final fen = r.s.fen;
      final best = table.best(fen);
      expect(best, isNotNull, reason: 'o aluno sem lance na tabela em $fen');
      await r.cubit.onMove(best!);
      if (r.s.phase != ScriptPhase.praticaVez) break;
      final defended = _after(fen, best);
      // A máquina respondeu com o lance da tabela, não com o motor.
      expect(r.s.lastMove, table.best(defended));
    }
    expect(r.s.phase, ScriptPhase.praticaFim);
    expect(r.s.tone, ScriptTone.good);
    expect(GameRules.fromFen(r.s.fen)!.isCheckmate, isTrue);
    expect(r.s.moves.last.result, '1–0');
    expect(r.opponent.requests, isEmpty);
    expect(r.engine.asked, isEmpty);
  });

  test('o lance que empata pela tabela é refutado, não segue', () async {
    final r = await _open(table);
    final start = r.s.fen;
    final drawing = _legal(start)
        .firstWhere((uci) => table.wdl(_after(start, uci)) == Wdl.draw);
    await r.cubit.onMove(drawing);
    expect(r.s.phase, ScriptPhase.praticaFim);
    expect(r.s.tone, ScriptTone.bad);
    expect(r.s.primary, ScriptAction.tentarDeNovo);
    await r.cubit.onAction(ScriptAction.tentarDeNovo);
    expect(r.s.fen, start);
    expect(r.s.phase, ScriptPhase.praticaVez);
    expect(r.s.movable, Side.white);
  });

  test(
    'lance fora da tabela não passa como certo: vale o juiz de reserva',
    () async {
      final start = (await _open(table)).s.fen;
      final winning = _legal(start).firstWhere(
        (uci) =>
            uci != table.best(start) &&
            table.wdl(_after(start, uci)) == Wdl.loss,
      );
      final missing = ScriptTable.keyOf(_after(start, winning));
      final r = await _open(
        ScriptTable({...positions}..remove(missing)),
        engine: FakePositionJudge(results: {missing: Wdl.draw}),
      );
      await r.cubit.onMove(winning);
      expect(r.engine.asked, [missing]);
      expect(r.s.tone, ScriptTone.bad);
      expect(r.s.primary, ScriptAction.tentarDeNovo);
    },
  );
}
