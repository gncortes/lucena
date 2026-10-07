import 'package:lucena/domain/use_cases/spoken_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('em português', () {
    const cases = {
      'Tf3': 'torre f3',
      'Taf3': 'torre de a para f3',
      'T1f3': 'torre de 1 para f3',
      'Cxe5+': 'cavalo toma e5, xeque',
      'Dh7#': 'dama h7, xeque-mate',
      'O-O': 'roque pequeno',
      'O-O-O': 'roque grande',
      'e8=D': 'e8, promove a dama',
      'exd5': 'e toma d5',
      'Kd6 ou Ke6': 'rei d6 ou rei e6',
      'Rb3': 'rei b3',
      'O rei vai para e4.': 'O rei vai para e4.',
      'De5+, Da1+ e Db1+.': 'dama e5, xeque, dama a1, xeque e dama b1, xeque.',
      'Bb3 fecha d5 e f5': 'bispo b3 fecha d5 e f5',
      'De novo, Dama!': 'De novo, Dama!',
    };
    cases.forEach((text, spoken) {
      test('"$text" → "$spoken"', () {
        expect(SpokenText.speakable(text, 'pt'), spoken);
      });
    });

    test('o português do Brasil usa as mesmas palavras', () {
      expect(SpokenText.speakable('Tf3', 'pt-BR'), 'torre f3');
    });
  });

  group('em inglês', () {
    const cases = {
      'Rf3': 'rook f3',
      'Raf3': 'rook from a to f3',
      'Nxe5+': 'knight takes e5, check',
      'Qh7#': 'queen h7, checkmate',
      'O-O': 'castles kingside',
      'O-O-O': 'castles queenside',
      'e8=Q': 'e8, promotes to a queen',
      'Kd6 or Ke6': 'king d6 or king e6',
      'A rook on f3.': 'A rook on f3.',
    };
    cases.forEach((text, spoken) {
      test('"$text" → "$spoken"', () {
        expect(SpokenText.speakable(text, 'en'), spoken);
      });
    });
  });

  group('em espanhol', () {
    const cases = {
      'Tf3': 'torre f3',
      'Taf3': 'torre de a a f3',
      'Cxe5+': 'caballo captura e5, jaque',
      'Ab5#': 'alfil b5, jaque mate',
      'O-O': 'enroque corto',
      'O-O-O': 'enroque largo',
      'e8=D': 'e8, corona dama',
      'Rd6': 'rey d6',
    };
    cases.forEach((text, spoken) {
      test('"$text" → "$spoken"', () {
        expect(SpokenText.speakable(text, 'es'), spoken);
      });
    });
  });

  test('nos outros idiomas o texto vai como está', () {
    expect(SpokenText.speakable('Tf3 Cxe5+', 'de'), 'Tf3 Cxe5+');
  });

  group('o caminho de volta para o texto da tela', () {
    const text = 'Agora Tf3 e o rei foge.';
    final utterance = SpokenText.utterance(text, 'pt');

    test('o texto falado', () {
      expect(utterance.text, 'Agora torre f3 e o rei foge.');
    });

    test('antes do lance, a mesma posição', () {
      expect(utterance.displayOffset(5), 5);
    });

    test('dentro do lance, proporcional', () {
      // "torre f3" ocupa 6..14 na fala e "Tf3", 6..9 na tela.
      expect(utterance.displayOffset(6), 6);
      expect(utterance.displayOffset(14), 9);
      expect(utterance.displayOffset(10), inInclusiveRange(6, 9));
    });

    test('depois do lance, deslocado', () {
      final spoken = utterance.text.indexOf('foge');
      expect(utterance.displayOffset(spoken), text.indexOf('foge'));
      expect(utterance.displayOffset(utterance.text.length), text.length);
    });

    test('sem lance, igual', () {
      final plain = SpokenText.utterance('Muito bem.', 'pt');
      expect(plain.text, 'Muito bem.');
      expect(plain.displayOffset(4), 4);
    });
  });

  group('o lance do motor, em inglês, falado no idioma', () {
    const cases = {
      ('Rf3', 'pt'): 'torre f3',
      ('Kg4', 'pt'): 'rei g4',
      ('Qxe5+', 'pt'): 'dama toma e5, xeque',
      ('b8=Q#', 'pt'): 'b8, promove a dama, xeque-mate',
      ('O-O', 'pt'): 'roque pequeno',
      ('Nf3', 'en'): 'knight f3',
      ('Bb5', 'es'): 'alfil b5',
      ('Rf3', 'de'): 'Rf3',
    };
    cases.forEach((key, spoken) {
      final (san, language) = key;
      test('$san em $language → "$spoken"', () {
        expect(SpokenText.san(san, language), spoken);
      });
    });
  });
}
