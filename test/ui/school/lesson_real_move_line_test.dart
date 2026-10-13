import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/explanation_keys.dart';
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
  testWidgets(
    'dados reais (rótulo A/B): o lance do aluno não vira linha solta',
    (tester) async {
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
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      final payload = cubit.state.explanation!;
      final roots = [
        for (final b in payload.explanations)
          for (final v in b.variations)
            if (v.parentId == null) v,
      ];
      expect(roots, isNotEmpty);
      expect(RegExp(r'^[A-Z]$').hasMatch(roots.first.label), isTrue);
      expect(
        find.byKey(ExplanationKeys.block(payload.explanations.first.id)),
        findsOneWidget,
      );
      // O lance já é link no parágrafo: nenhuma linha só com o lance.
      for (final v in roots) {
        expect(find.byKey(ExplanationKeys.variation(v.id)), findsNothing);
      }
    },
  );
}
