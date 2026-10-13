import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

/// T65 §8 com as aulas de verdade: a decisão A/B mede tudo o que a folha
/// mostra (cabeçalho, contexto e objetivo), não só a frase do objetivo.
void main() {
  Future<LessonCubit> open(WidgetTester tester, String part, Size size) async {
    final real = AssetLessonRepository.parseLesson(
      jsonDecode(
        io.File('assets/lessons/endgames/pawns.distantOpposition.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final texts = LessonTexts.fromJson(
      jsonDecode(
        io.File('assets/lessons/pt/endgames/pawns.distantOpposition.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(
        course: Course(
          modules: [
            CourseModule(id: 'pawns', lessons: [real]),
          ],
        ),
        texts: texts,
      ),
      progress: FakeSchoolProgressRepository(),
      feedback: AssetExerciseFeedbackRepository(_Assets()),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await tester.runAsync(
      () => cubit.load('pawns.distantOpposition', 'pt', part: part),
    );
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return cubit;
  }

  for (final part in ['lateral', 'diagonal']) {
    testWidgets('Oposição $part em 360×640: caso B, com a folha e o X', (
      tester,
    ) async {
      final cubit = await open(tester, part, const Size(360, 640));
      expect(cubit.state.presenting, isTrue);
      expect(find.byKey(LessonKeys.closeSheet), findsOneWidget);
      await tester.tap(find.byKey(LessonKeys.closeSheet));
      await tester.pumpAndSettle();
      expect(cubit.state.presenting, isFalse);
    });
  }

  testWidgets('Na defesa em 412×917: B ou A sem nada cortado sob o rodapé', (
    tester,
  ) async {
    final cubit = await open(tester, 'defend', const Size(412, 917));
    if (cubit.state.presenting) {
      expect(find.byKey(LessonKeys.closeSheet), findsOneWidget);
    } else {
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(LessonKeys.scroll),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.maxScrollExtent, lessThanOrEqualTo(1));
    }
    expect(tester.takeException(), isNull);
  });
}
