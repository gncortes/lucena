import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// O passo com `ref` para uma partida com `url` mostra, junto da fala do
/// Viktor, o link para vê-la no Lichess; no passo de pensar, só depois do
/// tempo. Sem `ref`, ou referência sem `url`, nada.
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  const url = 'https://lichess.org/analysis/pgn/1.e4#1';
  EndgameTrail trailWith(Lesson lesson) => EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: lesson,
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
            references: const [
              Reference(
                id: 'g1',
                kind: 'game',
                fields: {'white': 'A', 'black': 'B', 'url': url},
              ),
              Reference(
                id: 's1',
                kind: 'study',
                fields: {'title': 'S', 'url': 'https://lichess.org/study/abc'},
              ),
              Reference(id: 'b1', kind: 'book', fields: {'title': 'Livro'}),
            ],
          ),
        ],
      ),
    ],
  );

  LessonCubit cubitWith(Lesson lesson, FakeNow now) => LessonCubit(
    source: EndgameLessonSource(
      FakeEndgameLessonRepository(
        trail: trailWith(lesson),
        texts: LessonTexts.fromJson({
          'rook.lucena.think': 'What is the plan?',
          'rook.lucena.game': 'From a real game.',
          'rook.lucena.study': 'From a study.',
          'rook.lucena.book': 'From a book.',
          'rook.lucena.plain': 'Our own.',
        }),
      ),
      FakeEndgameProgressRepository(),
    ),
    characters: FakeCharacterRepository(),
    opponent: FakeOpponentRepository(),
    now: now,
    replyDelay: Duration.zero,
  );

  test('no passo de pensar, o link só vem depois do tempo', () async {
    final now = FakeNow(DateTime.utc(2026, 10, 9, 20));
    final cubit = cubitWith(
      Lesson.parted(
        id: 'rook.lucena',
        parts: const [
          LessonPart(
            id: 'bridge',
            steps: [
              ThinkStep(id: 'think', fen: fen, minutes: 1, ref: 'g1'),
              TalkStep(id: 'plain', fen: fen),
            ],
          ),
        ],
      ),
      now,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    expect(cubit.state.thinking, isTrue);
    expect(cubit.state.link, isNull);
    now.advance(const Duration(minutes: 2));
    await cubit.tick();
    expect(cubit.state.thinking, isFalse);
    expect(cubit.state.link?.url, url);
  });

  testWidgets('link da partida e do estudo junto da fala; sem url ou sem '
      'ref, nada', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final cubit = cubitWith(
      Lesson.parted(
        id: 'rook.lucena',
        parts: const [
          LessonPart(
            id: 'bridge',
            steps: [
              TalkStep(id: 'game', fen: fen, ref: 'g1'),
              TalkStep(id: 'study', fen: fen, ref: 's1'),
              TalkStep(id: 'book', fen: fen, ref: 'b1'),
              TalkStep(id: 'plain', fen: fen),
            ],
          ),
        ],
      ),
      FakeNow(DateTime.utc(2026, 10, 9, 20)),
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(thinkChosen: true)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('en'),
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final link = find.byKey(LessonKeys.referenceLink);
    expect(link, findsOneWidget);
    expect(
      find.descendant(
        of: link,
        matching: find.text('View the game on Lichess'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: link, matching: find.byIcon(Icons.open_in_new)),
      findsOneWidget,
    );

    Future<void> nextStep(String id) async {
      await cubit.next();
      await tester.pump(const Duration(milliseconds: 500));
      expect(cubit.state.current?.id, id);
    }

    await nextStep('study');
    expect(
      find.descendant(of: link, matching: find.text('View the study')),
      findsOneWidget,
    );

    // Referência sem url: sem link.
    await nextStep('book');
    expect(link, findsNothing);

    // Passo sem ref: sem link.
    await nextStep('plain');
    expect(link, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
