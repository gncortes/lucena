import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

/// A folha do Viktor recolhida usa o espaço livre entre o tabuleiro e a
/// barra de controles (S21 FE, 360x780): mostra as linhas inteiras que
/// couberem, sem faixa vazia maior que uma linha.
void main() {
  const lessonId = 'pawns.distantOpposition';
  late EndgameLesson real;
  late LessonTexts texts;
  final boundary = GlobalKey();

  setUpAll(() async {
    final repo = AssetEndgameLessonRepository(
      _Assets(),
      school: AssetLessonRepository(_Assets()),
    );
    real = (await repo.trail()).lessons.firstWhere((l) => l.id == lessonId);
    texts = await repo.texts('pt');
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          trail: EndgameTrail(
            modules: [
              EndgameModule(id: real.module, lessons: [real]),
            ],
          ),
          texts: texts,
        ),
        FakeEndgameProgressRepository(),
      ),
      feedback: AssetExerciseFeedbackRepository(_Assets()),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load(lessonId, 'pt');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        locale: const Locale('pt'),
        child: RepaintBoundary(
          key: boundary,
          child: BlocProvider.value(value: cubit, child: const LessonScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Passa para o estado correto do passo de pensar ("Ver resposta").
  Future<void> hints(WidgetTester tester) async {
    unawaited(
      tester
          .element(find.byType(LessonScreen))
          .read<LessonCubit>()
          .showAnswer(),
    );
    await tester.pumpAndSettle();
  }

  /// A última linha de tinta de texto (escura) visível na folha e o vazio
  /// entre ela e o topo da barra de controles.
  Future<double> freeBelowText(WidgetTester tester) async {
    final bar = tester.getRect(find.byKey(LessonKeys.footer)).top;
    final top = tester.getRect(find.byKey(LessonKeys.scroll)).top;
    final image = (await tester.runAsync(() async {
      final object =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return object.toImage();
    }))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    var last = top;
    for (var y = top.ceil() + 56; y < bar.floor(); y++) {
      for (var x = 24; x < image.width - 24; x++) {
        final o = (y * image.width + x) * 4;
        final dark =
            bytes.getUint8(o) < 90 &&
            bytes.getUint8(o + 1) < 90 &&
            bytes.getUint8(o + 2) < 90;
        if (dark) {
          last = y + 1.0;
          break;
        }
      }
    }
    return bar - last;
  }

  for (final h in [720, 738, 762, 780]) {
    testWidgets('sem faixa vazia maior que uma linha em 360x$h', (
      tester,
    ) async {
      await pump(tester, Size(360, h.toDouble()));
      await hints(tester);
      final free = await freeBelowText(tester);
      expect(free, lessThan(24), reason: "altura $h");
    });
  }
}
