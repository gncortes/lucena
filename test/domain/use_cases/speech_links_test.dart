import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/speech_links.dart';

void main() {
  const pt = SpeechLinks.portuguese;
  const en = SpeechLinks.english;

  List<String> texts(String text, Map<String, Role> letters) => [
    for (final link in SpeechLinks.find(text, letters)) link.text,
  ];

  test('casas e lances em português', () {
    final cases = {
      'O bispo em e4 fecha d5 e f5.': ['e4', 'd5', 'f5'],
      'Agora Tf7, e depois Cxe5+.': ['Tf7', 'Cxe5+'],
      'O roque O-O deixa o rei em g1.': ['O-O', 'g1'],
      'Promova com e8=D#.': ['e8=D#'],
      'Tad1 e C5f3 também.': ['Tad1', 'C5f3'],
      'O peão captura: exd5.': ['exd5'],
    };
    for (final MapEntry(key: text, value: expected) in cases.entries) {
      expect(texts(text, pt), expected, reason: text);
    }
    final link = SpeechLinks.find('Agora Tf7.', pt).single;
    expect(link.role, Role.rook);
    expect(link.square, Square.f7);
    expect(link.isMove, isTrue);
    expect(link.start, 6);
    expect(link.end, 9);
    // Casa sozinha não é lance.
    expect(SpeechLinks.find('em e4', pt).single.isMove, isFalse);
  });

  test('em inglês, as letras do inglês', () {
    expect(texts('Then Rf7 and Nxe5, or Qh5#.', en), ['Rf7', 'Nxe5', 'Qh5#']);
    expect(SpeechLinks.find('Rf7', en).single.role, Role.rook);
    // Em português, R é o rei.
    expect(SpeechLinks.find('Rf7', pt).single.role, Role.king);
  });

  test('sem falsos positivos', () {
    for (final text in [
      'abe4 dentro de palavra',
      'e44 não é casa',
      'i5 e h9 não existem',
      'Ze4 não é peça',
      'a cor e o número 4',
    ]) {
      expect(texts(text, pt), isEmpty, reason: text);
    }
  });

  test('a seta: de onde a peça sai, se só uma pode ir', () {
    final position = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/8/8/6K1/4P3/R6R w - - 0 1'),
    );
    (Square, Square)? arrow(String text) =>
        SpeechLinks.arrowFor(position, SpeechLinks.find(text, pt).single);

    expect(arrow('Ta5'), (Square.a1, Square.a5));
    // As duas torres chegam em d1: sem a coluna, não dá para saber.
    expect(arrow('Td1'), isNull);
    expect(arrow('Tad1'), (Square.a1, Square.d1));
    // O peão anda uma ou duas casas.
    expect(arrow('e4'), isNull);
    expect(
      SpeechLinks.arrowFor(
        position,
        const SpeechLink(
          start: 0,
          end: 2,
          text: 'e4',
          square: Square.e4,
          isMove: true,
        ),
      ),
      (Square.e2, Square.e4),
    );
    final castling = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1'),
    );
    (Square, Square)? castle(String text) =>
        SpeechLinks.arrowFor(castling, SpeechLinks.find(text, pt).single);
    expect(castle('O-O'), (Square.e1, Square.g1));
    expect(castle('O-O-O'), (Square.e1, Square.c1));
    // Peça que não está no tabuleiro.
    expect(arrow('Dd5'), isNull);
  });

  test('T60: a avaliação do lance (!, ?, !!, ??, !?, ?!) fica no destaque, '
      'e um peão avaliado é lance', () {
    final links = SpeechLinks.find(
      'Agora Te6! A torre protege. Cuidado com De3? Depois a4?? ou Rd1!?.',
      SpeechLinks.portuguese,
    );
    expect(links.map((link) => link.text), ['Te6!', 'De3?', 'a4??', 'Rd1!?']);
    expect(links.every((link) => link.isMove), isTrue);
  });

  test('T60: o número do lance entra no destaque (40.b4, 40...Re5, 41.h6!!), '
      'e um ano solto não', () {
    final links = SpeechLinks.find(
      'Londres, 1913. Capablanca jogou 39.f5?, e depois de 39...gxf5 40.h5 '
      'o rei voltava com 40...Re6. Só 41.h6!! ganha; 12.O-O também.',
      SpeechLinks.portuguese,
    );
    expect(links.map((link) => link.text), [
      '39.f5?',
      '39...gxf5',
      '40.h5',
      '40...Re6',
      '41.h6!!',
      '12.O-O',
    ]);
    final rook = links[3];
    expect(rook.square, Square.e6);
    expect(rook.isMove, isTrue);
  });
}
