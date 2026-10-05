import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/draw_rules.dart';

void main() {
  test('o Maia só aceita quando a previsão dele é ruim para ele', () {
    expect(DrawRules.maiaAccepts(win: 0.1, draw: 0.1), isTrue);
    expect(DrawRules.maiaAccepts(win: 0.2, draw: 0.2), isFalse);
    expect(DrawRules.maiaAccepts(win: 0.5, draw: 0.3), isFalse);
  });

  test('o Stockfish só aceita bem pior', () {
    expect(DrawRules.engineAccepts(-450), isTrue);
    expect(DrawRules.engineAccepts(-200), isFalse);
    expect(DrawRules.engineAccepts(300), isFalse);
  });
}
