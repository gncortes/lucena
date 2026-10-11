import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/speech_lines.dart';
import 'package:lucena/domain/use_cases/speech_links.dart';

void main() {
  const pt = SpeechLinks.portuguese;
  const en = SpeechLinks.english;
  // Lucena: brancas Rb8, peão b7, torre c1; pretas Rd8, torre a2.
  const lucena = '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1';

  List<SpeechLine> lines(
    String text, {
    Map<String, Role> letters = pt,
    List<String> bases = const [lucena],
  }) => SpeechLines.find(SpeechLinks.find(text, letters), letters, bases);

  List<String> texts(SpeechLine line) => [
    for (final link in line.links) link.text,
  ];

  test('o número do lance em meios-lances', () {
    int? ply(String text) =>
        SpeechLines.plyNumberOf(SpeechLinks.find(text, pt).single);
    expect(ply('1.Tc4'), 0);
    expect(ply('1...Re7'), 1);
    expect(ply('2.Td4'), 2);
    expect(ply('40...Ta1'), 79);
    expect(ply('Tc4'), isNull);
  });

  test('uma linha numerada em português vira uma variante só', () {
    final found = lines('Com 1.Td1+ Re7 2.Td4 Ta1 3.Rc7 as brancas vencem.');
    expect(found, hasLength(1));
    final line = found.single;
    expect(texts(line), ['1.Td1+', 'Re7', '2.Td4', 'Ta1', '3.Rc7']);
    expect(line.fens, hasLength(6));
    expect(line.fens.first, startsWith('1K1k4/1P6'));
    expect(line.moves.first, NormalMove(from: Square.c1, to: Square.d1));
    // O rei das brancas sai de b8 para c7 no fim.
    expect(line.moves.last, NormalMove(from: Square.b8, to: Square.c7));
  });

  test('a fala que comenta e retoma pelo número continua a linha', () {
    final found = lines(
      'Com 1.Td1+? o rei preto responde 1...Re7 e depois de 2.Td4 nada muda.',
    );
    expect(found, hasLength(1));
    expect(texts(found.single), ['1.Td1+?', '1...Re7', '2.Td4']);
  });

  test('dois primeiros lances diferentes são duas variantes', () {
    final found = lines('O certo é 1.Td1+, não 1.Tc2 que perde tempo.');
    expect(found.map(texts), [
      ['1.Td1+'],
      ['1.Tc2'],
    ]);
  });

  test('a alternativa no meio sai da posição da linha anterior', () {
    final found = lines('1.Td1+ Re7 2.Td4 Ta1 e, em vez disso, 2.Td7+.');
    expect(found.map(texts), [
      ['1.Td1+', 'Re7', '2.Td4', 'Ta1'],
      ['2.Td7+'],
    ]);
    // 2.Td7+ sai depois de 1...Re7: a torre está em d1.
    expect(found.last.moves.single, NormalMove(from: Square.d1, to: Square.d7));
  });

  test('em inglês, as letras do inglês', () {
    final found = lines('After 1.Rd1+ Ke7 2.Rd4 White wins.', letters: en);
    expect(texts(found.single), ['1.Rd1+', 'Ke7', '2.Rd4']);
  });

  test('lance das pretas numerado não se joga com as brancas a jogar', () {
    expect(lines('1...Ta1'), isEmpty);
    final black = lines(
      '1...Ta1',
      bases: const ['1K1k4/1P6/8/8/8/8/r7/2R5 b - - 0 1'],
    );
    expect(texts(black.single), ['1...Ta1']);
  });

  test('a primeira base em que a linha vai mais longe', () {
    // Na posição do passo a torre ainda está em c1; na atual, em d1.
    const after = '1K1k4/1P6/8/8/8/8/r7/3R4 b - - 1 1';
    final found = lines('Agora Re7 2.Td4.', bases: const [lucena, after]);
    expect(texts(found.single), ['Re7', '2.Td4']);
    expect(found.single.fens.first, after);
  });

  test('lance ilegal e casa solta ficam de fora; posição sem reis não tem '
      'variante', () {
    expect(lines('A casa d4 e o lance 1.Th8.'), isEmpty);
    expect(
      lines('1.Td1+', bases: const ['8/8/8/8/3R4/8/8/8 w - - 0 1']),
      isEmpty,
    );
  });

  test('o cursor anda lance a lance e para nas pontas', () {
    final line = lines('1.Td1+ Re7 2.Td4').single;
    var cursor = SpeechLineCursor(line);
    expect(cursor.fen, line.fens.first);
    expect(cursor.lastMove, isNull);
    expect(cursor.canPrevious, isFalse);
    expect(cursor.previous().ply, 0);
    cursor = cursor.next().next();
    expect(cursor.ply, 2);
    expect(cursor.lastMove, line.moves[1]);
    cursor = cursor.next();
    expect(cursor.canNext, isFalse);
    expect(cursor.next().ply, 3);
    expect(cursor.previous().fen, line.fens[2]);
    expect(line.plyOf(line.links[1]), 2);
    expect(SpeechLines.lineOf([line], line.links.last), same(line));
  });
}
