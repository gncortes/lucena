import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/routing/launch_location.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/data/services/tts_service.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/animated_speech_switcher.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/lesson_script/widgets/script_move_list.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';
import 'package:lucena/ui/lesson_script/widgets/script_page.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

const _tall = Size(412, 915);
const _short = Size(360, 640);
const _stabilitySizes = [
  Size(360, 740),
  Size(360, 800),
  Size(384, 832),
  Size(393, 873),
  Size(412, 915),
  Size(414, 896),
];

// Quebras explícitas: não dependem da fonte de teste para produzir 1/2/3 linhas.
const _neutralSpeeches = [
  'Olá.',
  'Primeira linha.\nSegunda linha.',
  'Primeira linha.\nSegunda linha.\nTerceira linha.',
  'Este é um texto sintético para conferir a interface. '
      'A fala completa continua disponível ao tocar no balão. '
      'O tamanho do texto não deve deslocar os elementos da lição. '
      'Repetimos esta mensagem apenas para ocupar mais espaço na tela. '
      'Este é um texto sintético para conferir a interface. '
      'A fala completa continua disponível ao tocar no balão.',
];

Map<String, dynamic> _geometryScript() {
  final json = scriptJson();
  final example =
      (((json['etapas'] as List).first as Map)['exemplos'] as List).first
          as Map;
  final first = (example['entrada'] as List).first as Map;
  example['entrada'] = [
    for (var i = 0; i < _neutralSpeeches.length; i++)
      <String, dynamic>{
        ...first.cast<String, dynamic>(),
        't': 'layout.$i',
        // Mantém FEN/lado/orientação; impede agrupar falas de tamanhos distintos.
        'salto': i > 0,
      },
  ];
  return json;
}

Map<Key, Rect> _geometry(WidgetTester tester) => {
  for (final key in [
    LessonScriptKeys.board,
    LessonScriptKeys.characterBar,
    LessonScriptKeys.primary,
    LessonScriptKeys.page,
  ])
    key: _rect(tester, key),
};

(int, double) _canvasReservation(double height, double width) {
  for (final candidate in [(4, 40.0), (3, 40.0), (2, 40.0), (2, 0.0)]) {
    if (height >= 42 + 22.5 * candidate.$1 + 58 + width + candidate.$2) {
      return candidate;
    }
  }
  return (2, 0);
}

void _expectGeometry(WidgetTester tester, Map<Key, Rect> expected) {
  for (final entry in expected.entries) {
    final actual = _rect(tester, entry.key);
    expect(
      actual.left,
      closeTo(entry.value.left, 0.5),
      reason: '${entry.key} x',
    );
    expect(actual.top, closeTo(entry.value.top, 0.5), reason: '${entry.key} y');
    expect(
      actual.width,
      closeTo(entry.value.width, 0.5),
      reason: '${entry.key} w',
    );
    expect(
      actual.height,
      closeTo(entry.value.height, 0.5),
      reason: '${entry.key} h',
    );
  }
  expect(tester.takeException(), isNull);
}

// Amostra também os quadros intermediários; não esconde deslocamentos no settle.
Future<void> _sampleGeometry(
  WidgetTester tester,
  Map<Key, Rect> expected,
) async {
  await tester.pump();
  _expectGeometry(tester, expected);
  for (var frame = 0; frame < 32; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    _expectGeometry(tester, expected);
  }
}

/// Um relógio que nunca dispara: o passo automático da etapa 1 não anda
/// sozinho no meio do teste nem deixa timer pendente no fim.
class _InertTimer implements Timer {
  @override
  bool get isActive => false;

  @override
  int get tick => 0;

  @override
  void cancel() {}
}

class _Setup {
  _Setup(this.cubit, this.voice);

  final LessonScriptCubit cubit;
  final FakeVoiceRepository voice;
}

class _UnavailableScripts extends FakeLessonScriptRepository {
  _UnavailableScripts() : super(scriptFixture());

  @override
  Future<LessonScript> script(String path) async =>
      throw const LessonContentUnavailable();
}

class _ExitSource extends EndgameLessonSource {
  _ExitSource(this.progress) : super(FakeEndgameLessonRepository(), progress);

  final FakeEndgameProgressRepository progress;
  final exitGate = Completer<void>();
  int leaves = 0;
  int failures = 0;

  @override
  Future<void> leave() async {
    leaves++;
    if (failures > 0) {
      failures--;
      throw StateError('falha temporária');
    }
    await exitGate.future;
    await super.leave();
  }
}

Future<_Setup> _open(
  WidgetTester tester,
  Size size, {
  Map<String, dynamic>? json,
  Map<String, String>? texts,
  int stage = 0,
  FakeKpkOracle? oracle,
  bool voiceOn = false,
  bool? autoPlay,
  LessonSource? source,
  bool navigable = false,
  LessonScriptRepository? repository,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final voice = FakeVoiceRepository(settings: VoiceSettings(enabled: voiceOn));
  final speech = SpeechCubit(voice);
  addTearDown(speech.close);
  await speech.load();
  final settings = SettingsCubit(
    FakeSettingsRepository(AppSettings(sound: voiceOn)),
    languages: AppLanguage.selectable,
  );
  addTearDown(settings.close);
  await settings.load();
  final cubit = LessonScriptCubit(
    lessonId: 'pawns.test',
    partId: 'distant',
    scriptPath: 'roteiro.json',
    language: 'pt',
    scripts:
        repository ??
        FakeLessonScriptRepository(
          json == null ? scriptFixture() : LessonScript.fromJson(json),
          {...scriptTexts(json), ...?texts},
        ),
    kpk: FakeKpkRepository(oracle ?? FakeKpkOracle()),
    source: source ?? FakeLessonSource(),
    initialStage: stage,
    delay: (_) async {},
    // O relógio de verdade só onde o teste mede o passo automático (por
    // padrão, a etapa 2).
    timer: autoPlay ?? stage == 1 ? Timer.new : (_, _) => _InertTimer(),
  );
  addTearDown(() {
    if (!cubit.isClosed) return cubit.close();
  });
  final lesson = RepositoryProvider<CharacterRepository>.value(
    value: FakeCharacterRepository(),
    child: BlocProvider.value(
      value: cubit,
      child: LessonScriptScreen(title: Future.value('Oposição distante')),
    ),
  );
  final router = navigable
      ? GoRouter(
          initialLocation: '/script',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('origem')),
              routes: [GoRoute(path: 'script', builder: (_, _) => lesson)],
            ),
          ],
        )
      : null;
  if (router != null) addTearDown(router.dispose);
  await tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      settingsCubit: settings,
      speechCubit: speech,
      router: router,
      child: lesson,
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  // O quadro seguinte termina o pop de entrada do balão.
  await tester.pump(SpeechPop.duration);
  return _Setup(cubit, voice);
}

Rect _rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
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

Map<String, dynamic> _guidedPracticeJson({bool invalidReply = false}) {
  final json = scriptJson();
  json['etapas'][2]['exemplos'] = [
    {
      'id': 'guided',
      'fen': '7k/8/6K1/8/8/8/8/R7 w - - 0 1',
      'vira': false,
      'objetivo': 'ganhar',
      'pratica': {
        'tipo': 'lance',
        't': 'guided.t',
        'maquina': 'b',
        'linha': [
          {
            'certos': ['a1a7'],
            'resposta': invalidReply ? 'h8h1' : 'h8g8',
          },
          {
            'certos': ['a7a8'],
          },
        ],
        'erros': {'a1a8': 'guided.error'},
      },
      'entrada': <dynamic>[],
      'linha': <dynamic>[],
      'fim': 'proximo',
    },
  ];
  return json;
}

void main() {
  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets(
      'erro da prática fica; retry e solução executam a linha autoral $size',
      (tester) async {
        final setup = await _open(
          tester,
          size,
          stage: 2,
          json: _guidedPracticeJson(),
        );
        final cubit = setup.cubit;
        final initial = cubit.state.fen;
        await cubit.onMove('a1a8');
        await _settle(tester);
        expect(find.text('Tentar de novo'), findsOneWidget);
        expect(find.text('Ver a solução'), findsOneWidget);
        final error = cubit.state;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(seconds: 2));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(cubit.state, error);
        await _tap(tester, LessonScriptKeys.primary);
        expect(cubit.state.fen, initial);
        await cubit.onMove('a1a8');
        await _settle(tester);
        await _tap(tester, LessonScriptKeys.showAnswer);
        expect(cubit.state.fen, initial);
        expect(cubit.state.arrows.single.to, 'a7');
        final settings = tester
            .element(find.byKey(LessonScriptKeys.screen))
            .read<SettingsCubit>();
        await settings.setLessonMarks(shown: false);
        await tester.pump();
        expect(
          tester.widget<ScriptBoard>(find.byType(ScriptBoard)).showMarks,
          true,
        );
        expect(settings.state!.lessonMarks, false);
        expect(cubit.canHint, false);
        expect(cubit.state.canBack, false);
        expect(find.text('Siga a seta.'), findsWidgets);
        expect(find.byKey(LessonScriptKeys.showAnswer), findsNothing);
        await cubit.onMove('a1a7');
        await _settle(tester);
        expect(cubit.state.lastMove, 'h8g8');
        expect(cubit.state.arrows.single.to, 'a8');
        await cubit.onMove('a7a8');
        await _settle(tester);
        expect(cubit.state.phase, ScriptPhase.praticaFim);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'solução ausente mostra estado vazio com retry sem lance inventado',
    (tester) async {
      final setup = await _open(
        tester,
        _tall,
        stage: 2,
        json: _guidedPracticeJson(invalidReply: true),
      );
      await setup.cubit.onMove('a1a8');
      await _settle(tester);
      await _tap(tester, LessonScriptKeys.showAnswer);
      expect(find.byKey(CoreKeys.emptyState), findsOneWidget);
      expect(
        find.text(
          'Não foi possível mostrar a solução desta posição. Tente de novo.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(LessonScriptKeys.board), findsNothing);
      await _tap(tester, LessonScriptKeys.primary);
      expect(find.byKey(CoreKeys.emptyState), findsOneWidget);
      expect(setup.cubit.state.moves, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in _stabilitySizes) {
    testWidgets(
      'conteúdo indisponível $size: centro útil e sair sem alterar progresso',
      (tester) async {
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 24);
        final progress = FakeEndgameProgressRepository();
        final saved = progress.saved;
        final source = _ExitSource(progress);
        await _open(
          tester,
          size,
          repository: _UnavailableScripts(),
          source: source,
          navigable: true,
        );
        await tester.pumpAndSettle();
        expect(
          find.text('As aulas ainda não estão disponíveis.'),
          findsOneWidget,
        );
        expect(find.byKey(LessonScriptKeys.board), findsNothing);
        final group = tester.getRect(find.byKey(CoreKeys.emptyState));
        expect(group.center.dx, closeTo(size.width / 2, .5));
        expect(group.center.dy, closeTo((56 + 64 + size.height - 24) / 2, .5));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(LessonScriptKeys.close));
        await tester.pumpAndSettle();
        expect(find.text('origem'), findsOneWidget);
        expect(source.leaves, 0);
        expect(identical(progress.saved, saved), isTrue);
      },
    );
  }
  for (final size in _stabilitySizes) {
    testWidgets('LIÇÃO $size: falas neutras, volta, repetição e folha '
        'conservam geometria inclusive durante animações', (tester) async {
      final setup = await _open(
        tester,
        size,
        json: _geometryScript(),
        texts: {
          for (var i = 0; i < _neutralSpeeches.length; i++)
            'layout.$i': _neutralSpeeches[i],
        },
        autoPlay: false,
      );
      final geometry = _geometry(tester);
      final board = geometry[LessonScriptKeys.board]!;
      final page = geometry[LessonScriptKeys.page]!;
      final strip = geometry[LessonScriptKeys.characterBar]!;
      expect(board.width, closeTo(size.width, 0.5));
      expect(board.height, closeTo(board.width, 0.5));
      expect(board.center.dx, closeTo(size.width / 2, 0.5));
      expect(board.top, closeTo(strip.bottom, 0.5));
      final context = tester.element(find.byKey(LessonScriptKeys.page));
      expect(MediaQuery.textScalerOf(context).scale(15), 15);
      expect(Theme.of(context).brightness, Brightness.light);
      final (lines, notation) = _canvasReservation(page.height, size.width);
      final reserved = 42 + 22.5 * lines;
      // Alvo vigente da LIÇÃO: sobras iguais ao redor do bloco reservado.
      // Não aplica ao tabuleiro o centro absoluto do FreeBoard/partida.
      expect(
        strip.top - reserved - page.top,
        closeTo(page.bottom - board.bottom - notation, 0.5),
      );
      for (var cycle = 0; cycle < 2; cycle++) {
        for (var i = 0; i < _neutralSpeeches.length; i++) {
          expect(setup.cubit.state.speech, [_neutralSpeeches[i]]);
          if (i + 1 < _neutralSpeeches.length) {
            await tester.tap(find.byKey(LessonScriptKeys.primary));
            await _sampleGeometry(tester, geometry);
          }
        }
        final beforeSheet = setup.cubit.state;
        await tester.tap(find.byKey(LessonScriptKeys.speech));
        await _sampleGeometry(tester, geometry);
        final sheet = find.byKey(LessonScriptKeys.speechSheet);
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(
            of: sheet,
            matching: find.text(_neutralSpeeches.last),
          ),
          findsOneWidget,
        );
        // A folha permanece embaixo; o X fica fora, acima do conteúdo.
        final sheetRect = tester.getRect(sheet);
        expect(sheetRect.bottom, closeTo(size.height, 0.5));
        final close = _rect(tester, LessonScriptKeys.speechSheetClose);
        expect(close.bottom, lessThanOrEqualTo(sheetRect.top));
        expect(close.height, greaterThanOrEqualTo(48));
        await tester.tap(find.byKey(LessonScriptKeys.speechSheetClose));
        await _sampleGeometry(tester, geometry);
        expect(sheet, findsNothing);
        expect(setup.cubit.state, beforeSheet);
        for (var i = _neutralSpeeches.length - 2; i >= 0; i--) {
          await tester.tap(find.byKey(LessonScriptKeys.back));
          await _sampleGeometry(tester, geometry);
          expect(setup.cubit.state.speech, [_neutralSpeeches[i]]);
        }
      }
    });

    testWidgets('LIÇÃO $size: repetir demonstração neutra conserva o '
        'tabuleiro na troca de fase', (tester) async {
      final json = _geometryScript();
      final stages = json['etapas'] as List;
      final idea = ((stages.first as Map)['exemplos'] as List).first as Map;
      final demo = ((stages[1] as Map)['exemplos'] as List).first as Map;
      demo['entrada'] = idea['entrada'];
      demo['linha'] = <dynamic>[];
      final setup = await _open(
        tester,
        size,
        json: json,
        stage: 1,
        autoPlay: false,
        texts: {
          for (var i = 0; i < _neutralSpeeches.length; i++)
            'layout.$i': _neutralSpeeches[i],
        },
      );
      // Os controles mudam ao terminar; a área do tabuleiro deve permanecer.
      final geometry = _geometry(tester)..remove(LessonScriptKeys.primary);
      final footer = tester.getRect(find.byKey(LessonScriptKeys.footer));
      // Conteúdo de 64 dp (anel) + folgas de 8 dp acima e 16 dp abaixo.
      expect(footer.height, closeTo(96, 0.5));
      for (var cycle = 0; cycle < 2; cycle++) {
        expect(setup.cubit.state.speech, [_neutralSpeeches.first]);
        for (var i = 1; i < _neutralSpeeches.length; i++) {
          await tester.tap(find.byKey(LessonScriptKeys.primary));
          await _sampleGeometry(tester, geometry);
          expect(tester.getRect(find.byKey(LessonScriptKeys.footer)), footer);
          expect(setup.cubit.state.speech, [_neutralSpeeches[i]]);
        }
        expect(setup.cubit.state.phase, ScriptPhase.fimEtapa);
        await tester.tap(find.byKey(LessonScriptKeys.demoRepeat));
        await _sampleGeometry(tester, geometry);
        expect(tester.getRect(find.byKey(LessonScriptKeys.footer)), footer);
        expect(setup.cubit.state.phase, ScriptPhase.entrada);
      }
    });

    testWidgets('ScriptPage $size: revelação incremental sintética e '
        'pontinhos preservam a posição reservada', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final content = ValueNotifier((texts: const ['Olá.'], typing: false));
      addTearDown(content.dispose);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: ValueListenableBuilder<({List<String> texts, bool typing})>(
              valueListenable: content,
              builder: (context, value, _) => ScriptPage(
                pageKey: LessonScriptKeys.page,
                speechBuilder: (metrics) => ScriptSpeech(
                  texts: value.texts,
                  metrics: metrics,
                  typing: value.typing,
                ),
                strip: const SizedBox(
                  key: LessonScriptKeys.characterBar,
                  height: ScriptPage.stripHeight,
                ),
                // Apenas a caixa: este cenário não avalia posições/lances.
                boardBuilder: (side) => SizedBox.square(
                  key: LessonScriptKeys.board,
                  dimension: side,
                ),
                list: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      final geometry = {
        for (final key in [
          LessonScriptKeys.board,
          LessonScriptKeys.characterBar,
          LessonScriptKeys.page,
        ])
          key: _rect(tester, key),
      };
      // Não existe typewriter neste fluxo: simula só a variação de texto.
      final text = _neutralSpeeches[2];
      for (var end = 1; end <= text.length; end++) {
        content.value = (texts: [text.substring(0, end)], typing: false);
        await tester.pump(const Duration(milliseconds: 16));
        _expectGeometry(tester, geometry);
      }
      for (final texts in [
        [_neutralSpeeches.first, 'Outro trecho.'],
        [_neutralSpeeches.last],
        [_neutralSpeeches[1], 'Outro trecho.'],
        [_neutralSpeeches.first],
      ]) {
        content.value = (texts: texts, typing: false);
        await _sampleGeometry(tester, geometry);
      }
      for (final typing in [true, false, true, false]) {
        content.value = (texts: [_neutralSpeeches.last], typing: typing);
        await _sampleGeometry(tester, geometry);
        expect(
          find.byKey(LessonScriptKeys.typing),
          typing ? findsOneWidget : findsNothing,
        );
      }
    });
  }

  testWidgets('saída pode tentar novamente depois de falha transitória', (
    tester,
  ) async {
    final source = _ExitSource(FakeEndgameProgressRepository())..failures = 1;
    source.exitGate.complete();
    final setup = await _open(tester, _tall, source: source, navigable: true);
    await tester.tap(find.byKey(LessonScriptKeys.close));
    // Não espera a barra de leitura inteira: o aviso tem duração menor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(LessonScriptKeys.screen), findsOneWidget);
    expect(
      find.text(
        tester
            .element(find.byKey(LessonScriptKeys.screen))
            .l10n
            .lessonSaveRetry,
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(LessonScriptKeys.close));
    await tester.pumpAndSettle();
    expect(find.text('origem'), findsOneWidget);
    expect(source.leaves, 2);
    expect((await source.progress.load()).ongoing!.open, isFalse);
    await tester.pumpWidget(const SizedBox());
    await setup.cubit.close();
  });
  for (final androidBack in [false, true]) {
    testWidgets(
      'saída ${androidBack ? 'Android' : 'appbar'} aguarda persistência '
      'e cancela avanço automático sem perder cursor',
      (tester) async {
        final source = _ExitSource(FakeEndgameProgressRepository());
        final setup = await _open(
          tester,
          _tall,
          stage: 1,
          source: source,
          navigable: true,
          texts: {'d1a': _long, 'd1b': _long},
        );
        await setup.cubit.onAction(ScriptAction.continuar);
        await tester.pump();
        final before = (await source.progress.load()).ongoing!;
        expect(before.open, isTrue);
        expect(before.scriptTrack, 'entrada');
        expect(before.scriptHead, 1);
        expect(setup.cubit.state.demo!.playing, isTrue);
        if (androidBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byKey(LessonScriptKeys.close));
        }
        await tester.pump();
        expect(source.leaves, 1);
        expect(find.byKey(LessonScriptKeys.screen), findsOneWidget);
        // Enquanto leave aguarda I/O, nem o timer nem outro Voltar avançam.
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(seconds: 10));
        expect(source.leaves, 1);
        expect((await source.progress.load()).ongoing, before);
        source.exitGate.complete();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(find.byKey(LessonScriptKeys.screen), findsNothing);
        expect(find.text('origem'), findsOneWidget);
        final progress = await source.progress.load();
        expect(progress.ongoing, before.copyWith(open: false));
        expect(launchLocation(endgames: progress), Routes.home);
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('background e descarte da tela conservam retomada automática', (
    tester,
  ) async {
    final source = _ExitSource(FakeEndgameProgressRepository());
    final setup = await _open(
      tester,
      _tall,
      stage: 1,
      source: source,
      texts: {'d1a': _long, 'd1b': _long},
    );
    await setup.cubit.onAction(ScriptAction.continuar);
    await tester.pump();
    final before = (await source.progress.load()).ongoing!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect((await source.progress.load()).ongoing, before);
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    // O harness usa BlocProvider.value: o dono externo encerra o Cubit.
    await setup.cubit.close();
    expect(source.leaves, 0);
    final progress = await source.progress.load();
    expect(progress.ongoing!.open, isTrue);
    expect(
      launchLocation(endgames: progress),
      Routes.endgameLessonScript(
        'pawns.test',
        part: 'distant',
        stage: 1,
        origin: 'continuar',
      ),
    );
  });
  for (final size in const [Size(360, 740), Size(412, 917)]) {
    testWidgets('área da fala fixa $size: 1 linha, 3 linhas e de volta, o '
        'tabuleiro e a faixa ficam no mesmo lugar', (tester) async {
      await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
      final board = _rect(tester, LessonScriptKeys.board);
      final strip = _rect(tester, LessonScriptKeys.characterBar);
      final footer = _rect(tester, LessonScriptKeys.primary);
      final oneLine = _rect(tester, LessonScriptKeys.speech);
      await _tap(tester, LessonScriptKeys.primary);
      final threeLines = _rect(tester, LessonScriptKeys.speech);
      expect(threeLines.height, greaterThan(oneLine.height));
      expect(_rect(tester, LessonScriptKeys.board), board);
      expect(_rect(tester, LessonScriptKeys.characterBar), strip);
      expect(_rect(tester, LessonScriptKeys.primary), footer);
      await _tap(tester, LessonScriptKeys.back);
      expect(_rect(tester, LessonScriptKeys.board), board);
      expect(_rect(tester, LessonScriptKeys.speech).height, oneLine.height);
      // Canvas: balão termina na faixa; retrato começa 8 dp abaixo.
      // The widget bounds include the 6 dp tail gap.
      expect(strip.top - threeLines.bottom, closeTo(0, 0.5));
      // A faixa fica colada no tabuleiro: a sobra vai para cima da área da
      // fala e para baixo do tabuleiro, em partes iguais.
      expect(board.top - strip.bottom, closeTo(0, 0.01));
      final page = _rect(tester, LessonScriptKeys.page);
      final (lines, notation) = _canvasReservation(page.height, size.width);
      final area = 42 + 22.5 * lines;
      final top = strip.top - area - page.top;
      expect(top, greaterThan(0));
      expect(top, closeTo(page.bottom - board.bottom - notation, 0.5));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [_tall, _short]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    group('tela $label', () {
      testWidgets('entrada: barra, livro, balão colado, ⏸ e ⏭ e ◀ parado', (
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
        // Balão abaixo da barra (56 dp), com ao menos 2 dp de folga.
        final speech = _rect(tester, LessonScriptKeys.speech);
        expect(speech.top, greaterThanOrEqualTo(56 + 2 - 0.5));
        // Com a área da fala fixa, o tabuleiro fica no meio entre a faixa do
        // Viktor e o rodapé (sobra igual em cima e embaixo); na tela baixa,
        // logo abaixo da fala.
        final board = _rect(tester, LessonScriptKeys.board);
        final page = _rect(tester, LessonScriptKeys.page);
        if (size == _tall) {
          final strip = _rect(tester, LessonScriptKeys.characterBar);
          // Faixa colada no tabuleiro; a sobra se divide igual entre o alto
          // da área da fala e o fundo da página.
          expect(board.top - strip.bottom, closeTo(0, 0.01));
          expect(board.bottom, lessThan(page.bottom));
        } else {
          expect(board.top, greaterThan(speech.bottom));
        }
        // A fala de "Continuar" da etapa 1 passa sozinha: ⏸ e o Continuar
        // que enche (Gabriel, 16/10/2026).
        expect(find.byKey(LessonScriptKeys.demoToggle), findsOneWidget);
        expect(find.byKey(LessonScriptKeys.theoryFill), findsOneWidget);
        expect(find.text('Continuar'), findsOneWidget);
        expect(find.text('Ver resposta'), findsNothing);
        // Sem passo anterior, o botão voltar não aparece.
        expect(find.byKey(LessonScriptKeys.back), findsNothing);
        expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
        // Rodapé com o fundo da tela, só com a linha em cima (F2).
        expect(_rect(tester, LessonScriptKeys.footer).height, 96);
      });

      testWidgets('balão: área fixa de 3 linhas; fala curta ou longa, o '
          'tabuleiro e a faixa não se mexem', (tester) async {
        await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
        final short = _rect(tester, LessonScriptKeys.speech);
        final boardBefore = _rect(tester, LessonScriptKeys.board);
        final stripBefore = _rect(tester, LessonScriptKeys.characterBar);
        await _tap(tester, LessonScriptKeys.primary);
        final grown = _rect(tester, LessonScriptKeys.speech);
        // O balão cresce para cima, preso embaixo, junto do retrato.
        expect(grown.height, greaterThan(short.height));
        expect(grown.bottom, closeTo(short.bottom, 0.5));
        expect(_rect(tester, LessonScriptKeys.board), boardBefore);
        expect(_rect(tester, LessonScriptKeys.characterBar), stripBefore);
        final text = tester.widget<Text>(
          find
              .descendant(
                of: find.byKey(LessonScriptKeys.speech),
                matching: find.byType(Text),
              )
              .first,
        );
        // Nunca reticências: a letra encolhe (ou a fala rola).
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(text.maxLines, isNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'o tabuleiro encolhe só após reduzir linhas e notação; fala 15',
        (tester) async {
          await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
          final board = _rect(tester, LessonScriptKeys.board);
          final page = _rect(tester, LessonScriptKeys.page);
          final (_, notation) = _canvasReservation(page.height, size.width);
          expect(
            page.bottom - board.bottom,
            greaterThanOrEqualTo(notation - .5),
          );
          final text = tester.widget<Text>(
            find
                .descendant(
                  of: find.byKey(LessonScriptKeys.speech),
                  matching: find.byType(Text),
                )
                .first,
          );
          expect(text.style?.fontSize ?? text.textSpan?.style?.fontSize, 15);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('tabuleiro: um tamanho só, na largura cheia; na tela baixa, '
          'o maior possível, centralizado', (tester) async {
        await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
        final before = _rect(tester, LessonScriptKeys.board);
        await _tap(tester, LessonScriptKeys.primary);
        final after = _rect(tester, LessonScriptKeys.board);
        // A fala mudou de tamanho, o tabuleiro não.
        expect(after.width, closeTo(before.width, 0.5));
        if (size == _tall) {
          expect(after.width, closeTo(size.width, 0.5));
        } else {
          expect(after.width, greaterThanOrEqualTo(0.8 * size.width));
          expect(after.center.dx, closeTo(size.width / 2, 0.5));
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('clique no balão abre a fala inteira; o ✕ fora da folha '
          'fecha', (tester) async {
        await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
        await _tap(tester, LessonScriptKeys.primary);
        await tester.tap(find.byKey(LessonScriptKeys.speech));
        // No meio da subida, o retrato voa (Hero).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(Hero), findsWidgets);
        await _settle(tester);
        final sheet = find.byKey(LessonScriptKeys.speechSheet);
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining('contarmos'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.textContaining('Viktor')),
          findsOneWidget,
        );
        // O ✕ fica acima da folha, fora dela, com alvo de 48 dp.
        final close = _rect(tester, LessonScriptKeys.speechSheetClose);
        expect(
          close.bottom,
          lessThanOrEqualTo(_rect(tester, LessonScriptKeys.speechSheet).top),
        );
        expect(close.height, greaterThanOrEqualTo(48));
        await _tap(tester, LessonScriptKeys.speechSheetClose);
        expect(sheet, findsNothing);
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
        final (_, notation) = _canvasReservation(
          _rect(tester, LessonScriptKeys.page).height,
          size.width,
        );
        if (notation > 0) {
          final list = _rect(tester, LessonScriptKeys.moveList);
          expect(list.top, greaterThanOrEqualTo(board.bottom - 1));
          expect(list.height, greaterThan(0));
        } else {
          expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
        }
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
    expect(find.text('Ver a solução'), findsOneWidget);
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
    // O rodapé tem altura fixa: com ou sem o ◀, o tabuleiro não pula.
    double footerTop() =>
        tester.getTopLeft(find.byKey(LessonScriptKeys.footer)).dy;
    final top = footerTop();
    await s.cubit.onMove('d3c3');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.refutacao);
    expect(footerTop(), top);
    expect(find.text('Continuar'), findsOneWidget);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.phase, ScriptPhase.livrePerdido);
    expect(find.byKey(LessonScriptKeys.primary), findsNothing);
    expect(footerTop(), top);
    expect(s.cubit.state.movable, isNotNull);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(LessonScriptKeys.back),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(LessonScriptKeys.back));
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.pergunta);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fim do jogo livre: um botão só, Ver linha principal', (
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
              'objetivo': 'ganhar',
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
    // Fora do roteiro: o rei preto captura o peão na hora, e o objetivo
    // (ganhar) não se cumpre.
    // Rei contra rei é empate (T76): o juiz condena o lance antes.
    await s.cubit.onMove('g3g2');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.refutacao);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.phase, ScriptPhase.livreFim);
    // A fala do fim vem sozinha; o convite com o link é o passo seguinte.
    expect(find.byKey(LessonScriptKeys.mainLine), findsNothing);
    await _tap(tester, LessonScriptKeys.primary);
    expect(find.byKey(LessonScriptKeys.mainLine), findsOneWidget);
    expect(find.text('Voltar ao início'), findsNothing);
    // O Viktor convida a ver a linha principal; o rótulo na fala é clicável
    // e faz o mesmo que o botão.
    final link = find.textRange.ofSubstring(
      'ver linha principal',
      descendentOf: find.byKey(LessonScriptKeys.speech),
    );
    expect(link, findsOneWidget);
    await tester.tapOnText(link);
    await _settle(tester);
    // A linha principal a partir do lance certo.
    expect(s.cubit.state.speech.first, 'ok');
    expect(tester.takeException(), isNull);
  });

  testWidgets('o livro abre a folha Curiosidades', (tester) async {
    await _open(tester, _tall);
    await tester.tap(find.byKey(LessonScriptKeys.bookButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('cur.t'), findsOneWidget);
  });

  testWidgets(
    '360x640: Canvas remove a notação antes de encolher o tabuleiro',
    (tester) async {
      final s = await _open(tester, _short);
      await _until(tester, s, ScriptPhase.pergunta);
      await _tap(tester, LessonScriptKeys.showAnswer);
      expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
      final footer = tester.getTopLeft(find.byKey(LessonScriptKeys.footer)).dy;
      final board = _rect(tester, LessonScriptKeys.board);
      expect(board.width, greaterThanOrEqualTo(0.8 * _short.width));
      expect(board.bottom, closeTo(footer, .5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('livro só na posição com curiosidade; título central sem ações', (
    tester,
  ) async {
    await _open(tester, _tall);
    expect(find.byKey(LessonScriptKeys.bookButton), findsOneWidget);
    final title = tester.getTopLeft(find.text('Oposição distante'));
    expect(title.dx, lessThan(_tall.width / 4));
    await _open(tester, _tall, stage: 1);
    expect(find.byKey(LessonScriptKeys.bookButton), findsNothing);
    expect(
      tester.getCenter(find.text('Oposição distante')).dx,
      closeTo(_tall.width / 2, .5),
    );
  });

  testWidgets('o botão ao lado do som esconde e mostra as marcações', (
    tester,
  ) async {
    await _open(tester, _tall);
    bool shown() =>
        tester.widget<ScriptBoard>(find.byType(ScriptBoard)).showMarks;
    expect(shown(), isTrue);
    expect(
      tester.getSize(find.byKey(LessonScriptKeys.marksToggle)).width,
      greaterThanOrEqualTo(48),
    );
    await _tap(tester, LessonScriptKeys.marksToggle);
    expect(shown(), isFalse);
    expect(
      tester
          .element(find.byType(LessonScriptScreen))
          .read<SettingsCubit>()
          .state
          ?.lessonMarks,
      isFalse,
    );
    await _tap(tester, LessonScriptKeys.marksToggle);
    expect(shown(), isTrue);
  });

  testWidgets('etapa de demonstrações segue sozinha até Próxima etapa', (
    tester,
  ) async {
    final s = await _open(tester, _tall, stage: 1);
    expect(find.byKey(LessonScriptKeys.showAnswer), findsNothing);
    await _until(tester, s, ScriptPhase.fimEtapa);
    expect(find.text('Praticar'), findsOneWidget);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.stageId, 'pratica');
    expect(s.cubit.state.phase, ScriptPhase.praticaVez);
    expect(find.text('p.t'), findsOneWidget);
    // Sem rótulo de posição (Gabriel, 14/10/2026).
    expect(find.textContaining('Posição'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demonstração com voz: o passo espera o Viktor acabar de '
      'falar e só faz a pausa depois', (tester) async {
    final s = await _open(tester, _tall, stage: 1, voiceOn: true);
    // A tela alta junta os trechos curtos num balão só.
    final first = s.cubit.state.speech;
    expect(s.voice.spoken.last.$1, first.join(' '));
    expect(s.cubit.state.demo!.speaking, isTrue);
    // Bem mais que o tempo de leitura: a voz ainda fala, o passo espera.
    await tester.pump(LessonScriptCubit.readTime(first.join(' ')) * 3);
    expect(s.cubit.state.speech, first);
    s.voice.emit(const TtsFinished());
    await tester.pump();
    expect(s.cubit.state.demo!.speaking, isFalse);
    expect(s.cubit.state.demo!.remaining, LessonScriptCubit.voicePause);
    await tester.pump(LessonScriptCubit.voicePause);
    await tester.pump();
    final next = s.cubit.state.speech;
    expect(next, isNot(first));
    expect(s.voice.spoken.last.$1, next.join(' '));
    // O fim da etapa não tem relógio: a voz fala e nada espera por ela.
    expect(s.cubit.state.demo!.ended, isTrue);
    expect(s.cubit.state.demo!.speaking, isFalse);
    s.voice.emit(const TtsFinished());
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demonstração sem voz: vale o tempo de leitura', (tester) async {
    final s = await _open(tester, _tall, stage: 1);
    final first = s.cubit.state.speech;
    expect(s.voice.spoken, isEmpty);
    expect(s.cubit.state.demo!.speaking, isFalse);
    final read = LessonScriptCubit.readTime(first.join(' '));
    // O `_open` já passou 1,2 s (1 s e o pop do balão).
    await tester.pump(read - const Duration(milliseconds: 1300));
    expect(s.cubit.state.speech, first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(s.cubit.state.speech, isNot(first));
    expect(s.cubit.state.demo!.ended, isTrue);
    await _settle(tester);
  });

  testWidgets('segundo plano: a demonstração espera no fundo e segue na '
      'volta', (tester) async {
    final s = await _open(tester, _tall, stage: 1);
    final first = s.cubit.state.speech;
    final read = LessonScriptCubit.readTime(first.join(' '));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(read * 5);
    expect(s.cubit.state.speech, first);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(s.cubit.state.speech, first);
    expect(s.cubit.state.demo!.playing, isTrue);
    await tester.pump(read);
    await tester.pump();
    expect(s.cubit.state.speech, isNot(first));
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rodapé da demonstração: ← sempre, ↻ ⏮ ⏸ e o ⏭ com anel; '
      'no fim, só ↻ e Próxima etapa', (tester) async {
    final s = await _open(tester, _tall, stage: 1);
    expect(s.cubit.state.demo, isNotNull);
    for (final key in [
      LessonScriptKeys.back,
      LessonScriptKeys.demoRepeat,
      LessonScriptKeys.demoStepBack,
      LessonScriptKeys.demoToggle,
      LessonScriptKeys.demoRing,
      LessonScriptKeys.primary,
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: '$key');
    }
    expect(find.text('Continuar'), findsNothing);
    // ⏸ pausa: o ícone vira ▶.
    await _tap(tester, LessonScriptKeys.demoToggle);
    expect(s.cubit.state.demo!.playing, isFalse);
    expect(find.byIcon(CanvasSymbols.playArrow), findsOneWidget);
    // ⏭ avança mesmo pausada.
    final tick = s.cubit.state.demo!.tick;
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.demo?.tick, isNot(tick));
    await _until(tester, s, ScriptPhase.fimEtapa);
    expect(s.cubit.state.demo?.ended, isTrue);
    expect(find.byKey(LessonScriptKeys.demoRepeat), findsOneWidget);
    expect(find.byKey(LessonScriptKeys.demoToggle), findsNothing);
    expect(find.byKey(LessonScriptKeys.demoStepBack), findsNothing);
    expect(find.text('Praticar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fala de 5 linhas na tela alta: o balão usa a sobra de cima, '
      'sem rolar nem diminuir a letra, e o tabuleiro não se mexe (Gabriel, '
      '16/10/2026)', (tester) async {
    // Na fonte dos testes (caixas de 15 dp), umas 5 linhas: além das 3 da
    // área fixa, mesmo em 13.
    const five =
        'Uma regra para achar as casas-chave: elas ficam duas fileiras à '
        'frente do peão.';
    await _open(tester, _tall, texts: {'e1': 'Curto.', 'e2': five});
    final board = _rect(tester, LessonScriptKeys.board);
    final page = _rect(tester, LessonScriptKeys.page);
    await _tap(tester, LessonScriptKeys.primary);
    final speech = _rect(tester, LessonScriptKeys.speech);
    expect(_rect(tester, LessonScriptKeys.board), board);
    expect(speech.top, greaterThanOrEqualTo(page.top));
    final inside = find.descendant(
      of: find.byKey(LessonScriptKeys.speech),
      matching: find.byType(SingleChildScrollView),
    );
    expect(inside, findsNothing);
    final text = tester.widget<Text>(
      find
          .descendant(
            of: find.byKey(LessonScriptKeys.speech),
            matching: find.byType(Text),
          )
          .first,
    );
    expect(text.style?.fontSize ?? text.textSpan?.style?.fontSize, 15);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'teoria (etapa 1): ← quando há volta, ⏸ e o Continuar que enche, sem ↻ '
    'nem ⏮; a fala passa sozinha e a pergunta espera o aluno',
    (tester) async {
      final s = await _open(tester, _tall, autoPlay: true);
      expect(s.cubit.state.stageId, 'ideia');
      expect(s.cubit.state.demo?.full, isFalse);
      expect(find.byKey(LessonScriptKeys.demoToggle), findsOneWidget);
      expect(find.byKey(LessonScriptKeys.demoRing), findsNothing);
      expect(find.byKey(LessonScriptKeys.theoryFill), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.primary),
          matching: find.text('Continuar'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(LessonScriptKeys.demoRepeat), findsNothing);
      expect(find.byKey(LessonScriptKeys.demoStepBack), findsNothing);
      // ⏸ pausa; ▶ retoma.
      await _tap(tester, LessonScriptKeys.demoToggle);
      expect(s.cubit.state.demo!.playing, isFalse);
      await _tap(tester, LessonScriptKeys.demoToggle);
      expect(s.cubit.state.demo!.playing, isTrue);
      // Sem voz, o tempo de leitura passa a fala sozinha até a pergunta, que
      // não tem relógio.
      for (var i = 0; i < 12; i++) {
        if (s.cubit.state.phase == ScriptPhase.pergunta) break;
        await tester.pump(const Duration(seconds: 9));
        await _settle(tester);
      }
      expect(s.cubit.state.phase, ScriptPhase.pergunta);
      expect(s.cubit.state.demo, isNull);
      expect(find.byKey(LessonScriptKeys.theoryFill), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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
  testWidgets('fim da demo: a ponte fica na posição final, com o lance', (
    tester,
  ) async {
    final s = await _open(tester, _tall, json: demoToPractice());
    await _until(tester, s, ScriptPhase.fimEtapa);
    final board = tester.widget<ScriptBoard>(find.byType(ScriptBoard));
    expect(board.state.fen, '8/8/8/3k4/8/3K4/5P2/8 w - - 4 3');
    expect(board.state.lastMove, 'd6d5');
    final list = tester.widget<ScriptMoveList>(find.byType(ScriptMoveList));
    expect(list.currentId, list.moves.last.id);
    expect(list.moves, hasLength(4));
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.stageId, 'pratica');
    expect(tester.takeException(), isNull);
  });
}
