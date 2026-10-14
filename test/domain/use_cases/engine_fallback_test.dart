import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/use_cases/engine_fallback.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';

void main() {
  final after = Chess.initial;
  final legal = Move.parse('e2e4')!;

  EngineFallback engine({Evaluation? evaluation, Object? error, Move? reply}) =>
      EngineFallback(
        evaluate: (_, _) async {
          if (error != null) throw error;
          return evaluation;
        },
        bestMove: (_) async => reply,
      );

  test('ganha: mantém', () async {
    final a = await engine(evaluation: const Evaluation(centipawns: 900))
        .respond(after, student: Side.white, mustWin: true);
    expect(a.verdict, EngineVerdict.keeps);
    expect(a.reply, isNull);
  });

  test('perde o ganho: traz a resposta', () async {
    final a = await engine(
      evaluation: const Evaluation(centipawns: 0),
      reply: legal,
    ).respond(after, student: Side.white, mustWin: true);
    expect(a.verdict, EngineVerdict.loses);
    expect(a.reply, legal);
  });

  test('empate: mantém com avaliação igual', () async {
    final a = await engine(evaluation: const Evaluation(centipawns: 0))
        .respond(after, student: Side.white, mustWin: false);
    expect(a.verdict, EngineVerdict.keeps);
  });

  test('replyOnKeep traz a resposta também ao manter', () async {
    final a = await engine(
      evaluation: const Evaluation(centipawns: 900),
      reply: legal,
    ).respond(after, student: Side.white, mustWin: true, replyOnKeep: true);
    expect(a.verdict, EngineVerdict.keeps);
    expect(a.reply, legal);
  });

  test('exceção, sem avaliação ou lance ilegal: falha', () async {
    expect(
      (await engine(
        error: StateError('x'),
      ).respond(after, student: Side.white, mustWin: true)).verdict,
      EngineVerdict.failed,
    );
    expect(
      (await engine().respond(
        after,
        student: Side.white,
        mustWin: true,
      )).verdict,
      EngineVerdict.failed,
    );
    expect(
      (await engine(
        evaluation: const Evaluation(centipawns: 0),
        reply: Move.parse('e2e5'),
      ).respond(after, student: Side.white, mustWin: true)).verdict,
      EngineVerdict.failed,
    );
  });
}
