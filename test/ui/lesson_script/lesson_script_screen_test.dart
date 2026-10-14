import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

const _tall = Size(412, 915);
const _short = Size(360, 640);

class _Setup {
  _Setup(this.cubit);

  final LessonScriptCubit cubit;
}

Future<_Setup> _open(
  WidgetTester tester,
  Size size, {
  Map<String, dynamic>? json,
  Map<String, String>? texts,
  int stage = 0,
  FakeKpkOracle? oracle,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final speech = SpeechCubit(
    FakeVoiceRepository(settings: const VoiceSettings(enabled: false)),
  );
  addTearDown(speech.close);
  await speech.load();
  final settings = SettingsCubit(
    FakeSettingsRepository(const AppSettings(sound: false)),
    languages: AppLanguage.selectable,
  );
  addTearDown(settings.close);
  await settings.load();
  final cubit = LessonScriptCubit(
    lessonId: 'pawns.test',
    partId: 'distant',
    scriptPath: 'roteiro.json',
    language: 'pt',
    scripts: FakeLessonScriptRepository(
      json == null ? scriptFixture() : LessonScript.fromJson(json),
      {...scriptTexts(json), ...?texts},
    ),
    kpk: FakeKpkRepository(oracle ?? FakeKpkOracle()),
    source: FakeLessonSource(),
    initialStage: stage,
    delay: (_) async {},
  );
  addTearDown(cubit.close);
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
  return _Setup(cubit);
}

Rect _rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await _settle(tester);
}

/// Dois quadros: o `AnimatedSize` só começa a animar no quadro seguinte.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Toca no botão principal até a fase [phase] (os trechos curtos se juntam,
/// então a conta de toques depende do tamanho da tela).
Future<void> _until(WidgetTester tester, _Setup s, ScriptPhase phase) async {
  for (var i = 0; i < 12 && s.cubit.state.phase != phase; i++) {
    await _tap(tester, LessonScriptKeys.primary);
  }
  expect(s.cubit.state.phase, phase);
}

const _long =
    'Imagine que as brancas avançam o peão antes do rei e que as pretas '
    'respondem com o rei, para depois contarmos as casas.';

void main() {
  for (final size in [_tall, _short]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    group('tela $label', () {
      testWidgets('entrada: barra, livro, balão colado, Continuar e ◀ parado', (
        tester,
      ) async {
        await _open(tester, size);
        expect(tester.takeException(), isNull);
        expect(find.text('Oposição distante'), findsOneWidget);
        expect(find.byKey(LessonScriptKeys.bookButton), findsOneWidget);
        expect(
          tester.getSize(find.byKey(LessonScriptKeys.bookButton)).width,
          greaterThanOrEqualTo(48),
        );
        // Balão colado na barra (56 dp), com 8 de margem.
        expect(_rect(tester, LessonScriptKeys.speech).top, closeTo(56 + 8, 1));
        expect(find.text('Continuar'), findsOneWidget);
        expect(find.text('Ver resposta'), findsNothing);
        expect(
          tester
              .widget<IconButton>(find.byKey(LessonScriptKeys.back))
              .onPressed,
          isNull,
        );
        expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
      });

      testWidgets('balão: duas linhas no mínimo; o resto desce só além', (
        tester,
      ) async {
        await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
        final short = _rect(tester, LessonScriptKeys.speech);
        final lines = size.height < 700 ? 2 * 14 * 1.25 : 2 * 15 * 1.25;
        final pad = size.height < 700 ? 16.0 : 20.0;
        expect(short.height, closeTo(lines + pad, 1.5));
        final listTop = _rect(tester, LessonScriptKeys.board).top;
        await _tap(tester, LessonScriptKeys.primary);
        final grown = _rect(tester, LessonScriptKeys.speech);
        expect(grown.height, greaterThan(short.height));
        // Três linhas: o balão cresce e empurra o tabuleiro.
        expect(_rect(tester, LessonScriptKeys.board).top, greaterThan(listTop));
        expect(tester.takeException(), isNull);
      });

      testWidgets('trechos curtos se juntam num balão só', (tester) async {
        final s = await _open(tester, size);
        expect(s.cubit.state.speech.length, greaterThan(1));
        expect(find.byKey(LessonScriptKeys.speech), findsOneWidget);
      });

      testWidgets('tabuleiro cabe; lista tem altura; alvos de 48 dp', (
        tester,
      ) async {
        final s = await _open(tester, size);
        await _until(tester, s, ScriptPhase.pergunta);
        await _tap(tester, LessonScriptKeys.showAnswer);
        final board = _rect(tester, LessonScriptKeys.board);
        expect(board.width, lessThanOrEqualTo(size.width + 0.5));
        if (size == _tall) expect(board.width, closeTo(412, 1));
        final list = _rect(tester, LessonScriptKeys.moveList);
        expect(list.top, greaterThanOrEqualTo(board.bottom - 1));
        expect(list.height, greaterThan(0));
        expect(
          tester.getSize(find.byKey(LessonScriptKeys.primary)).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester.getSize(find.byKey(LessonScriptKeys.back)).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('pergunta: só Ver resposta; resposta traz a lista de lances', (
    tester,
  ) async {
    final s = await _open(tester, _tall);
    await _until(tester, s, ScriptPhase.pergunta);
    expect(find.text('Ver resposta'), findsOneWidget);
    expect(find.byKey(LessonScriptKeys.primary), findsNothing);
    expect(s.cubit.state.movable, isNotNull);
    expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
    await _tap(tester, LessonScriptKeys.showAnswer);
    expect(find.byKey(LessonScriptKeys.moveList), findsOneWidget);
    expect(s.cubit.state.moves, isNotEmpty);
    final first = s.cubit.state.moves.first.id;
    expect(find.byKey(LessonScriptKeys.move(first)), findsOneWidget);
    // Avançar mostra mais lances; tocar num já visto volta a ele.
    final before = s.cubit.state.moves.length;
    await _until(tester, s, ScriptPhase.fimExemplo);
    expect(s.cubit.state.moves.length, greaterThan(before));
    await _tap(tester, LessonScriptKeys.move(first));
    expect(s.cubit.state.currentMoveId, first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lance errado: refutação e jogo livre com ◀', (tester) async {
    final oracle = FakeKpkOracle(byFen: {afterKc3: KpkOutcome.draw});
    final s = await _open(tester, _tall, oracle: oracle);
    await _until(tester, s, ScriptPhase.pergunta);
    await s.cubit.onMove('d3c3');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.refutacao);
    expect(find.text('Continuar'), findsOneWidget);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.phase, ScriptPhase.livrePerdido);
    expect(find.byKey(LessonScriptKeys.primary), findsNothing);
    expect(s.cubit.state.movable, isNotNull);
    expect(
      tester.widget<IconButton>(find.byKey(LessonScriptKeys.back)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(LessonScriptKeys.back));
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.pergunta);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fim do jogo livre perdido: Voltar ao início volta à pergunta', (
    tester,
  ) async {
    const fen = '8/8/8/8/8/6k1/6P1/4K3 b - - 0 1';
    Map<String, dynamic> step(String f, String t, [String? move]) => {
      'fen': f,
      't': t,
      'lance': ?move,
    };
    final json = {
      'licao': 'pawns.test',
      'parte': 'distant',
      'etapas': [
        {
          'id': 'ideia',
          'exemplos': [
            {
              'id': 'c1',
              'fen': fen,
              'vira': true,
              'objetivo': 'empatar',
              'entrada': <dynamic>[],
              'pergunta': {
                't': 'q',
                'certos': ['g3h3'],
                'certo': step('8/8/8/8/8/7k/6P1/4K3 w - - 1 2', 'ok', 'g3h3'),
                'revela': step('8/8/8/8/8/7k/6P1/4K3 w - - 1 2', 'rev', 'g3h3'),
                'alternativos': <String, dynamic>{},
                'erros': <String, dynamic>{},
                'livre': {
                  'maquina': 'w',
                  'fala': 'free',
                  'fins': {'capturado': 'fin.cap'},
                  'volta': 'back',
                },
              },
              'linha': [step('8/8/8/8/8/8/6k1/4K3 w - - 0 1', 'l1')],
              'fim': 'etapa',
            },
          ],
        },
      ],
    };
    final s = await _open(tester, _tall, json: json);
    expect(s.cubit.state.phase, ScriptPhase.pergunta);
    await s.cubit.onMove('g3g2');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.refutacao);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.phase, ScriptPhase.livreFim);
    expect(find.text('Voltar ao início'), findsOneWidget);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.phase, ScriptPhase.pergunta);
    expect(s.cubit.state.speech, ['back']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o livro abre a folha Curiosidades', (tester) async {
    await _open(tester, _tall);
    await tester.tap(find.byKey(LessonScriptKeys.bookButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('cur.t'), findsOneWidget);
  });

  testWidgets('etapa de demonstrações segue sozinha até Próxima etapa', (
    tester,
  ) async {
    final s = await _open(tester, _tall, stage: 1);
    expect(find.byKey(LessonScriptKeys.showAnswer), findsNothing);
    await _until(tester, s, ScriptPhase.fimEtapa);
    expect(find.text('Próxima etapa'), findsOneWidget);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.stageId, 'pratica');
    expect(s.cubit.state.phase, ScriptPhase.praticaVez);
    expect(find.text('p.t'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fim da parte: Rever a ideia volta; Continuar conclui', (
    tester,
  ) async {
    final json = scriptJson();
    final example =
        (((json['etapas'] as List)[2] as Map)['exemplos'] as List).first as Map;
    example['fen'] = '4k3/6P1/8/8/8/8/8/4K3 w - - 0 1';
    ((json['etapas'] as List)[2] as Map)['exemplos'] = [example];
    final s = await _open(tester, _tall, json: json, stage: 2);
    expect(find.text('p.t'), findsOneWidget);
    await s.cubit.onMove('g7g8');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.praticaFim);
    expect(find.text('Rever a ideia'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byKey(LessonScriptKeys.nextPart), findsOneWidget);
    await _tap(tester, LessonScriptKeys.reviewIdea);
    expect(s.cubit.state.stageId, 'ideia');
    expect(tester.takeException(), isNull);
  });
}
