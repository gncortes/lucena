import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/tablebase/kpk_repository.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';

/// Um oráculo escrito à mão: o resultado de cada posição pelo FEN (peças e
/// vez), ou [fallback] para as outras.
class FakeKpkOracle implements KpkOracle {
  FakeKpkOracle({
    this.fallback = const KpkOutcome.win(10),
    Map<String, KpkOutcome>? byFen,
    this.rule,
  }) : byFen = {
         for (final entry in (byFen ?? const <String, KpkOutcome>{}).entries)
           _key(entry.key): entry.value,
       };

  final KpkOutcome fallback;
  final Map<String, KpkOutcome> byFen;

  /// Decide antes do mapa e do [fallback]; nulo passa adiante.
  final KpkOutcome? Function(Position position)? rule;

  /// As posições avaliadas, em FEN.
  final asked = <String>[];

  static String _key(String fen) => fen.split(' ').take(2).join(' ');

  @override
  KpkOutcome evaluate(Position position) {
    asked.add(position.fen);
    return rule?.call(position) ?? byFen[_key(position.fen)] ?? fallback;
  }
}

class FakeKpkRepository implements KpkRepository {
  FakeKpkRepository([KpkOracle? oracle]) : _oracle = oracle ?? FakeKpkOracle();

  final KpkOracle _oracle;

  @override
  Future<KpkOracle> oracle() async => _oracle;
}
