import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/wiki_links.dart';
import 'package:lucena/domain/use_cases/spoken_text.dart';
import 'package:lucena/domain/use_cases/wiki_markup.dart';

void main() {
  group('WikiMarkup', () {
    test('texto sem marcação fica como está', () {
      final marked = WikiMarkup.parse('Com 1.Rf7! as brancas vencem.');
      expect(marked.text, 'Com 1.Rf7! as brancas vencem.');
      expect(marked.marks, isEmpty);
    });

    test('tira a marcação e acha os nomes nas posições do texto limpo', () {
      final marked = WikiMarkup.parse(
        'Em 1985, {{Andersson|ulf-andersson}} jogou em '
        '{{Skellefteå|skelleftea}}.',
      );
      expect(marked.text, 'Em 1985, Andersson jogou em Skellefteå.');
      expect(marked.marks, const [
        WikiMark(start: 9, end: 18, text: 'Andersson', key: 'ulf-andersson'),
        WikiMark(start: 28, end: 38, text: 'Skellefteå', key: 'skelleftea'),
      ]);
      expect(
        marked.text.substring(marked.marks[1].start, marked.marks[1].end),
        'Skellefteå',
      );
    });

    test('nome com espaço e marcação no começo e no fim', () {
      final marked = WikiMarkup.parse('{{Ulf Andersson|a}} e {{Karpov|b}}');
      expect(marked.text, 'Ulf Andersson e Karpov');
      expect(marked.marks.first.start, 0);
      expect(marked.marks.last.end, marked.text.length);
    });

    test('marcação incompleta não é nome: fica como veio', () {
      expect(
        WikiMarkup.plain('{{Andersson}} e {{x|}}'),
        '{{Andersson}} e {{x|}}',
      );
    });

    test('as chaves usadas', () {
      expect(WikiMarkup.keys('{{A|a}} e {{B|b}}').toList(), ['a', 'b']);
    });
  });

  group('WikiLinks', () {
    final links = WikiLinks.fromJson({
      'a': {
        'pt': 'https://pt.wikipedia.org/wiki/A',
        'en': 'https://en.wikipedia.org/wiki/A',
      },
      'b': {'en': 'https://en.wikipedia.org/wiki/B'},
      'c': {'pt': ''},
    });

    test('o idioma do app ou, sem ele, o inglês', () {
      expect(links.url('a', 'pt')?.host, 'pt.wikipedia.org');
      expect(links.url('a', 'pt-BR')?.host, 'pt.wikipedia.org');
      expect(links.url('a', 'es')?.host, 'en.wikipedia.org');
      expect(links.url('b', 'pt')?.host, 'en.wikipedia.org');
    });

    test('chave sem página: nulo', () {
      expect(links.url('c', 'pt'), isNull);
      expect(links.url('zzz', 'en'), isNull);
      expect(WikiLinks.fromJson('lixo').url('a', 'en'), isNull);
    });
  });

  test('a voz lê só o texto visível, nunca a chave', () {
    final utterance = SpokenText.utterance(
      'Agora {{Andersson|ulf-andersson}} joga Tf7.',
      'pt',
    );
    expect(utterance.text, isNot(contains('ulf-andersson')));
    expect(utterance.text, isNot(contains('{{')));
    expect(utterance.text, contains('Andersson'));
  });

  test('títulos e resumos saem sem a marcação; a fala, com', () {
    final texts = LessonTexts.fromJson({
      'x.title': 'Final de {{Andersson|ulf-andersson}}',
      'x.summary': 'Como {{Andersson|ulf-andersson}} venceu.',
      'x.s1': 'Olhe {{Andersson|ulf-andersson}}.',
    });
    expect(texts.lessonTitle('x'), 'Final de Andersson');
    expect(texts.lessonSummary('x'), 'Como Andersson venceu.');
    expect(texts.step('x', 's1'), 'Olhe {{Andersson|ulf-andersson}}.');
    expect(texts.plain('x.s1'), 'Olhe Andersson.');
  });
}
