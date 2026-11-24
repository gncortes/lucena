import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/glossary/glossary_repository.dart';
import 'package:lucena/data/repositories/lesson_video/lesson_video_repository.dart';
import 'package:lucena/data/repositories/lesson_video/video_interruptions_repository.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/lesson_video_converter.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/video_timeline.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/lesson_video_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/fakes/fake_glossary.dart';
import '../../testing/fakes/fake_kpk_repository.dart';
import '../../testing/fakes/fake_lesson_script_repository.dart';
import '../../testing/fakes/fake_lesson_source.dart';
import '../../testing/fakes/fake_lesson_video_repository.dart';
import '../../testing/fakes/fake_now.dart';
import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../testing/fakes/fake_voice_repository.dart';
import '../../testing/script_fixture.dart';
import '../../testing/test_app.dart';

/// Entradas E1–E12 de `docs/fluxos/aula-video.md` (tabela de entradas, um
/// teste por linha): a lição de verdade (`LessonScriptScreen` com o cubit
/// real e as etapas em vídeo padrão, L6) dentro de um roteador com a origem
/// e o Glossário. Sem dart-define: a aula em vídeo é a Teoria e a
/// Demonstração de toda lição.
void main() {
  group('aula em vídeo: entradas', () {
    testWidgets('E1: lição nunca feita → Teoria em vídeo tocando', (
      tester,
    ) async {
      final rig = await _Rig.open(tester);
      expect(find.byKey(LessonVideoKeys.screen), findsOneWidget);
      expect(find.byKey(LessonScriptKeys.screen), findsNothing);
      expect(rig.video(tester).stage, 'ideia');
      expect(rig.video(tester).state.playing, isTrue);
      expect(rig.source.checkpoints.last.step, 0);
      expect(rig.source.checkpoints.last.stepId, endsWith('/video'));
      await rig.dispose(tester);
    });

    testWidgets('E2: progresso salvo → pausada com o aviso de retomada', (
      tester,
    ) async {
      final rig = await _Rig.open(tester);
      final video = rig.video(tester);
      video.seek(video.state.total ~/ 3);
      video.pause();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(LessonScriptKeys.close));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('origem'), findsOneWidget);

      final again = await _Rig.open(
        tester,
        source: rig.source,
        videos: rig.videos,
      );
      expect(again.video(tester).stage, 'ideia');
      expect(again.video(tester).state.notice, isTrue);
      expect(again.video(tester).state.playing, isFalse);
      await again.dispose(tester);
    });

    testWidgets('E3: lição concluída → Teoria em 0:00, pausada', (
      tester,
    ) async {
      final source = FakeLessonSource()
        ..fresh = false
        ..done = (lesson: true, part: true);
      final rig = await _Rig.open(tester, source: source);
      final video = rig.video(tester);
      expect(video.stage, 'ideia');
      expect(video.state.position, Duration.zero);
      expect(video.state.playing, isFalse);
      await rig.dispose(tester);
    });

    testWidgets('E4: reabrir depois de fechar à força no meio → = E2', (
      tester,
    ) async {
      final rig = await _Rig.open(tester);
      final video = rig.video(tester);
      video.seek(video.state.total ~/ 2);
      video.pause();
      await tester.pump(const Duration(milliseconds: 300));
      // Fechar à força: a árvore some sem passar pela seta de voltar.
      await rig.dispose(tester);

      final again = await _Rig.open(
        tester,
        source: rig.source,
        videos: rig.videos,
      );
      expect(again.video(tester).stage, 'ideia');
      expect(again.video(tester).state.notice, isTrue);
      expect(again.video(tester).state.playing, isFalse);
      await again.dispose(tester);
    });

    testWidgets('E5: origem do Treino (fonte da Escola) → abre como E1', (
      tester,
    ) async {
      // O fim que volta às metas é do LessonScriptCubit, que o L6 não muda
      // (coberto em training_lesson_origin_test).
      final rig = await _Rig.open(
        tester,
        source: FakeLessonSource(endgame: false),
      );
      expect(rig.video(tester).stage, 'ideia');
      expect(rig.video(tester).state.playing, isTrue);
      await rig.dispose(tester);
    });

    testWidgets('E6: livro no topo → Glossário, vídeo pausado', (tester) async {
      final rig = await _Rig.open(tester);
      await tester.tap(find.byKey(LessonVideoKeys.glossaryButton));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('glossário'), findsOneWidget);
      expect(rig.videoCubit!.state.playing, isFalse);
      await rig.dispose(tester);
    });

    testWidgets('E7: termo sublinhado → Glossário filtrado', (tester) async {
      // L5: o roteiro de teste não tem termo do Glossário na fala da
      // Teoria; o toque no termo é coberto em lesson_video_screen_test.
    }, skip: true);

    testWidgets('E8: voltar do Glossário → mesmo instante, volta a tocar', (
      tester,
    ) async {
      final rig = await _Rig.open(tester);
      final video = rig.video(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(LessonVideoKeys.glossaryButton));
      await tester.pump(const Duration(milliseconds: 500));
      final at = video.state.position;
      rig.router.pop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(LessonVideoKeys.screen), findsOneWidget);
      expect(identical(rig.video(tester), video), isTrue);
      expect(video.state.position >= at, isTrue);
      expect(video.state.playing, isTrue);
      await rig.dispose(tester);
    });

    testWidgets('E9: "Próxima etapa" no fim da Teoria → Demonstração em 0:00, '
        'tocando', (tester) async {
      final rig = await _Rig.open(tester, videos: _theoryAnswered());
      await _toEnd(tester, rig);
      await tester.tap(find.byKey(LessonVideoKeys.endNext));
      await tester.pump(const Duration(milliseconds: 300));
      final demo = rig.video(tester);
      expect(demo.stage, 'demos');
      expect(demo.state.position < const Duration(seconds: 1), isTrue);
      expect(demo.state.playing, isTrue);
      expect(rig.script.state.stageId, 'demos');
      await rig.dispose(tester);
    });

    testWidgets('E10: "Próxima etapa" no fim da Demonstração → Prática', (
      tester,
    ) async {
      final source = FakeLessonSource();
      final rig = await _Rig.open(tester, source: source, stage: 1);
      expect(rig.video(tester).stage, 'demos');
      await _toEnd(tester, rig);
      await tester.tap(find.byKey(LessonVideoKeys.endNext));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(LessonVideoKeys.screen), findsNothing);
      expect(find.byKey(LessonScriptKeys.screen), findsOneWidget);
      expect(rig.script.state.stageId, 'pratica');
      expect(rig.script.state.phase, ScriptPhase.praticaVez);
      expect(rig.script.state.speech, ['p.t']);
      await rig.dispose(tester);
    });

    test('E11: fim da Prática → fim da lição', () {
      // O fim da lição não muda no L6: lesson_end_steps_route_test.
    }, skip: 'coberto por lesson_end_steps_route_test (sem mudança no L6)');

    testWidgets('E12: seta voltar no vídeo → origem, etapa salva', (
      tester,
    ) async {
      final rig = await _Rig.open(tester, stage: 1);
      await tester.tap(find.byKey(LessonScriptKeys.close));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('origem'), findsOneWidget);
      expect(rig.source.checkpoints.last.step, 1);
      expect(rig.source.checkpoints.last.stepId, endsWith('/video'));
      await rig.dispose(tester);
    });
  });
}

/// Leva o vídeo da etapa da vez ao fim (rodapé "Próxima etapa").
Future<void> _toEnd(WidgetTester tester, _Rig rig) async {
  final video = rig.video(tester);
  video.seek(video.state.total);
  await tester.pump(const Duration(milliseconds: 300));
  expect(video.state.ended, isTrue);
}

/// A Teoria com todas as perguntas já respondidas: dá para ir ao fim.
FakeLessonVideoRepository _theoryAnswered() {
  final timeline = VideoTimeline.layout(
    LessonVideoConverter.convert(
      scriptFixture(),
      ScriptTexts(scriptTexts()),
      language: 'pt',
    ).stage('ideia').lines,
    pace: VideoPace.reading,
  );
  return FakeLessonVideoRepository(
    progress: {
      'pawns.test.distant.ideia': VideoProgress(
        line: timeline.lines.first.line.id,
        resolved: {
          for (final g in timeline.gates) timeline.lines[g.line].line.id,
        },
      ),
    },
  );
}

class _Rig {
  _Rig._(this.router, this.source, this.videos, this.script);

  final GoRouter router;
  final FakeLessonSource source;
  final FakeLessonVideoRepository videos;
  final LessonScriptCubit script;

  /// O cubit do vídeo na tela agora (o último visto, se a tela saiu).
  LessonVideoCubit? videoCubit;

  LessonVideoCubit video(WidgetTester tester) => videoCubit = tester
      .element(find.byKey(LessonVideoKeys.screen))
      .read<LessonVideoCubit>();

  static Future<_Rig> open(
    WidgetTester tester, {
    FakeLessonSource? source,
    FakeLessonVideoRepository? videos,
    int stage = 0,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final lessonSource = source ?? FakeLessonSource();
    final videoRepo = videos ?? FakeLessonVideoRepository();
    final scripts = FakeLessonScriptRepository(scriptFixture(), scriptTexts());
    final speech = SpeechCubit(
      FakeVoiceRepository(settings: const VoiceSettings(enabled: false)),
    );
    addTearDown(speech.close);
    await speech.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final cubit = LessonScriptCubit(
      lessonId: 'pawns.test',
      partId: 'distant',
      scriptPath: 'roteiro.json',
      language: 'pt',
      scripts: scripts,
      kpk: FakeKpkRepository(FakeKpkOracle()),
      source: lessonSource,
      initialStage: stage,
      delay: (_) async {},
    );
    addTearDown(() {
      if (!cubit.isClosed) return cubit.close();
    });
    final router = GoRouter(
      initialLocation: '/script',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('origem')),
          routes: [
            GoRoute(
              path: 'script',
              builder: (_, _) => BlocProvider.value(
                value: cubit,
                child: LessonScriptScreen(
                  title: Future.value('Oposição distante'),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: Routes.glossary,
          builder: (_, _) => const Scaffold(body: Text('glossário')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<LessonScriptRepository>.value(value: scripts),
          RepositoryProvider<LessonVideoRepository>.value(value: videoRepo),
          RepositoryProvider<VideoInterruptionsRepository>.value(
            value: FakeVideoInterruptionsRepository(),
          ),
          RepositoryProvider<Now>.value(
            value: FakeNow(DateTime(2026, 11, 24, 10)),
          ),
          RepositoryProvider<GlossaryRepository>.value(
            value: FakeGlossaryRepository(),
          ),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          speechCubit: speech,
          router: router,
          child: const SizedBox(),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final rig = _Rig._(router, lessonSource, videoRepo, cubit);
    if (find.byKey(LessonVideoKeys.screen).evaluate().isNotEmpty) {
      rig.video(tester);
    }
    return rig;
  }

  /// Desmonta a árvore (fecha os cubits do vídeo e os timers).
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }
}
