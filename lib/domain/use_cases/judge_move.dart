import 'package:dartchess/dartchess.dart';

import '../models/kpk_outcome.dart';
import 'kpk_oracle.dart';

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
}
