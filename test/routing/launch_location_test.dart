import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/routing/launch_location.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/routing/routes.dart';

import '../../testing/fakes/fake_endgame_repositories.dart';

/// P1 (T71): o app que reabre numa lição de final vai para a parte do
/// checkpoint; a parte com roteiro, para a tela de roteiro (sem a tela em
/// branco).
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lessons = FakeEndgameLessonRepository(
    trail: EndgameTrail(
      modules: [
        EndgameModule(
          id: 'rook',
          lessons: [
            EndgameLesson(
              id: 'rook.lucena',
              module: 'rook',
              lesson: Lesson.parted(
                id: 'rook.lucena',
                parts: const [
                  LessonPart(
                    id: 'bridge',
                    steps: [TalkStep(id: 'end', fen: fen)],
                  ),
                  LessonPart(id: 'roteiro', steps: [], script: 'r.json'),
                ],
              ),
              exercises: const [],
              passScore: 0,
              keyPositions: const [],
              practice: const Practice(fen: fen, goal: PositionGoal.win),
            ),
          ],
        ),
      ],
    ),
  );

  /// Onde o app abre de fato: o lugar inicial e o redirect da lição.
  Future<String> landing(String location) async {
    final uri = Uri.parse(location);
    final match = RegExp(r'^/endgames/([^/]+)/lesson$').firstMatch(uri.path);
    if (match == null) return location;
    return await scriptPartRedirect(
          lessons,
          match.group(1)!,
          uri.queryParameters['part'],
        ) ??
        location;
  }

  EndgameProgress ongoing(String? part, {bool open = true}) => EndgameProgress(
    ongoing: LessonCheckpoint(
      lessonId: 'rook.lucena',
      part: part,
      step: 0,
      open: open,
    ),
  );

  test('checkpoint do roteiro reabre na tela de roteiro da parte', () async {
    final location = launchLocation(endgames: ongoing('roteiro'));
    expect(location, Routes.endgameLessonSteps('rook.lucena', part: 'roteiro'));
    expect(
      await landing(location),
      Routes.endgameLessonScript('rook.lucena', part: 'roteiro'),
    );
  });

  test('checkpoint de parte comum reabre na lição dessa parte', () async {
    final location = launchLocation(endgames: ongoing('bridge'));
    expect(await landing(location), location);
    expect(Uri.parse(location).queryParameters['part'], 'bridge');
  });

  test('checkpoint antigo (sem parte) reabre na lição', () async {
    final location = launchLocation(endgames: ongoing(null));
    expect(location, Routes.endgameLessonSteps('rook.lucena'));
    expect(await landing(location), location);
  });

  test('saiu pela seta: o app abre no início', () {
    expect(
      launchLocation(endgames: ongoing('roteiro', open: false)),
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
      launchLocation(school: school, endgames: ongoing('roteiro')),
      Routes.lesson('pieces.rook'),
    );
  });

  test('o app e o router usam estas funções', () {
    final main = io.File('lib/main.dart').readAsStringSync();
    final router = io.File('lib/routing/router.dart').readAsStringSync();
    expect(main, contains('initialLocation: launchLocation('));
    expect(
      RegExp(r"path: 'lesson',[\s\S]{0,200}scriptPartRedirect\(")
          .hasMatch(router),
      isTrue,
    );
  });
}
