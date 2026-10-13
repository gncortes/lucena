import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      () => cubit.load(
        'pawns.distantOpposition',
        'pt',
        part: part.isEmpty ? null : part,
      ),
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
      expect(find.byKey(LessonKeys.presentationClose), findsOneWidget);
      await tester.tap(find.byKey(LessonKeys.presentationClose));
      await tester.pumpAndSettle();
      expect(cubit.state.presenting, isFalse);
    });
  }

  testWidgets('Na defesa em 412×917: B ou A sem nada cortado sob o rodapé', (
    tester,
  ) async {
    final cubit = await open(tester, 'defend', const Size(412, 917));
    if (cubit.state.presenting) {
      expect(find.byKey(LessonKeys.presentationClose), findsOneWidget);
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

  testWidgets('B: a folha sobe até o fim do texto, sem vão vazio embaixo', (
    tester,
  ) async {
    for (final (part, size) in [
      ('defend', const Size(412, 917)),
      ('lateral', const Size(360, 640)),
    ]) {
      final cubit = await open(tester, part, size);
      if (!cubit.state.presenting) continue;
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      if (!cubit.state.presenting) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      final sheet = tester.getRect(find.byKey(LessonKeys.scroll));
      final lowest = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(LessonKeys.scroll),
              matching: find.byType(Text),
            ),
          )
          .map((text) => tester.getRect(find.byWidget(text)).bottom)
          .reduce((a, b) => a > b ? a : b);
      expect(
        sheet.bottom - lowest,
        lessThan(48),
        reason: '$part: fim do texto junto do fim da folha',
      );
      expect(sheet.top, greaterThanOrEqualTo(76));
    }
  });

  testWidgets('360x640 recolhido: 3 linhas do enunciado inteiras, sem corte', (
    tester,
  ) async {
    final cubit = await open(tester, 'defend', const Size(360, 640));
    if (cubit.state.presenting) {
      await tester.tap(find.byKey(LessonKeys.presentationClose));
      await tester.pumpAndSettle();
    }
    final speech = find.descendant(
      of: find.byKey(LessonKeys.speech),
      matching: find.byType(RichText),
    );
    final paragraph = tester.renderObject<RenderParagraph>(speech.first);
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first;
    final line = box.bottom - box.top;
    final text = tester.getRect(speech.first);
    // O que fica visível: da folha até o rodapé, menos o respiro de 12 dp e o
    // esmaecer de 12 dp (o texto precisa terminar antes do esmaecer).
    final footerTop = tester.getRect(find.byKey(LessonKeys.footer)).top;
    final clearBottom = footerTop - 12 - 12;
    final visibleLines = ((clearBottom - text.top) / line).floor();
    expect(visibleLines, greaterThanOrEqualTo(3));
    // E o card (9 dp abaixo da terceira linha) também termina antes do fade.
    expect(text.top + 3 * line + 9, lessThanOrEqualTo(clearBottom));
    expect(tester.takeException(), isNull);
  });
}
