import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_voice.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/domain/models/lesson_video_progress.dart';
import 'package:lucena/domain/use_cases/lesson_video_converter.dart';
import 'package:lucena/domain/use_cases/video_timeline.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/lesson_video_keys.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:lucena/ui/lesson_video/view_models/lesson_video_cubit.dart';
import 'package:lucena/ui/lesson_video/widgets/lesson_video_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_center.dart';
import '../../../testing/fakes/fake_lesson_voice_repository.dart';
import '../../../testing/fakes/fake_lesson_script_repository.dart';
import '../../../testing/fakes/fake_lesson_video_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_video_interruptions_repository.dart';
import '../../../testing/script_fixture.dart';
import '../../../testing/test_app.dart';

// Testes que quebram antes (RED) da tela da aula em vídeo.
//
// Gaps de `docs/fluxos/aula-video.md` ("Matriz de gaps", Vídeo N), lote de
// cada um em `docs/tasks/T-aula-video-contrato.md` ("Testes que quebram
// antes" e "Lotes"). O nome do teste é o gap. `testWidgets` só aceita
// `skip: bool`, então os casos ficam num `group` por lote com o motivo no
// `skip`; quando o lote entra, o skip do grupo sai (e o corpo vira o teste).

/// Um roteiro que nunca chega (carregando para sempre).
class _HangingScripts implements LessonScriptRepository {
  final _never = Completer<LessonScript>();

  @override
  Future<LessonScript> script(String path) => _never.future;

  @override
  Future<ScriptTexts> texts(String lessonId, String language) async =>
      ScriptTexts.empty;
}

/// Um roteiro que falha na primeira vez e abre na segunda.
class _FlakyScripts implements LessonScriptRepository {
  final _ok = FakeLessonScriptRepository(scriptFixture(), scriptTexts());
  int calls = 0;

  @override
  Future<LessonScript> script(String path) async {
    calls++;
    if (calls == 1) throw StateError('roteiro ilegível');
    return _ok.script(path);
  }

  @override
  Future<ScriptTexts> texts(String lessonId, String language) =>
      _ok.texts(lessonId, language);
}

typedef _Pumped = ({
  LessonVideoCubit cubit,
  SettingsCubit settings,
  FakeSettingsRepository settingsRepo,
  FakeLessonVideoRepository videos,
});

Future<_Pumped> _pump(
  WidgetTester tester, {
  AparelhoA8 aparelho = const AparelhoA8(Size(412, 917)),
  String stage = 'ideia',
  bool autoplay = false,
  bool accessible = false,
  bool waitStart = true,
  LessonScriptRepository? scripts,
  FakeLessonVideoRepository? videos,
  FakeNow? now,
  FakeLessonVoiceRepository? voice,
}) async {
  final padding = FakeViewPadding(top: aparelho.status, bottom: aparelho.nav);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = aparelho.size
    ..viewPadding = padding
    ..padding = padding;
  addTearDown(tester.view.reset);

  final settingsRepo = FakeSettingsRepository(const AppSettings());
  final settings = SettingsCubit(
    settingsRepo,
    languages: AppLanguage.selectable,
  );
  addTearDown(settings.close);
  await settings.load();
  final repo = videos ?? FakeLessonVideoRepository();
  final cubit = LessonVideoCubit(
    scripts:
        scripts ?? FakeLessonScriptRepository(scriptFixture(), scriptTexts()),
    videos: repo,
    interruptions: FakeVideoInterruptionsRepository(),
    now: now ?? FakeNow(DateTime(2026, 11, 23, 10)),
    lessonId: 'pawns.test',
    partId: 'distant',
    scriptPath: 'roteiro.json',
    stage: stage,
    autoplay: autoplay,
    ticker: (_, _) => null,
    voice: voice,
  );
  addTearDown(cubit.close);
  Widget screen = BlocProvider.value(
    value: cubit,
    child: const LessonVideoScreen(title: 'Oposição distante'),
  );
  if (accessible) {
    final inner = screen;
    screen = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
        child: inner,
      ),
    );
  }
  await tester.pumpWidget(
    TestApp(locale: const Locale('pt'), settingsCubit: settings, child: screen),
  );
  if (waitStart) {
    await cubit.start();
  } else {
    unawaited(cubit.start());
  }
  await tester.pump(const Duration(milliseconds: 300));
  return (
    cubit: cubit,
    settings: settings,
    settingsRepo: settingsRepo,
    videos: repo,
  );
}

/// A mesma linha do tempo que o cubit monta (modo leitura).
VideoTimeline _reference(String stage) => VideoTimeline.layout(
  LessonVideoConverter.convert(
    scriptFixture(),
    ScriptTexts(scriptTexts()),
    language: 'pt',
  ).stage(stage).lines,
  pace: VideoPace.reading,
);

Set<Shape> _boardShapes(WidgetTester tester) =>
    tester.widget<Chessboard>(find.byType(Chessboard)).shapes;

/// O progresso salvo com todas as perguntas da Teoria respondidas, no 0:00.
FakeLessonVideoRepository _allAnswered() {
  final ref = _reference('ideia');
  return FakeLessonVideoRepository(
    progress: {
      'pawns.test.distant.ideia': VideoProgress(
        line: ref.lines.first.line.id,
        resolved: {for (final g in ref.gates) ref.lines[g.line].line.id},
      ),
    },
  );
}

/// O centro vertical do corpo (abaixo da app bar) e o tabuleiro.
({Rect board, double bodyCenter}) _boardInBody(WidgetTester tester) {
  final board = maiorTabuleiro(tester);
  final top = tester.getRect(find.byType(LucenaAppBar)).bottom;
  final bottom = tester.getRect(find.byKey(LessonVideoKeys.screen)).bottom;
  return (board: board, bodyCenter: (top + bottom) / 2);
}

String _mmss(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

const _labeledButtons = [
  LessonVideoKeys.glossaryButton,
  LessonScriptKeys.marksToggle,
  LessonVideoKeys.back10,
  LessonVideoKeys.playPause,
  LessonVideoKeys.forward10,
  LessonVideoKeys.captions,
];

void _expectTarget(WidgetTester tester, Key key) {
  final size = tester.getSize(find.byKey(key));
  expect(size.width, greaterThanOrEqualTo(48), reason: '$key $size');
  expect(size.height, greaterThanOrEqualTo(48), reason: '$key $size');
}

void main() {
  group('gaps L1', () {
    testWidgets(
      'Vídeo 1: toque ou arraste no tabuleiro fora da sua vez → nada: o '
      'vídeo não pausa nem move peça',
      (tester) async {
        final p = await _pump(tester, stage: 'demos');
        p.cubit.play();
        await tester.pump();
        final fen = p.cubit.state.frame!.fen;
        final position = p.cubit.state.position;
        expect(p.cubit.state.playing, isTrue);

        final board = find.byKey(LessonVideoKeys.board);
        await tester.tap(board);
        await tester.pump();
        // d3 (rei branco) → e4, pelo arraste.
        final rect = tester.getRect(board);
        final square = rect.width / 8;
        final d3 = rect.topLeft + Offset(3.5 * square, 5.5 * square);
        await tester.dragFrom(d3, Offset(square, -square));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tapAt(d3);
        await tester.pump();
        await tester.tapAt(d3 + Offset(square, -square));
        await tester.pump(const Duration(milliseconds: 300));

        expect(p.cubit.state.playing, isTrue);
        expect(p.cubit.state.frame!.fen, fen);
        expect(p.cubit.state.position, position);
        final game = tester
            .widget<Chessboard>(find.byType(Chessboard))
            .controller
            .game;
        expect(game.fen, fen, reason: 'nenhuma peça mexeu no tabuleiro');
      },
    );

    testWidgets(
      'Vídeo 5: arrastar atravessando Teoria/Demonstração → impossível: '
      'cada etapa tem a sua barra; o fim da Teoria mostra o rodapé',
      (tester) async {
        // As perguntas da Teoria já respondidas: a barra vai até o fim.
        final p = await _pump(tester, videos: _allAnswered());
        final total = p.cubit.state.total;
        expect(find.byKey(LessonVideoKeys.endRestart), findsNothing);

        await tester.drag(
          find.byKey(LessonVideoKeys.bar),
          const Offset(2000, 0),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(p.cubit.state.position, total);
        expect(p.cubit.state.ended, isTrue);
        expect(p.cubit.stage, 'ideia', reason: 'a etapa não muda');
        expect(p.cubit.state.total, total);
        expect(find.byKey(LessonVideoKeys.endRestart), findsOneWidget);
        expect(find.byKey(LessonVideoKeys.playPause), findsNothing);
      },
    );

    testWidgets(
      'Vídeo 13: marcações desligadas → some tudo do tabuleiro (casas, '
      'setas, círculos); preferência lessonMarks atual',
      (tester) async {
        final p = await _pump(tester);
        // A 2ª fala da Teoria marca d3.
        final ref = _reference('ideia');
        p.cubit.seek(ref.timeOf(ref.lines[1].line.id, 0.5)!);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_boardShapes(tester), isNotEmpty, reason: 'pré-condição');

        await tester.tap(find.byKey(LessonScriptKeys.marksToggle));
        await tester.pump(const Duration(milliseconds: 300));

        expect(_boardShapes(tester), isEmpty);
        expect(p.settings.state?.lessonMarks, isFalse);
        expect(p.settingsRepo.saved.last.lessonMarks, isFalse);
      },
    );

    testWidgets(
      'Vídeo 36: tela grande (412×915, 414×896) → tabuleiro na largura '
      'toda, no centro',
      (tester) async {
        for (final aparelho in const [
          AparelhoA8(Size(412, 917)),
          AparelhoA8(Size(412, 915)),
          AparelhoA8(Size(414, 896)),
        ]) {
          await _pump(tester, aparelho: aparelho);
          final m = _boardInBody(tester);
          expect(
            m.board.width,
            aparelho.size.width,
            reason: '$aparelho: ${m.board}',
          );
          expect(
            m.board.center.dy,
            closeTo(m.bodyCenter, 4),
            reason: '$aparelho: ${m.board} x corpo ${m.bodyCenter}',
          );
        }
      },
    );

    testWidgets(
      'Vídeo 37: leitor de tela → barra é Slider com "m:ss de m:ss"',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final p = await _pump(tester, stage: 'demos', accessible: true);
        p.cubit.seek(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Slider), findsOneWidget);
        expect(
          find.semantics.byValue(
            '${_mmss(p.cubit.state.position)} de '
            '${_mmss(p.cubit.state.total)}',
          ),
          findsOne,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'Vídeo 37: leitor de tela → botões com rótulo; controles do player com '
      'alvo ≥ 48',
      (tester) async {
        await _pump(tester, accessible: true);
        for (final key in _labeledButtons) {
          final button = tester.widget<IconButton>(find.byKey(key));
          expect(button.tooltip, isNotEmpty, reason: '$key sem rótulo');
        }
        expect(find.bySemanticsLabel('Velocidade'), findsOneWidget);
        for (final key in [
          LessonVideoKeys.back10,
          LessonVideoKeys.playPause,
          LessonVideoKeys.forward10,
          LessonVideoKeys.captions,
          LessonVideoKeys.rate,
          LessonVideoKeys.glossaryButton,
        ]) {
          _expectTarget(tester, key);
        }
      },
    );

    testWidgets(
      'Vídeo 43: carregando o vídeo/áudio → aviso de carregando e play '
      'indisponível',
      (tester) async {
        final p = await _pump(
          tester,
          scripts: _HangingScripts(),
          waitStart: false,
        );
        expect(p.cubit.state.status, LessonVideoStatus.loading);
        expect(find.byKey(LessonVideoKeys.loading), findsOneWidget);
        final play = find.byKey(LessonVideoKeys.playPause);
        if (play.evaluate().isNotEmpty) {
          expect(tester.widget<IconButton>(play).onPressed, isNull);
        }
        p.cubit.play();
        expect(p.cubit.state.playing, isFalse);
      },
    );

    testWidgets(
      'Vídeo 44: roteiro ausente ou ilegível → aviso de lição indisponível; '
      'o botão do aviso recarrega',
      (tester) async {
        final scripts = _FlakyScripts();
        final p = await _pump(tester, scripts: scripts);
        expect(p.cubit.state.status, LessonVideoStatus.failed);
        expect(find.byKey(LessonVideoKeys.unavailable), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byKey(LessonVideoKeys.unavailable),
            matching: find.byType(TextButton),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(scripts.calls, 2);
        expect(p.cubit.state.status, LessonVideoStatus.ready);
        expect(find.byKey(LessonVideoKeys.unavailable), findsNothing);
        expect(find.byKey(LessonVideoKeys.board), findsOneWidget);
      },
    );
  });

  group('gaps L1 (pendente: geometria em 360)', () {
    testWidgets(
      'Vídeo 35: tela pequena (360×740, 360×800) → tabuleiro encolhe e fica '
      'no centro (~340 em 360×740)',
      (tester) async {
        for (final aparelho in const [
          AparelhoA8(Size(360, 740)),
          AparelhoA8(Size(360, 800)),
        ]) {
          await _pump(tester, aparelho: aparelho);
          final m = _boardInBody(tester);
          debugPrint('$aparelho: lado do tabuleiro ${m.board.width}');
          if (aparelho.size.height == 740) {
            expect(m.board.width, closeTo(340, 8), reason: '$aparelho');
          }
          expect(
            m.board.center.dy,
            closeTo(m.bodyCenter, 4),
            reason: '$aparelho: ${m.board} x corpo ${m.bodyCenter}',
          );
        }
      },
    );
  }, skip: 'L1: em 360×740 o lado medido é 316 (contrato: 340 ± 8)');

  group(
    'gaps L1 (pendente: alvo do botão de marcações)',
    () {
      testWidgets('Vídeo 37: leitor de tela → todo botão com alvo ≥ 48', (
        tester,
      ) async {
        await _pump(tester, accessible: true);
        for (final key in [..._labeledButtons, LessonVideoKeys.rate]) {
          _expectTarget(tester, key);
        }
      });
    },
    skip:
        'L1: LessonScriptKeys.marksToggle mede 48×44 (a faixa do Viktor '
        'tem 44 de altura)',
  );

  group('gaps L1 (pendente: leitor de tela não segura o autoplay)', () {
    testWidgets('Vídeo 37: leitor de tela → não começa sozinho', (
      tester,
    ) async {
      // Como o router: cubit com autoplay (padrão).
      final p = await _pump(tester, autoplay: true, accessible: true);
      expect(p.cubit.state.playing, isFalse);
    });
  }, skip: 'L1: o cubit toca com autoplay sem olhar accessibleNavigation');

  group('gaps L1 (pendente: termo e casa do balão)', () {
    testWidgets('Vídeo 37: leitor de tela → termo e casa são links', (
      tester,
    ) async {
      // Assert: LessonVideoKeys.term(id) e LessonVideoKeys.square(sq) com
      // semântica de link.
    });
  }, skip: 'L5: termo e casa sublinhados no balão ainda não existem');

  group(
    'gaps L1 (pendente: carregando sem esqueleto)',
    () {
      testWidgets(
        'Vídeo 43: carregando o vídeo/áudio → esqueleto no balão, tabuleiro na '
        'posição inicial',
        (tester) async {
          await _pump(tester, scripts: _HangingScripts(), waitStart: false);
          expect(find.byKey(LessonVideoKeys.caption), findsOneWidget);
          expect(find.byKey(LessonVideoKeys.board), findsOneWidget);
        },
      );
    },
    skip:
        'L1: carregando mostra só o spinner (sem balão-esqueleto nem '
        'tabuleiro; a posição inicial depende do roteiro que ainda não chegou)',
  );

  group(
    'gaps L1 (pendente: texto do aviso de indisponível)',
    () {
      testWidgets(
        'Vídeo 44: roteiro ausente ou ilegível → aviso de lição indisponível '
        'com "Tentar de novo"',
        (tester) async {
          await _pump(tester, scripts: _FlakyScripts());
          expect(
            find.descendant(
              of: find.byKey(LessonVideoKeys.unavailable),
              matching: find.text('Tentar de novo'),
            ),
            findsOneWidget,
          );
        },
      );
    },
    skip:
        'L1: o aviso é só um botão "Tocar" (lessonVideoPlay), sem texto '
        'de lição indisponível nem "Tentar de novo"',
  );

  group('gaps L2', () {
    testWidgets(
      'Vídeo 25: sua vez esperando o lance → vídeo parado, tabuleiro com '
      'contorno, play e ±10 esmaecidos',
      (tester) async {
        // Arrange: tocar até a pergunta. Assert: LessonVideoKeys.yourMove;
        // play, back10 e forward10 com opacidade 38 %.
      },
    );
  }, skip: 'L2: sua vez (perguntas) ainda não existe');

  group('gaps L3', () {
    testWidgets(
      'Vídeo 12: legenda desligada → setas e marcas ficam; preferência salva',
      (tester) async {
        final p = await _pump(tester);
        final ref = _reference('ideia');
        p.cubit.seek(ref.timeOf(ref.lines[1].line.id, 0.5)!);
        await tester.pump(const Duration(milliseconds: 300));
        final before = _boardShapes(tester);
        expect(before, isNotEmpty, reason: 'pré-condição');

        await tester.tap(find.byKey(LessonVideoKeys.captions));
        await tester.pump(const Duration(milliseconds: 300));

        expect(p.cubit.state.captions, isFalse);
        expect(_boardShapes(tester), before);
        expect(p.videos.current.captions, isFalse);
      },
    );
  });

  group('L4: legenda desligada e voz', () {
    testWidgets(
      'Vídeo 12: legenda desligada → "Legenda desligada" no lugar do balão',
      (tester) async {
        await _pump(tester);
        await tester.tap(find.byKey(LessonVideoKeys.captions));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(LessonVideoKeys.captionsOff), findsOneWidget);
        expect(find.text('Legenda desligada'), findsOneWidget);
        expect(find.byKey(LessonVideoKeys.caption), findsNothing);
      },
    );

    testWidgets(
      'Vídeo 10: sem o pacote → "Sem áudio." e "Baixar a voz" baixa',
      (tester) async {
        final voice = FakeLessonVoiceRepository()
          ..nextDownload = const VoicePackFailed(VoicePackFailure.network);
        final p = await _pump(tester, voice: voice);
        expect(p.cubit.state.voice, VideoVoice.missing);
        expect(find.byKey(LessonVideoKeys.voiceNotice), findsOneWidget);
        expect(
          find.textContaining('Sem áudio.', findRichText: true),
          findsOneWidget,
        );

        expect(find.text('Baixar a voz'), findsOneWidget);
        await tester.tap(find.byKey(LessonVideoKeys.voiceNoticeAction));
        await tester.pump(const Duration(milliseconds: 300));
        expect(voice.downloads, ['pawns.test']);
        // Vídeo 11: falhou → "Não deu para baixar a voz." e "Tentar novamente".
        expect(find.text('Não deu para baixar a voz.'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
      },
    );

    testWidgets('voz desligada nos ajustes → leitura sem aviso', (
      tester,
    ) async {
      await _pump(tester, voice: FakeLessonVoiceRepository(on: false));
      expect(find.byKey(LessonVideoKeys.voiceNotice), findsNothing);
    });
  });

  group('gaps L5', () {
    testWidgets(
      'Vídeo 2: toque numa casa sublinhada do balão → a casa pisca no '
      'tabuleiro (square_flash), o vídeo segue',
      (tester) async {
        // Act: tap em LessonVideoKeys.square('c8').
        // Assert: square_flash em c8 e o vídeo continua tocando.
      },
    );

    testWidgets(
      'Vídeo 17: livro → Glossário → voltar → pausa; ao voltar continua só '
      'se tocava',
      (tester) async {
        // Act: tocar glossaryButton tocando; voltar. Assert: pausou ao abrir
        // e voltou a tocar. Repetir pausado: continua pausado.
      },
    );

    testWidgets(
      'Vídeo 18: tocar termo sublinhado → pausa; Glossário com a busca = '
      'termo e folha da Wikipédia; fechar a folha deixa a lista filtrada',
      (tester) async {
        // Act: tap em LessonVideoKeys.term(id). Assert: GlossaryKeys.search
        // com o termo, folha aberta; fechar → lista filtrada; X limpa.
      },
    );

    testWidgets('Vídeo 19: termo sem internet → folha do termo com definição + '
        '"Sem internet…"', (tester) async {
      // Arrange: conectividade off. Act: tocar termo.
      // Assert: GlossaryKeys.sheet com definição e GlossaryKeys.offline.
    });

    testWidgets(
      'Vídeo 21: busca no Glossário sem resultado → estado vazio "Nenhum '
      'termo com …"',
      (tester) async {
        // Act: digitar termo inexistente em GlossaryKeys.search.
        // Assert: GlossaryKeys.empty com o texto da busca.
      },
    );
  }, skip: 'L5: Glossário (tela, busca, folhas) e termo/casa sublinhados');

  group('gaps L6', () {
    testWidgets(
      'Vídeo 33: fim da Demonstração → rodapé → Prática com a fala de '
      'entrada',
      (tester) async {
        // Arrange: Demonstração no fim. Act: tocar LessonVideoKeys.endNext.
        // Assert: tela da Prática atual com a fala de entrada.
      },
    );
  }, skip: 'L6: ligação do vídeo com a Prática');
}
