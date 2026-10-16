import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/data/services/tts_service.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/exercise_actions.dart';
import 'package:lucena/ui/core/widgets/animated_speech_switcher.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/lesson_script/widgets/script_move_list.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';
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
import 'lesson_script_fim_demo_test.dart' show demoToPractice;

const _tall = Size(412, 915);
const _short = Size(360, 640);

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

Future<_Setup> _open(
  WidgetTester tester,
  Size size, {
  Map<String, dynamic>? json,
  Map<String, String>? texts,
  int stage = 0,
  FakeKpkOracle? oracle,
  bool voiceOn = false,
  bool? autoPlay,
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
    scripts: FakeLessonScriptRepository(
      json == null ? scriptFixture() : LessonScript.fromJson(json),
      {...scriptTexts(json), ...?texts},
    ),
    kpk: FakeKpkRepository(oracle ?? FakeKpkOracle()),
    source: FakeLessonSource(),
    initialStage: stage,
    delay: (_) async {},
    // O relógio de verdade só onde o teste mede o passo automático (por
    // padrão, a etapa 2).
    timer: autoPlay ?? stage == 1 ? Timer.new : (_, _) => _InertTimer(),
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

void main() {
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
      // A ponta fica a 2 dp do retrato (40 dp, no meio da faixa de 50).
      expect(strip.top + 5 - threeLines.bottom, closeTo(2, 0.5));
      // A faixa fica colada no tabuleiro: a sobra vai para cima da área da
      // fala e para baixo do tabuleiro, em partes iguais.
      expect(board.top - strip.bottom, closeTo(0, 0.01));
      final page = _rect(tester, LessonScriptKeys.page);
      final context = tester.element(find.byKey(LessonScriptKeys.page));
      final area = ScriptSpeechMetrics.of(context).areaHeight(context);
      final top = strip.top - area - page.top;
      expect(top, greaterThan(0));
      expect(top, closeTo(page.bottom - board.bottom, 0.5));
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
        // A fala de "Continuar" da etapa 1 passa sozinha: ⏸ e o ⏭ com o
        // anel, que diz "Continuar" (Gabriel, 16/10/2026).
        expect(find.byKey(LessonScriptKeys.demoToggle), findsOneWidget);
        expect(find.byKey(LessonScriptKeys.demoRing), findsOneWidget);
        expect(find.byTooltip('Continuar'), findsOneWidget);
        expect(find.text('Ver resposta'), findsNothing);
        // Sem passo anterior, o botão voltar não aparece.
        expect(find.byKey(LessonScriptKeys.back), findsNothing);
        expect(find.byKey(LessonScriptKeys.moveList), findsNothing);
        // Rodapé com o fundo da tela, só com a linha em cima (F2).
        expect(
          tester.widget<ExerciseActions>(find.byType(ExerciseActions)).color,
          Theme.of(tester.element(find.byKey(LessonScriptKeys.screen)))
              .scaffoldBackgroundColor,
        );
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

      testWidgets('o tabuleiro deixa 8 dp até o rodapé e a letra do balão é 15 '
          '(canvas PropV2ExA4P360)', (tester) async {
        await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
        final board = _rect(tester, LessonScriptKeys.board);
        final page = _rect(tester, LessonScriptKeys.page);
        expect(page.bottom - board.bottom, greaterThanOrEqualTo(8 - 0.5));
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
    // O rodapé tem altura fixa: com ou sem o ◀, o tabuleiro não pula.
    double footerTop() => tester.getTopLeft(find.byType(ExerciseActions)).dy;
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
          .widget<FloatingActionButton>(find.byKey(LessonScriptKeys.back))
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
      'Ver linha principal',
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

  testWidgets('360: a lista fica abaixo da dobra e aparece rolando a tela, '
      'com o mesmo componente do 412 (Gabriel, 14/10/2026, opção A)', (
    tester,
  ) async {
    final s = await _open(tester, _short);
    await _until(tester, s, ScriptPhase.pergunta);
    await _tap(tester, LessonScriptKeys.showAnswer);
    final list = find.byKey(LessonScriptKeys.moveList);
    expect(
      find.ancestor(of: list, matching: find.byType(ScriptMoveList)),
      findsOneWidget,
    );
    final footer = tester.getTopLeft(find.byType(ExerciseActions)).dy;
    final board = _rect(tester, LessonScriptKeys.board);
    expect(board.width, greaterThanOrEqualTo(0.8 * _short.width));
    // Rolando a página, a lista inteira aparece acima do rodapé.
    await tester.drag(find.byKey(LessonScriptKeys.page), const Offset(0, -400));
    await _settle(tester);
    expect(
      _rect(tester, LessonScriptKeys.moveList).bottom,
      lessThanOrEqualTo(footer),
    );
    expect(_rect(tester, LessonScriptKeys.moveList).height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('livro só na posição com curiosidade; o título fica no mesmo '
      'lugar com ou sem ele', (tester) async {
    await _open(tester, _tall);
    expect(find.byKey(LessonScriptKeys.bookButton), findsOneWidget);
    final title = tester.getTopLeft(find.text('Oposição distante'));
    expect(title.dx, lessThan(_tall.width / 4));
    await _open(tester, _tall, stage: 1);
    expect(find.byKey(LessonScriptKeys.bookButton), findsNothing);
    expect(tester.getTopLeft(find.text('Oposição distante')), title);
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
    expect(find.text('Próxima etapa'), findsOneWidget);
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
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    // ⏭ avança mesmo pausada.
    final tick = s.cubit.state.demo!.tick;
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.demo?.tick, isNot(tick));
    await _until(tester, s, ScriptPhase.fimEtapa);
    expect(s.cubit.state.demo?.ended, isTrue);
    expect(find.byKey(LessonScriptKeys.demoRepeat), findsOneWidget);
    expect(find.byKey(LessonScriptKeys.demoToggle), findsNothing);
    expect(find.byKey(LessonScriptKeys.demoStepBack), findsNothing);
    expect(find.text('Próxima etapa'), findsOneWidget);
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

  testWidgets('teoria (etapa 1): ← quando há volta, ⏸ e o ⏭ com anel, sem ↻ '
      'nem ⏮; a fala passa sozinha e a pergunta espera o aluno', (
    tester,
  ) async {
    final s = await _open(tester, _tall, autoPlay: true);
    expect(s.cubit.state.stageId, 'ideia');
    expect(s.cubit.state.demo?.full, isFalse);
    expect(find.byKey(LessonScriptKeys.demoToggle), findsOneWidget);
    expect(find.byKey(LessonScriptKeys.demoRing), findsOneWidget);
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
    expect(find.byKey(LessonScriptKeys.demoRing), findsNothing);
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
