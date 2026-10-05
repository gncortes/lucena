import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/use_cases/game_events.dart';
import 'package:lucena/domain/use_cases/line_picker.dart';

void main() {
  CharacterLine line(
    String id,
    LineCategory category, {
    int intensity = 1,
    Emotion emotion = Emotion.calm,
  }) => CharacterLine(
    id: id,
    category: category,
    intensity: intensity,
    emotion: emotion,
    text: id,
  );

  final lines = [
    line('blunder.1', LineCategory.opponentBlunder, intensity: 2),
    line('blunder.2', LineCategory.opponentBlunder, intensity: 2),
    line('blunder.3', LineCategory.opponentBlunder, intensity: 2),
    line('blunder.4', LineCategory.opponentBlunder, intensity: 3),
    line('better.1', LineCategory.better),
    line('better.2', LineCategory.better, emotion: Emotion.playful),
    line('lost.1', LineCategory.pieceLost, intensity: 3),
    line('lowTime.1', LineCategory.opponentLowTime, intensity: 2),
  ];

  const blunder = GameEvent(LineCategory.opponentBlunder, 2);

  test('mesma situação muitas vezes: sem repetir até esgotar, nunca duas '
      'vezes seguidas', () {
    var memory = TalkMemory.empty;
    final said = <String>[];
    for (var i = 0; i < 12; i++) {
      final got = LinePicker.pick(
        lines: lines,
        events: const [blunder],
        memory: memory,
        roll: 0,
      )!;
      said.add(got.line.id);
      memory = got.memory;
    }
    // As 4 primeiras são as 4 falas, sem repetir (as de intensidade 2 antes).
    expect(said.take(4).toSet(), hasLength(4));
    expect(said.take(3).toSet(), {'blunder.1', 'blunder.2', 'blunder.3'});
    for (var i = 1; i < said.length; i++) {
      expect(said[i], isNot(said[i - 1]), reason: 'fala $i');
    }
    expect(said.skip(4).toSet().length, greaterThan(1));
  });

  test('roll escolhe entre as candidatas', () {
    final first = LinePicker.pick(
      lines: lines,
      events: const [blunder],
      memory: TalkMemory.empty,
      roll: 0,
    )!;
    final last = LinePicker.pick(
      lines: lines,
      events: const [blunder],
      memory: TalkMemory.empty,
      roll: 1,
    )!;
    expect(first.line.id, 'blunder.1');
    expect(last.line.id, 'blunder.3');
  });

  test('a memória volta com a fala, a emoção e o contador zerado', () {
    const memory = TalkMemory(movesSinceLine: 5, scores: [150, 150, 150]);
    final got = LinePicker.pick(
      lines: lines,
      events: const [GameEvent(LineCategory.better)],
      memory: memory,
      roll: 0,
    )!;
    // A emoção do momento é brincalhão: prefere a fala dessa emoção.
    expect(got.line.id, 'better.2');
    expect(got.memory.spoken, ['better.2']);
    expect(got.memory.lastLineId, 'better.2');
    expect(got.memory.emotion, Emotion.playful);
    expect(got.memory.movesSinceLine, 0);
  });

  test('evento comum espera o intervalo; prioritário não', () {
    const fresh = TalkMemory(movesSinceLine: 1);
    expect(
      LinePicker.pick(
        lines: lines,
        events: const [GameEvent(LineCategory.better)],
        memory: fresh,
        roll: 0,
      ),
      isNull,
    );
    final got = LinePicker.pick(
      lines: lines,
      events: const [GameEvent(LineCategory.better), blunder],
      memory: fresh,
      roll: 0,
    );
    expect(got!.line.category, LineCategory.opponentBlunder);

    final later = LinePicker.pick(
      lines: lines,
      events: const [GameEvent(LineCategory.better)],
      memory: LinePicker.moved(fresh),
      roll: 0,
    );
    expect(later, isNotNull);
  });

  test('categoria sem fala passa para o próximo evento', () {
    final got = LinePicker.pick(
      lines: lines,
      events: const [
        GameEvent(LineCategory.comeback, 3),
        GameEvent(LineCategory.pieceLost, 1),
      ],
      memory: const TalkMemory(movesSinceLine: 3),
      roll: 0,
    );
    expect(got!.line.id, 'lost.1');
    expect(
      LinePicker.pick(
        lines: lines,
        events: const [GameEvent(LineCategory.win)],
        memory: TalkMemory.empty,
        roll: 0,
      ),
      isNull,
    );
  });

  test('uma única fala já dita por último não se repete', () {
    final got = LinePicker.pick(
      lines: lines,
      events: const [GameEvent(LineCategory.pieceLost, 3)],
      memory: const TalkMemory(
        movesSinceLine: 3,
        spoken: ['lost.1'],
        lastLineId: 'lost.1',
      ),
      roll: 0,
    );
    expect(got, isNull);
  });

  test('evento de uma vez só marca a memória', () {
    final got = LinePicker.pick(
      lines: lines,
      events: const [GameEvent(LineCategory.opponentLowTime, 2)],
      memory: const TalkMemory(movesSinceLine: 3),
      roll: 0,
    )!;
    expect(got.memory.onceFlags, {'opponentLowTime'});
  });
}
