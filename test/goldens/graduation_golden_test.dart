import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_finished.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/goldens/golden_harness.dart';
import '../../testing/test_app.dart';

/// Os módulos de verdade da escola, do curso.
List<CourseModule> _path() {
  final course = jsonDecode(
    File('assets/lessons/course.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return [
    for (final module in course['modules'] as List)
      CourseModule(
        id: module['id'] as String,
        lessons: [
          for (final lesson in module['lessons'] as List)
            Lesson(id: lesson['id'] as String, steps: const []),
        ],
      ),
  ];
}

/// Os textos das aulas no idioma [language] (pt ou en).
LessonTexts _texts(String language) {
  final raw = jsonDecode(
    File('assets/lessons/$language/lessons.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return LessonTexts({
    for (final MapEntry(:key, :value) in raw.entries)
      key: value is List ? value.cast<String>() : [value as String],
  });
}

LessonState _state({required bool arabic}) => LessonState(
  ready: true,
  finished: true,
  courseFinished: true,
  finishedAt: DateTime.utc(2026, 10, 8),
  lesson: const Lesson(id: 'graduation.twoBishops', steps: []),
  viktor: FakeCharacterRepository.viktor,
  texts: _texts(arabic ? 'en' : 'pt'),
  graduationPath: _path(),
  speech: arabic
      ? 'تخرّجت! الآن اصعد الرحلة.'
      : 'Formado! Agora suba a Jornada e mostre o que aprendeu.',
  lessonNumber: 39,
  lessonCount: 39,
);

void main() {
  Goldens.matrix(
    'graduation',
    (variant) => SizedBox(
      height: 760,
      child: LessonFinished(state: _state(arabic: variant.arabic)),
    ),
    height: 800,
  );

  // A imagem que vai para as redes: o cartão inteiro, sem a tela em volta.
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('graduation_share · ${theme.name}', (tester) async {
      await Goldens.loadFonts();
      const size = Size(412, 2000);
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          themeMode: theme,
          child: MediaQuery(
            data: const MediaQueryData(size: size, disableAnimations: true),
            child: Scaffold(body: LessonFinished(state: _state(arabic: false))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(SchoolKeys.graduationCard),
        matchesGoldenFile('goldens/graduation_share/${theme.name}.png'),
      );
    });
  }
}
