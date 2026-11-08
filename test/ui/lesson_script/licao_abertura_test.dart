import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';
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

class _InertTimer implements Timer {
  @override
  bool get isActive => false;

  @override
  int get tick => 0;

  @override
  void cancel() {}
}

/// H-LIC-29: os rótulos da aula de abertura (curso, fora da trilha
/// de finais) seguem o quadro PropV1TreinoAbIdeiaFim / AbModeloFim.
void main() {
  Future<LessonScriptCubit> open(
    WidgetTester tester, {
    required bool endgame,
    int stage = 0,
    Map<String, dynamic>? json,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final cubit = LessonScriptCubit(
      lessonId: 'opening.test',
      partId: 'p1',
      scriptPath: 'roteiro.json',
      language: 'pt',
      scripts: FakeLessonScriptRepository(
        json == null ? scriptFixture() : LessonScript.fromJson(json),
        scriptTexts(json),
      ),
      kpk: FakeKpkRepository(FakeKpkOracle()),
      source: FakeLessonSource(endgame: endgame),
      initialStage: stage,
      delay: (_) async {},
      timer: (_, _) => _InertTimer(),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: RepositoryProvider<CharacterRepository>.value(
          value: FakeCharacterRepository(),
          child: BlocProvider.value(
            value: cubit,
            child: LessonScriptScreen(
              title: Future.value('Caro-Kann'),
              onAnalyze: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    return cubit;
  }

  for (final endgame in [false, true]) {
    testWidgets('fim da ideia diz "Partidas-modelo" (finais: $endgame)', (
      tester,
    ) async {
      final cubit = await open(tester, endgame: endgame);
      for (
        var i = 0;
        i < 40 && cubit.state.primary != ScriptAction.proximaEtapa;
        i++
      ) {
        if (cubit.state.primary == null) break;
        await cubit.onAction(cubit.state.primary!);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(cubit.state.primary, ScriptAction.proximaEtapa);
      expect(cubit.state.stageId, 'ideia');
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.primary),
          matching: find.text('Partidas-modelo'),
        ),
        findsOneWidget,
      );
    });
  }

  for (final endgame in [false, true]) {
    testWidgets('fim da prática tem a lupa "Analisar" (finais: $endgame)', (
      tester,
    ) async {
      final json = scriptJson();
      final example =
          (((json['etapas'] as List)[2] as Map)['exemplos'] as List).first
              as Map;
      example['fen'] = '4k3/6P1/8/8/8/8/8/4K3 w - - 0 1';
      ((json['etapas'] as List)[2] as Map)['exemplos'] = [example];
      final cubit = await open(tester, endgame: endgame, stage: 2, json: json);
      await cubit.onMove('g7g8');
      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.phase, ScriptPhase.praticaFim);
      expect(find.byKey(LessonScriptKeys.lessonAnalyze), findsOneWidget);
      expect(find.byIcon(CanvasSymbols.search), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('fim da ideia da abertura não tem a lupa (quadro AbIdeiaFim)', (
    tester,
  ) async {
    final cubit = await open(tester, endgame: false);
    for (
      var i = 0;
      i < 40 && cubit.state.primary != ScriptAction.proximaEtapa;
      i++
    ) {
      if (cubit.state.primary == null) break;
      await cubit.onAction(cubit.state.primary!);
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(cubit.state.phase, ScriptPhase.fimEtapa);
    expect(find.byKey(LessonScriptKeys.lessonAnalyze), findsNothing);
  });
}
