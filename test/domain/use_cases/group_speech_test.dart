import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/use_cases/group_speech.dart';

ScriptStep _step(
  String t, {
  String fen = 'A',
  String? move,
  bool jump = false,
}) => ScriptStep(fen: fen, t: t, move: move, jump: jump);

void main() {
  String say(String key) => key;
  bool upTo(int chars, List<String> texts) =>
      texts.fold<int>(0, (sum, t) => sum + t.length) <= chars;

  test('sem medida da tela, um balão por passo', () {
    final steps = [_step('aa'), _step('bb')];
    expect(GroupSpeech.groups(steps, say, null), [(0, 1), (1, 2)]);
  });

  test('junta enquanto cabe', () {
    final steps = [_step('aa'), _step('bb'), _step('cc')];
    expect(GroupSpeech.groups(steps, say, (t) => upTo(4, t)), [(0, 2), (2, 3)]);
    expect(GroupSpeech.groups(steps, say, (t) => upTo(99, t)), [(0, 3)]);
  });

  test('não junta passo com lance, salto ou outra posição', () {
    expect(
      GroupSpeech.groups(
        [_step('a'), _step('b', move: 'e2e4')],
        say,
        (_) => true,
      ),
      [(0, 1), (1, 2)],
    );
    expect(
      GroupSpeech.groups(
        [_step('a'), _step('b', jump: true)],
        say,
        (_) => true,
      ),
      [(0, 1), (1, 2)],
    );
    expect(
      GroupSpeech.groups([_step('a'), _step('b', fen: 'B')], say, (_) => true),
      [(0, 1), (1, 2)],
    );
  });

  test(
    'a cabeça pode ter lance e juntar os passos parados da mesma posição',
    () {
      final steps = [_step('a', move: 'e2e4'), _step('b'), _step('c')];
      expect(GroupSpeech.groups(steps, say, (_) => true), [(0, 3)]);
    },
  );
}
