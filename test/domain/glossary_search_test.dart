import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/glossary_term.dart';
import 'package:lucena/domain/use_cases/glossary_search.dart';

import '../../testing/fakes/fake_glossary.dart';

void main() {
  const distante = GlossaryTerm(
    id: 'oposicao-distante',
    name: 'Oposição distante',
    definition: 'Três casas vazias entre os reis.',
  );

  group('filtro', () {
    test('busca vazia devolve todos', () {
      expect(GlossarySearch.filter(fakeGlossaryTerms, '  '), fakeGlossaryTerms);
    });

    test('ignora acento e caixa', () {
      final found = GlossarySearch.filter(fakeGlossaryTerms, 'OPOSICAO');
      expect(found.map((t) => t.id), ['oposicao']);
    });

    test('sem resultado devolve lista vazia', () {
      expect(GlossarySearch.filter(fakeGlossaryTerms, 'roque'), isEmpty);
    });
  });

  group('termos na fala', () {
    test('acha o termo como palavra inteira, com o índice do original', () {
      const text = 'Construa a ponte, e é zugzwang.';
      final found = GlossarySearch.find(text, fakeGlossaryTerms);
      expect(found.map((m) => text.substring(m.start, m.end)), [
        'ponte',
        'zugzwang',
      ]);
    });

    test('não acha dentro de outra palavra', () {
      expect(
        GlossarySearch.find('pontes? apontei', [
          fakeGlossaryTerms[1],
        ]).map((m) => m.end - m.start),
        [6],
      );
    });

    test('o nome mais longo ganha e não há sobreposição', () {
      const text = 'A oposição distante vira oposição direta.';
      final found = GlossarySearch.find(text, [
        fakeGlossaryTerms.first,
        distante,
      ]);
      expect(found.map((m) => m.term.id), ['oposicao-distante', 'oposicao']);
    });
  });

  group('variantes e sinônimos', () {
    const afastado = GlossaryTerm(
      id: 'peao-passado-distante',
      name: 'peão passado distante',
      definition: 'd',
      synonyms: ['peão passado afastado'],
    );
    const ala = GlossaryTerm(
      id: 'ala',
      name: 'ala do rei / ala da dama',
      definition: 'd',
    );
    const corte = GlossaryTerm(
      id: 'corte',
      name: 'corte (do rei)',
      definition: 'd',
    );

    test('a busca casa o sinônimo', () {
      expect(GlossarySearch.filter([afastado, ala], 'afastado'), [afastado]);
    });

    test('a fala casa cada variante, o sinônimo e o nome sem parêntese', () {
      const text = 'Na ala da dama, o peão passado afastado; o corte basta.';
      final found = GlossarySearch.find(text, [afastado, ala, corte]);
      expect(found.map((m) => text.substring(m.start, m.end)), [
        'ala da dama',
        'peão passado afastado',
        'corte',
      ]);
    });
  });

  test('lê sinônimos, nota e aulas do asset', () {
    final term = GlossaryTerm.fromJson({
      'id': 'a',
      'nome': 'afogamento',
      'definicao': 'd',
      'nota': 'n',
      'sinonimos': ['empate por afogamento', 3],
      'aulas': ['endgames/basics.kingPawn'],
    });
    expect(term?.synonyms, ['empate por afogamento']);
    expect(term?.note, 'n');
    expect(term?.lessons, ['endgames/basics.kingPawn']);
    expect(GlossaryTerm.fromJson({'id': 'a', 'nome': 'x'}), isNull);
  });

  test('chaveWiki vira o endereço do verbete', () {
    expect(
      fakeGlossaryTerms.last.wikiUrl.toString(),
      'https://pt.wikipedia.org/wiki/Zugzwang',
    );
    expect(fakeGlossaryTerms[1].wikiUrl, isNull);
  });
}
