import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

/// A prática do ataque da Oposição distante: Rf3, peão b3, Re8; as brancas
/// jogam (o caso do Gabriel).
const _start = '4k3/8/8/8/8/1P3K2/8/8 w - - 0 1';

Map<String, dynamic> _json() {
  final json = jsonDecode(
    io.File('assets/lessons/roteiros/pawns.distantOpposition/distant.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final stages = (json['etapas'] as List).cast<Map<String, dynamic>>();
  final practice = stages.firstWhere((s) => s['id'] == 'pratica');
  practice['exemplos'] = [
    for (final e in (practice['exemplos'] as List).cast<Map<String, dynamic>>())
      if (e['id'] == 'ataque') e,
  ];
  return {
    ...json,
    'etapas': [practice],
  };
}

Map<String, String> _texts() {
  final generic = jsonDecode(
    io.File('assets/lessons/pt/roteiro_generico.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final lesson = jsonDecode(
    io.File('assets/lessons/pt/endgames/pawns.distantOpposition.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final e in generic.entries) e.key: e.value as String,
    for (final e in lesson.entries)
      if (e.key.startsWith('rot.pratica.')) e.key: e.value as String,
  };
}

KpkTableOracle _oracle() =>
    KpkTableOracle(io.File('assets/tablebase/kpk.bin').readAsBytesSync());

/// Uma lista de esperas que o teste solta uma a uma.
class _Waits {
  final pending = <Completer<void>>[];

  Future<void> call(Duration duration) {
    if (duration != LessonScriptCubit.refuteDelay) return Future.value();
    final wait = Completer<void>();
    pending.add(wait);
    return wait.future;
  }

  Future<void> release() async {
    pending.removeAt(0).complete();
    await Future<void>.delayed(Duration.zero);
  }
}

LessonScriptCubit _cubit(_Waits waits, {bool instant = false}) {
  final script = LessonScript.fromJson(_json());
  final cubit = LessonScriptCubit(
    lessonId: script.lessonId,
    partId: script.partId,
    scriptPath: 'roteiro.json',
    language: 'pt',
    scripts: FakeLessonScriptRepository(script, _texts()),
    kpk: FakeKpkRepository(_oracle()),
    source: FakeLessonSource(),
    initialStage: 0,
    delay: instant ? (_) async {} : waits.call,
  );
  addTearDown(cubit.close);
  return cubit;
}

void main() {
  test('lance errado: fica no tabuleiro, o Viktor explica, a refutação '
      'é jogada e "Tentar de novo" volta', () async {
    final waits = _Waits();
    final cubit = _cubit(waits);
    await cubit.start();
    expect(cubit.state.fen, _start);
    expect(cubit.state.phase, ScriptPhase.praticaVez);

    final done = cubit.onMove('f3e3');
    await Future<void>.delayed(Duration.zero);
    // O lance errado está no tabuleiro, com a fala e sem botão ainda.
    var s = cubit.state;
    expect(s.fen, startsWith('4k3/8/8/8/8/1P2K3/8/8 b'));
    expect(s.lastMove, 'f3e3');
    expect(s.tone, ScriptTone.bad);
    // A fala do roteiro em duas partes: primeiro o que o lance perde.
    expect(s.speech.single, _texts()['rot.pratica.ataque.err.f3e3.1']);
    expect(s.speech.single, startsWith('Com 1.Re3?'));
    expect(s.primary, isNull);
    expect(s.movable, isNull);
    expect(s.moves.first.san, 'Ke3');
    expect(s.moves.first.symbol, '?');

    // Cada espera solta joga mais um lance da refutação.
    final fens = <String>[s.fen];
    while (waits.pending.isNotEmpty || s.phase != ScriptPhase.praticaFim) {
      await waits.release();
      s = cubit.state;
      if (fens.last != s.fen) fens.add(s.fen);
      if (waits.pending.isEmpty && s.phase == ScriptPhase.praticaFim) break;
    }
    await done;
    expect(fens.length, inInclusiveRange(2, 4));
    expect(s.phase, ScriptPhase.praticaFim);
    expect(s.primary, ScriptAction.tentarDeNovo);
    expect(s.secondary, isNull);
    expect(s.moves.length, inInclusiveRange(2, 4));
    // Com a resposta, o porquê, que fica até o "Tentar de novo".
    expect(s.speech.single, _texts()['rot.pratica.ataque.err.f3e3.2']);
    expect(s.speech.single, contains('1...Rd7'));

    // Tentar de novo: a posição de antes, com a vez do aluno.
    await cubit.onAction(ScriptAction.tentarDeNovo);
    s = cubit.state;
    expect(s.fen, _start);
    expect(s.phase, ScriptPhase.praticaVez);
    expect(s.movable, isNotNull);
    expect(s.primary, isNull);
    expect(s.moves, isEmpty);
    expect(s.tone, ScriptTone.neutral);

    // E um lance certo segue normalmente.
    await cubit.onMove('f3e4');
    expect(cubit.state.tone, isNot(ScriptTone.bad));
    expect(cubit.state.moves.first.san, 'Ke4');
  });

  test(
    'a fala do roteiro vale só no primeiro lance; depois, a genérica',
    () async {
      final cubit = _cubit(_Waits(), instant: true);
      await cubit.start();
      await cubit.onMove('f3e4');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.fen, startsWith('3k4/8/8/8/4K3/1P6/8/8 w'));
      // b3b4 está nos erros do roteiro, mas a fala dele cita o 1º lance.
      await cubit.onMove('b3b4');
      expect(cubit.state.phase, ScriptPhase.praticaFim);
      expect(cubit.state.speech.single, startsWith('Com 2.b4?, as pretas'));
    },
  );

  test('cada erro previsto da prática tem as duas falas, em pt e en', () {
    final script = LessonScript.fromJson(
      jsonDecode(
        io.File('assets/lessons/roteiros/pawns.distantOpposition/distant.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    for (final language in ['pt', 'en']) {
      final texts = jsonDecode(
        io.File(
          'assets/lessons/$language/endgames/pawns.distantOpposition.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      var count = 0;
      for (final stage in script.stages) {
        for (final example in stage.examples) {
          for (final key in example.practice?.errors.values ?? <String>[]) {
            expect(texts['$key.1'], isA<String>(), reason: '$language $key.1');
            expect(texts['$key.2'], isA<String>(), reason: '$language $key.2');
            count++;
          }
        }
      }
      expect(count, 15);
    }
  });

  test('um lance certo não aciona a refutação', () async {
    final waits = _Waits();
    final cubit = _cubit(waits);
    await cubit.start();
    await cubit.onMove('f3e4');
    expect(cubit.state.primary, isNull);
    expect(cubit.state.phase, ScriptPhase.praticaVez);
    expect(waits.pending, isEmpty);
  });

  testWidgets('tela: o rodapé nunca fica vazio e o botão é "Tentar de novo"', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    final cubit = _cubit(_Waits(), instant: true);
    await cubit.start();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        speechCubit: speech,
        child: RepositoryProvider<CharacterRepository>.value(
          value: FakeCharacterRepository(),
          child: BlocProvider.value(
            value: cubit,
            child: LessonScriptScreen(title: Future.value('Oposição distante')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(LessonScriptKeys.primary), findsNothing);

    await cubit.onMove('f3e3');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.phase, ScriptPhase.praticaFim);
    expect(find.byKey(LessonScriptKeys.primary), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.textContaining('1...Rd7'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(LessonScriptKeys.primary)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(LessonScriptKeys.primary));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(cubit.state.fen, _start);
    expect(find.byKey(LessonScriptKeys.primary), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
