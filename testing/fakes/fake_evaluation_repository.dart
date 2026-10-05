import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/evaluation/evaluation_repository.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';

/// Avaliação combinada pelo teste: [next] em ordem e, acabando, [fallback].
class FakeEvaluationRepository implements EvaluationRepository {
  FakeEvaluationRepository({this.fallback = const Evaluation(centipawns: 0)});

  Evaluation? fallback;
  final next = <Evaluation?>[];

  /// As posições avaliadas (FEN).
  final requests = <String>[];

  @override
  Future<Evaluation?> evaluate(Position position, {required Side pov}) async {
    requests.add(position.fen);
    return next.isEmpty ? fallback : next.removeAt(0);
  }
}
