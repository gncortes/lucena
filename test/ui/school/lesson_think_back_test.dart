import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

void main() {
  testWidgets('pensar errado, Voltar: o painel volta ao objetivo, sem a '
      'solução', (tester) async {
    final real = AssetLessonRepository.parseLesson(
      jsonDecode(
        io.File('assets/lessons/endgames/pawns.distantOpposition.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final texts = LessonTexts.fromJson(
      jsonDecode(
        io.File('assets/lessons/en/endgames/pawns.distantOpposition.json')
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
    await cubit.load('pawns.distantOpposition', 'en', part: 'distant');
    await tester.runAsync(() async {
      await cubit.load('pawns.distantOpposition', 'en', part: 'distant');
      await cubit.play(Move.parse('d3e3')!);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    expect(cubit.state.step, 1);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LessonKeys.backButton));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(cubit.state.step, 0);
    expect(cubit.state.explanation, isNotNull);
    expect(cubit.state.interactive, isTrue);
    // O painel é o objetivo; nunca a solução nem "a ideia principal".
    final blocks = cubit.state.explanation?.explanations ?? const [];
    expect(blocks.where((b) => b.kind != ExplanationKind.context), isEmpty);
    expect(find.textContaining('preserves the win'), findsNothing);
    expect(find.textContaining('The main idea'), findsNothing);
    expect(cubit.state.speech ?? '', isNot(contains('preserves the win')));
  });
}
