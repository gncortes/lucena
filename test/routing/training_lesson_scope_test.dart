import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/training/training_endgame_content.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/routing/training_lesson_scope.dart';

import '../../testing/fakes/fake_endgame_repositories.dart';
import '../../testing/fakes/fake_school_repositories.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) async {
    if (path.endsWith('/index.json')) {
      return jsonEncode({
        'partes': [
          {
            'id': 'p1',
            'capitulos': [
              {'id': 'private.c1'},
            ],
          },
        ],
      });
    }
    if (path.endsWith('private.c1.json')) {
      return jsonEncode({
        'id': 'private.c1',
        'module': 'p1',
        'parts': [
          {
            'id': 'topic',
            'roteiro': 'assets/lessons/roteiros/private.c1/topic.json',
            'steps': [],
          },
        ],
        'exercises': [],
        'passScore': 0,
        'practice': {'fen': '8/8/8/8/8/2K5/5k2/8 w - - 0 1'},
      });
    }
    return '{}';
  }
}

void main() {
  for (final id in <String?>[null, 'rook.lucena', 'private.c1']) {
    testWidgets('repository scope selects only the configured lesson: $id', (
      tester,
    ) async {
      final public = FakeEndgameLessonRepository();
      final private = TrainingEndgameContent(
        _Assets(),
        school: FakeLessonRepository(),
        indexes: {'private': 'assets/courses/private/index.json'},
      );
      late EndgameLessonRepository selected;
      late EndgameLessonRepository redirectSource;
      EndgameLessonRepository? noPrivateTests;
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<EndgameLessonRepository>.value(value: public),
            RepositoryProvider<TrainingEndgameContent?>.value(value: private),
          ],
          child: Builder(
            builder: (context) {
              redirectSource = trainingLessonRepository(context, id);
              noPrivateTests = trainingTestRepository(
                context,
                'assets/lessons/course.json',
              );
              return scopeTrainingLesson(context, id, (scoped) {
                selected = scoped.read<EndgameLessonRepository>();
                return const SizedBox();
              });
            },
          ),
        ),
      );
      expect(noPrivateTests, isNull);
      expect(identical(selected, public), id != 'private.c1');
      expect(identical(selected, redirectSource), isTrue);
      if (id == 'private.c1') {
        expect(
          await resolveScriptPart(redirectSource, id!, null),
          '/endgames/private.c1/roteiro?part=topic&etapa=0',
        );
      }
    });
  }

  testWidgets(
    'compositions without private DI retain their public/fake repository',
    (tester) async {
      final public = FakeEndgameLessonRepository();
      late EndgameLessonRepository selected;
      await tester.pumpWidget(
        RepositoryProvider<EndgameLessonRepository>.value(
          value: public,
          child: Builder(
            builder: (context) =>
                scopeTrainingLesson(context, 'private.c1', (scoped) {
                  selected = scoped.read<EndgameLessonRepository>();
                  expect(trainingTestRepository(scoped, 'index'), same(public));
                  return const SizedBox();
                }),
          ),
        ),
      );
      expect(selected, same(public));
    },
  );
}
