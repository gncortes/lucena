import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';

void main() {
  const game = Reference(
    id: 'capa',
    kind: 'game',
    fields: {
      'white': 'Capablanca',
      'black': 'Lasker',
      'url': 'https://lichess.org/analysis/pgn/1._e4_e5#76',
    },
  );
  const book = Reference(
    id: 'villa',
    kind: 'book',
    fields: {'author': 'de la Villa', 'title': '100 Endgames'},
  );
  const references = [game, book];

  group('Reference.resolve', () {
    test('acha a referência pelo id', () {
      expect(Reference.resolve(references, 'capa'), same(game));
      expect(Reference.resolve(references, 'villa'), same(book));
    });

    test('id#ply troca o ply da url da partida', () {
      final at80 = Reference.resolve(references, 'capa#80');
      expect(at80?.url, 'https://lichess.org/analysis/pgn/1._e4_e5#80');
      expect(at80?.kind, 'game');
      expect(at80?['white'], 'Capablanca');
    });

    test('ply numa referência sem url devolve a referência como está', () {
      expect(Reference.resolve(references, 'villa#12'), same(book));
    });

    test('nulo sem ref ou sem a referência', () {
      expect(Reference.resolve(references, null), isNull);
      expect(Reference.resolve(references, 'nada'), isNull);
      expect(Reference.resolve(references, 'nada#3'), isNull);
    });
  });

  group('Reference.isLearnerFacing', () {
    test('oculta fontes de produção e mantém referências do aluno', () {
      const archive = Reference(
        id: 'pgnMentor',
        kind: 'web',
        fields: {'url': 'https://www.pgnmentor.com/players/Fischer.zip'},
      );
      const page = Reference(
        id: 'game',
        kind: 'game',
        fields: {'url': 'https://www.chessgames.com/perl/chessgame?gid=1'},
      );

      expect(archive.isLearnerFacing, isFalse);
      expect(page.isLearnerFacing, isTrue);
    });
  });
}
