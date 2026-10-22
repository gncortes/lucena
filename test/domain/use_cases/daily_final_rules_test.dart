import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/daily_final_rules.dart';

void main() {
  final queue = DailyQueue(
    version: 1,
    epoch: DateTime(2026, 10, 1),
    ids: const ['a', 'b', 'c', 'd'],
  );

  group('idOf', () {
    test('mesma data, mesmo final, a qualquer hora do dia', () {
      final morning = DailyFinalRules.idOf(DateTime(2026, 10, 2, 0, 1), queue);
      final night = DailyFinalRules.idOf(DateTime(2026, 10, 2, 23, 59), queue);
      expect(morning, 'b');
      expect(night, 'b');
    });

    test('vira o dia à meia-noite', () {
      expect(DailyFinalRules.idOf(DateTime(2026, 10, 2, 23, 59), queue), 'b');
      expect(DailyFinalRules.idOf(DateTime(2026, 10, 3), queue), 'c');
    });

    test('o documento do dia ganha da fila', () {
      expect(
        DailyFinalRules.idOf(DateTime(2026, 10, 2), queue, override: 'z'),
        'z',
      );
    });

    test('não repete até a fila acabar, depois recomeça', () {
      final days = [
        for (var d = 1; d <= 4; d++)
          DailyFinalRules.idOf(DateTime(2026, 10, d), queue),
      ];
      expect(days.toSet(), hasLength(4));
      expect(DailyFinalRules.idOf(DateTime(2026, 10, 5), queue), 'a');
    });

    test('virada de mês e horário de verão não pulam nem repetem', () {
      // 1º de novembro de 2026: começa o horário de verão em alguns fusos.
      final ids = [
        for (var d = 29; d <= 35; d++)
          DailyFinalRules.idOf(DateTime(2026, 10, d, 12), queue),
      ];
      expect(ids, ['a', 'b', 'c', 'd', 'a', 'b', 'c']);
    });

    test('antes do começo da fila ainda dá um final', () {
      expect(DailyFinalRules.idOf(DateTime(2026, 9, 30), queue), 'd');
    });

    test('fila vazia e sem documento: nenhum', () {
      expect(
        DailyFinalRules.idOf(DateTime(2026, 10, 2), DailyQueue.empty),
        isNull,
      );
    });
  });

  group('square', () {
    test('mantém o resultado: certo', () {
      expect(DailyFinalRules.square(Wdl.win, Wdl.win), DailySquare.right);
      expect(DailyFinalRules.square(Wdl.draw, Wdl.draw), DailySquare.right);
    });

    test('piora o resultado: estragou', () {
      expect(DailyFinalRules.square(Wdl.win, Wdl.draw), DailySquare.bad);
      expect(DailyFinalRules.square(Wdl.draw, Wdl.loss), DailySquare.bad);
    });

    test('depois de um erro do adversário, melhorar não é erro', () {
      expect(DailyFinalRules.square(Wdl.draw, Wdl.win), DailySquare.right);
    });

    test('o juiz não sabe: certo', () {
      expect(DailyFinalRules.square(null, Wdl.loss), DailySquare.right);
      expect(DailyFinalRules.square(Wdl.win, null), DailySquare.right);
    });
  });

  test('o registro vai e volta em JSON', () {
    final record = DailyRecord(
      date: DateTime(2026, 10, 22),
      positionId: 'pawn.pawnVsKing.0001',
      outcome: DailyOutcome.won,
      fulfilled: true,
      squares: const [DailySquare.right, DailySquare.bad],
    );
    final back = DailyRecord.fromJson(record.toJson());
    expect(back.date, record.date);
    expect(back.positionId, record.positionId);
    expect(back.outcome, DailyOutcome.won);
    expect(back.fulfilled, isTrue);
    expect(back.squares, record.squares);
    expect(back.moves, 2);
  });
}
