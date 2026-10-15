import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

/// O fim da última parte (T72, canvas c4380df): "Fazer o teste final" (3
/// palavras) empilha sobre "Revisar", sem ícone. Entre as partes não há tela
/// de fim (crit. 18): o lado a lado fica no teste do `ActionsFooter`.
void main() {
  const id = 'test.parts';
  const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
  final course = Course(
    modules: [
      CourseModule(
        id: 'test',
        lessons: [
          Lesson.parted(
            id: id,
            parts: const [
              LessonPart(
                id: 'p1',
                steps: [TalkStep(id: 'a', fen: fen)],
              ),
              LessonPart(
                id: 'p2',
                steps: [TalkStep(id: 'b', fen: fen)],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  const texts = LessonTexts({
    'test.parts.title': ['Oposição'],
    'test.parts.a': ['Primeira ideia.'],
    'test.parts.b': ['Segunda ideia.'],
    'test.parts.part.p1.title': ['A oposição direta'],
    'test.parts.part.p1.summary': [
      'Os reis frente a frente com uma casa entre eles: quem não tem a vez '
          'ganha a oposição.',
    ],
    'test.parts.part.p2.title': ['A oposição distante'],
    'test.parts.part.p2.summary': [
      'Com três ou cinco casas entre os reis, a oposição vale do mesmo jeito.',
    ],
  });

  // Prints com sombra real: --dart-define=PRINT=<pasta> --update-goldens.
  const print = String.fromEnvironment('PRINT');

  Future<void> finish(WidgetTester tester, Size size, String part) async {
    await Goldens.loadFonts();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: _Source(
        course.modules.single.lessons.single,
        texts,
        const LessonOutcome(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
      holdDelay: Duration.zero,
      typingDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load(id, 'pt', part: part);
    await cubit.next();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonKeys.finished), findsOneWidget);
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (print.isEmpty) return;
    debugDisableShadows = false;
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate().toList()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LessonScreen),
      matchesGoldenFile('$print/$name.png'),
    );
    debugDisableShadows = true;
  }

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    final w = size.width.toInt();
    testWidgets('$w: último capítulo, Fazer o teste final em cima, sem ícone', (
      tester,
    ) async {
      await finish(tester, size, 'p2');
      final test = tester.getRect(find.byKey(LessonKeys.nextPartButton));
      final review = tester.getRect(find.byKey(LessonKeys.reviewPartButton));
      expect(find.text('Fazer o teste final'), findsOneWidget);
      expect(test.width, size.width - 32);
      expect(review.top - test.bottom, 8);
      expect(
        find.descendant(
          of: find.byKey(LessonKeys.nextPartButton),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      await snap(tester, 'capitulo_ultimo_$w');
    });
  }
}

/// A lição em partes, com a próxima parte que o fim de capítulo mostra.
class _Source extends FakeLessonSource {
  _Source(this._lesson, this._texts, LessonOutcome outcome)
    : super(outcome: outcome);

  final Lesson _lesson;
  final LessonTexts _texts;

  @override
  Future<Lesson?> lesson(String id) async => _lesson;

  @override
  Future<LessonTexts> texts(String language) async => _texts;
}
