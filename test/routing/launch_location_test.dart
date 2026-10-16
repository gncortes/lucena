import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/routing/launch_location.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/routing/routes.dart';

import '../../testing/fakes/fake_endgame_repositories.dart';

/// A retomada de uma aula de final: o app que reabre vai para a parte do
/// checkpoint; só abre parte com roteiro novo. Parte que não aparece mais
/// (capítulo sem roteiro) cai no início da primeira parte, nunca numa tela
/// antiga.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;

  EndgameLesson lesson(String id, List<LessonPart> parts) => EndgameLesson(
    id: id,
    module: 'rook',
    lesson: Lesson.parted(id: id, parts: parts),
    exercises: const [],
    passScore: 0,
    keyPositions: const [],
    practice: const Practice(fen: fen, goal: PositionGoal.win),
  );

  // A aula toda salva (como nos assets): a Oposição com capítulos antigos
  // sem roteiro ao lado do `distant`, que tem.
  final all = FakeEndgameLessonRepository(
    trail: EndgameTrail(
      modules: [
        EndgameModule(
          id: 'rook',
          lessons: [
            lesson('pawns.opposition', const [
              LessonPart(id: 'distant', steps: [], script: 'r.json'),
              LessonPart(
                id: 'diagonal',
                steps: [TalkStep(id: 'd', fen: fen)],
              ),
              LessonPart(
                id: 'wrapUp',
                steps: [TalkStep(id: 'w', fen: fen)],
              ),
            ]),
            lesson('pawns.old', const [
              LessonPart(
                id: 'a',
                steps: [TalkStep(id: 'a', fen: fen)],
              ),
            ]),
          ],
        ),
      ],
    ),
  );
  final ids = {'pawns.opposition', 'pawns.old'};
  final visible = VisibleEndgameLessonRepository(all, ids: ids);

  EndgameProgress ongoing(String? part, {bool open = true}) => EndgameProgress(
    ongoing: LessonCheckpoint(
      lessonId: 'pawns.opposition',
      part: part,
      step: 3,
      open: open,
    ),
  );

  final start = Routes.endgameLessonScript('pawns.opposition', part: 'distant');

  /// Onde o app abre de fato: o lugar inicial e o redirect da rota de roteiro.
  Future<String> landing(String location) async {
    final uri = Uri.parse(location);
    final match = RegExp(r'^/endgames/([^/]+)/roteiro$').firstMatch(uri.path);
    if (match == null) return location;
    return await resolveScriptPart(
          visible,
          match.group(1)!,
          uri.queryParameters['part'],
        ) ??
        location;
  }

  group('visibilidade por roteiro (VisibleLessons)', () {
    test('a aula fica só com os capítulos que têm roteiro', () async {
      final trail = await visible.trail();
      final opposition = trail.lesson('pawns.opposition')!;
      expect([for (final p in opposition.lesson.parts) p.id], ['distant']);
      expect(opposition.lesson.part('diagonal'), isNull);
    });

    test('aula sem nenhum capítulo com roteiro sai da trilha', () async {
      final trail = await visible.trail();
      expect(trail.lesson('pawns.old'), isNull);
      expect([for (final l in trail.lessons) l.id], ['pawns.opposition']);
    });

    test('concluir o capítulo que resta conclui a aula', () async {
      final trail = await visible.trail();
      final opposition = trail.lesson('pawns.opposition')!;
      const done = EndgameLessonProgress(parts: {'distant'});
      expect(done.partsDone(opposition), {'distant'});
    });

    test('o ponto único de decisão', () {
      expect(
        VisibleLessons.partVisible(const LessonPart(id: 'x', steps: [])),
        isFalse,
      );
      expect(
        VisibleLessons.partVisible(
          const LessonPart(id: 'x', steps: [], script: 'r.json'),
        ),
        isTrue,
      );
    });
  });

  group('retomada', () {
    test('capítulo com roteiro reabre nele', () async {
      final location = launchLocation(endgames: ongoing('distant'));
      expect(await landing(location), location);
      expect(Uri.parse(location).queryParameters['part'], 'distant');
    });

    test('capítulo antigo (sem roteiro) ou sem parte cai no início', () async {
      for (final part in <String?>['diagonal', 'wrapUp', 'sumiu', null]) {
        final location = launchLocation(endgames: ongoing(part));
        expect(await landing(location), start, reason: '$part');
      }
    });

    test('a aula sem capítulo visível não redireciona', () async {
      expect(await resolveScriptPart(visible, 'pawns.old', 'a'), isNull);
    });
  });

  test('saiu pela seta: o app abre no início', () {
    expect(
      launchLocation(endgames: ongoing('distant', open: false)),
      Routes.home,
    );
  });

  test('a ordem: conclusão, partida, escola, final', () {
    const school = SchoolProgress(
      ongoing: LessonCheckpoint(lessonId: 'pieces.rook', step: 0),
    );
    expect(
      launchLocation(conclusion: 7, resumeGame: true, school: school),
      Routes.conclusion(7),
    );
    expect(launchLocation(resumeGame: true, school: school), Routes.freeBoard);
    expect(
      launchLocation(school: school, endgames: ongoing('distant')),
      Routes.lessonScript('pieces.rook'),
    );
  });

  test('aula escondida não reabre: a da Escola e a de final', () {
    const school = SchoolProgress(
      ongoing: LessonCheckpoint(lessonId: 'pieces.rook', step: 0),
    );
    expect(
      launchLocation(
        school: school,
        endgames: ongoing('distant'),
        showSchool: false,
        visibleEndgameLessons: {'pawns.other'},
      ),
      Routes.home,
    );
  });

  test('o app e o router usam estas funções', () {
    final main = io.File('lib/main.dart').readAsStringSync();
    final router = io.File('lib/routing/router.dart').readAsStringSync();
    expect(main, contains('initialLocation: launchLocation('));
    expect(main, contains('visibleEndgameLessons: VisibleLessons.'));
    expect(
      RegExp(r"path: 'roteiro',[\s\S]{0,400}resolveScriptPart\(")
          .hasMatch(router),
      isTrue,
    );
  });
}
