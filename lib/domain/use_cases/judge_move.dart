import 'package:dartchess/dartchess.dart';

import '../models/kpk_outcome.dart';
import '../models/wdl.dart';
import 'kpk_oracle.dart';
import 'position_judge.dart';

/// Se um lance mantém ou perde o resultado que o aluno busca (T70).
enum MoveVerdict { keeps, loses }

abstract final class JudgeMove {
  /// O resultado [after] cumpre o que o aluno busca: quem quer ganhar precisa
  /// da vitória; quem quer empatar, do empate. Fora da tabela: mantém (a
  /// tabela não sabe, e o roteiro não usa posições assim).
  static MoveVerdict ofOutcome(KpkOutcome after, {required bool wantsWin}) {
    if (after.isOutside) return MoveVerdict.keeps;
    return after.isWin == wantsWin ? MoveVerdict.keeps : MoveVerdict.loses;
  }

  /// O lance [move] jogado em [before], julgado pela tabela.
  static MoveVerdict judge(
    KpkOracle oracle,
    Position before,
    Move move, {
    required bool wantsWin,
  }) => ofOutcome(
    oracle.evaluate(before.playUnchecked(move)),
    wantsWin: wantsWin,
  );

  /// O resultado [after] (de quem joga depois do lance, o adversário do
  /// aluno) cumpre o objetivo: quem quer ganhar precisa da vitória; quem quer
  /// empatar, de não perder (T76). Nulo (o juiz não sabe): mantém.
  static MoveVerdict ofWdl(Wdl? after, {required bool wantsWin}) {
    if (after == null) return MoveVerdict.keeps;
    final mine = after.flipped;
    final keeps = wantsWin ? mine == Wdl.win : mine != Wdl.loss;
    return keeps ? MoveVerdict.keeps : MoveVerdict.loses;
  }

  /// O lance [move] jogado em [before], julgado por [judge].
  static Future<MoveVerdict> judgeWith(
    PositionJudge judge,
    Position before,
    Move move, {
    required bool wantsWin,
  }) async => ofWdl(
    await judge.evaluate(before.playUnchecked(move)),
    wantsWin: wantsWin,
  );
}
