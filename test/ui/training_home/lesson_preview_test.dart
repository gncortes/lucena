import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/theme/app_motion.dart';
import 'package:lucena/ui/core/widgets/game_board_hero.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

class _DelayedScripts extends FakeLessonScriptRepository {
  _DelayedScripts(super.script, super.texts);
  final gate = Completer<void>();
  @override
  Future<LessonScript> script(String path) async {
    await gate.future;
    return super.script(path);
  }
}

void main() {
  for (final black in [false, true]) {
    for (final previewEnabled in [false, true]) {
      testWidgets('lesson $black preview=$previewEnabled before async script', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(412, 915)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: AppLanguage.selectable,
        );
        await settings.load();
        addTearDown(settings.close);
        final json = scriptJson();
        final first =
            ((json['etapas'] as List).first as Map)['exemplos'] as List;
        (first.first as Map)['vira'] = black;
        final script = LessonScript.fromJson(json);
        final example = script.stages.first.examples.first;
        final scripts = _DelayedScripts(script, scriptTexts(json));
        final source = FakeLessonSource();
        final cubit = LessonScriptCubit(
          lessonId: script.lessonId,
          partId: script.partId,
          scriptPath: 'script.json',
          language: 'pt',
          scripts: scripts,
          kpk: FakeKpkRepository(FakeKpkOracle()),
          source: source,
        );
        addTearDown(cubit.close);
        final preview = LessonScriptState(
          ready: true,
          fen: example.entry.first.fen,
          orientation: example.student,
          speech: [scriptTexts(json)[example.entry.first.t]!],
          primary: ScriptAction.continuar,
        );
        late GoRouter router;
        router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    PositionBoard(
                      fen: preview.fen,
                      size: 60,
                      orientation: preview.orientation,
                      heroTag: gameBoardTag(preview.orientation),
                    ),
                    TextButton(
                      onPressed: () {
                        unawaited(router.push('/guide'));
                        unawaited(router.push('/lesson'));
                      },
                      child: const Text('Abrir'),
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/guide',
              builder: (_, _) => const Scaffold(body: Text('Guia')),
            ),
            GoRoute(
              path: '/lesson',
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                transitionDuration: AppMotion.screen,
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
                child: BlocProvider.value(
                  value: cubit,
                  child: LessonScriptScreen(
                    title: Future.value('Aula real'),
                    preview: previewEnabled ? preview : null,
                    homeHero: previewEnabled,
                    previewTeacher: previewEnabled
                        ? FakeCharacterRepository.viktor
                        : null,
                    previewTitle: previewEnabled ? 'Aula real' : null,
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
            child: TestApp(
              settingsCubit: settings,
              locale: const Locale('pt'),
              router: router,
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir'));
        await tester.pump();
        await tester.pump();
        final arrival = find.byType(GameBoardHero);
        expect(arrival, previewEnabled ? findsOneWidget : findsNothing);
        expect(
          source.checkpoints,
          isEmpty,
          reason: 'Visual preview must not create operational progress',
        );
        Rect? previewRect;
        if (previewEnabled) {
          previewRect = tester.getRect(arrival);
          final hero = tester.widget<Hero>(
            find.descendant(of: arrival, matching: find.byType(Hero)),
          );
          expect(hero.tag, gameBoardTag(preview.orientation));
        } else {
          expect(find.byKey(LessonScriptKeys.board), findsNothing);
        }
        await tester.pump(AppMotion.screen);
        scripts.gate.complete();
        await tester.pumpAndSettle();
        expect(find.byKey(LessonScriptKeys.board), findsOneWidget);
        if (previewEnabled) {
          expect(tester.getRect(find.byType(GameBoardHero)), previewRect);
        } else {
          expect(find.byType(GameBoardHero), findsNothing);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
