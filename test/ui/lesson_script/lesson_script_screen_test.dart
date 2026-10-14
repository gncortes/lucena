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
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';
import 'package:lucena/ui/lesson_script/widgets/lesson_script_screen.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';
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
  return _Setup(cubit, voice);
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
        // Balão abaixo da barra (56 dp), com ao menos 2 dp de folga.
        final speech = _rect(tester, LessonScriptKeys.speech);
        expect(speech.top, greaterThanOrEqualTo(56 + 2 - 0.5));
        // Tabuleiro centralizado na altura quando cabe; na tela baixa, logo
        // abaixo da fala.
        final board = _rect(tester, LessonScriptKeys.board);
        final page = _rect(tester, LessonScriptKeys.page);
        if (size == _tall) {
          expect(board.center.dy, closeTo(page.center.dy, 1));
        } else {
          expect(board.top, greaterThan(speech.bottom));
        }
        expect(find.text('Continuar'), findsOneWidget);
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

      testWidgets('balão: duas linhas no mínimo; sobe antes de empurrar; '
          'na tela baixa, corta em 2 linhas', (tester) async {
        await _open(tester, size, texts: {'e1': 'Curto.', 'e2': _long});
        final short = _rect(tester, LessonScriptKeys.speech);
        final lines = size.height < 700 ? 2 * 12 * 1.25 : 2 * 15 * 1.25;
        final pad = size.height < 700 ? 20.0 : 28.0;
        expect(short.height, closeTo(lines + pad, 1.5));
        final boardTop = _rect(tester, LessonScriptKeys.board).top;
        await _tap(tester, LessonScriptKeys.primary);
        final grown = _rect(tester, LessonScriptKeys.speech);
        final board = _rect(tester, LessonScriptKeys.board);
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byKey(LessonScriptKeys.speech),
            matching: find.byType(Text),
          ),
        );
        if (size == _tall) {
          // Três linhas: o balão sobe no espaço de cima e o tabuleiro fica
          // no centro.
          expect(grown.height, greaterThan(short.height));
          final page = _rect(tester, LessonScriptKeys.page);
          expect(board.center.dy, closeTo(page.center.dy, 1));
          expect(grown.top, lessThan(short.top));
          expect(text.maxLines, isNull);
        } else {
          // Tela baixa: 2 linhas com reticências, letra 12; o tabuleiro não
          // se mexe (a fala inteira abre no clique).
          expect(grown.height, closeTo(short.height, 0.5));
          expect(board.top, closeTo(boardTop, 0.5));
          expect(text.maxLines, 2);
          expect(text.overflow, TextOverflow.ellipsis);
          expect(text.style?.fontSize, 12);
        }
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
    await s.cubit.onMove('d3c3');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.refutacao);
    expect(find.text('Continuar'), findsOneWidget);
    await _tap(tester, LessonScriptKeys.primary);
    expect(s.cubit.state.phase, ScriptPhase.livrePerdido);
    expect(find.byKey(LessonScriptKeys.primary), findsNothing);
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
    await s.cubit.onMove('g3g2');
    await _settle(tester);
    expect(s.cubit.state.phase, ScriptPhase.livreFim);
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
    // O `_open` já passou 1 s.
    await tester.pump(read - const Duration(milliseconds: 1100));
    expect(s.cubit.state.speech, first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(s.cubit.state.speech, isNot(first));
    expect(s.cubit.state.demo!.ended, isTrue);
    await _settle(tester);
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
