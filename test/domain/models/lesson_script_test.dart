import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';

import '../../../testing/script_fixture.dart';

void main() {
  final script = scriptFixture();

  test('lê etapas, exemplos e a pergunta', () {
    expect(script.lessonId, 'pawns.test');
    expect(script.partId, 'distant');
    expect(
      [for (final s in script.stages) s.id],
      ['ideia', 'demos', 'pratica'],
    );
    final ex1 = script.stages[0].examples[0];
    expect(ex1.flip, isFalse);
    expect(ex1.goal, ScriptGoal.ganhar);
    expect(ex1.entry, hasLength(3));
    expect(ex1.entry[1].marks, ['d3']);
    final q = ex1.question!;
    expect(q.right, ['d3e4']);
    expect(q.rightStep.move, 'd3e4');
    expect(q.errors.keys, ['d3d4']);
    expect(q.errors['d3d4'], hasLength(2));
    expect(q.free!.ends['capturado'], 'fin.cap');
    expect(ex1.end, ScriptEnd.proximo);
  });

  test('o lado do aluno vem do vira; salto e alternativos', () {
    final ex2 = script.stages[0].examples[1];
    expect(ex2.flip, isTrue);
    expect(ex2.goal, ScriptGoal.empatar);
    expect(ex2.end, ScriptEnd.etapa);
    final alt = ex2.question!.alternatives['e8f7']!;
    expect(alt.last.jump, isTrue);
    expect(alt.first.hasMove, isTrue);
  });

  test('exemplo sem pergunta e prática', () {
    final demo = script.stages[1].examples.single;
    expect(demo.question, isNull);
    final practice = script.stages[2].examples;
    expect(practice[0].isPractice, isTrue);
    expect(practice[0].practice!.limit, 40);
  });

  test('prática: fins opcionais por tipo de fim', () {
    Map<String, dynamic> json(Map<String, dynamic> extra) => {
      't': 'p.t',
      'maquina': 'b',
      ...extra,
    };
    final withEnds = PracticeSpec.fromJson(
      json({
        'fins': {'repeticao': 'p.fim.rep', 'limite': 'p.fim.lim'},
      }),
    );
    expect(withEnds.ends, {'repeticao': 'p.fim.rep', 'limite': 'p.fim.lim'});
    expect(PracticeSpec.fromJson(json({})).ends, isEmpty);
  });

  test('curiosidades: id e jogador em linha', () {
    final cur = script.stages[0].examples[0].curiosities!;
    expect(cur.quoteAuthor, 'Alguém');
    expect(cur.references[0].id, 'book1');
    final player = cur.references[1].inline!;
    expect(player.kind, 'player');
    expect(player.title, 'Ada Lovelace');
    expect(player.initials, 'AL');
    expect(player.url, 'https://x.y');
  });

  test('ScriptTexts devolve a chave quando falta o texto', () {
    const texts = ScriptTexts({'a': 'Olá'});
    expect(texts.say('a'), 'Olá');
    expect(texts.say('b'), 'b');
    expect(texts.has('a'), isTrue);
    expect(texts.has('b'), isFalse);
  });

  test('FreeEnd.meets: quem quer ganhar e quem quer empatar', () {
    expect(FreeEnd.coroa.meets(true), isTrue);
    expect(FreeEnd.coroa.meets(false), isFalse);
    expect(FreeEnd.capturado.meets(false), isTrue);
    expect(FreeEnd.afogado.meets(false), isTrue);
    expect(FreeEnd.afogado.meets(true), isFalse);
  });

  test('a referência de jogador usa o nome como título', () {
    expect(
      Reference(id: 'p', kind: 'player', fields: const {'name': 'X'}).title,
      'X',
    );
  });

  test('a parte da aula guarda o caminho do roteiro', () {
    final lesson = AssetLessonRepository.parseLesson({
      'id': 'pawns.test',
      'parts': [
        {'id': 'distant', 'roteiro': 'assets/x.json'},
        {'id': 'old', 'steps': <dynamic>[]},
      ],
    });
    expect(lesson.parts[0].script, 'assets/x.json');
    expect(lesson.parts[0].steps, isEmpty);
    expect(lesson.parts[1].script, isNull);
  });
}
