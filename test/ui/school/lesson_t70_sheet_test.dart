import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/engine_fallback.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/typing_dots.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_part_widgets.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// A folha do aprendizado (T70, lote 2): o enunciado em A1/A2/A3, o rodapé
/// ✕ ⏮ ⏭ ↔ Ver resposta, o estado correto pelos três caminhos, o ramo
/// jogável e o motor. PT-BR, tema claro, fonte 1,0; 360x740 e 412x917.
void main() {
  const id = 'test.t70';
  const start = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
  const afterE3 = '4k3/8/8/8/8/4P3/8/4K3 b - - 0 1';
  const afterKd1 = '4k3/8/8/8/8/8/4P3/3K4 b - - 1 1';

  const texts = LessonTexts({
    'test.t70.t': [
      'Leve o peão ao destino. As brancas jogam e o rei preto está perto: pense no plano antes de mexer e escolha o lance que ajuda o rei branco. Olhe para as casas à frente do peão, para a distância entre os dois reis e para quem tem a oposição. Lembre que o peão só vence quando o rei branco chega primeiro à casa de promoção e o rei preto não consegue bloquear o caminho do peão até o fim da coluna. Conte os lances de cada rei com calma, casa por casa, e compare com os lances que o peão precisa para andar até a última fileira do tabuleiro. Se o rei preto chegar antes à frente do peão, a partida termina empatada; se o rei branco chegar antes, o peão passa e a promoção sai sem problema nenhum para as brancas.',
    ],
    'test.t70.talk': ['Explicação completa do plano.'],
    'test.t70.talk.short': ['Curta.'],
    'test.t70.t.mistake.e1d1': ['O rei sai da frente.\nAs pretas respondem.'],
    'test.t70.end': ['Fim.'],
  });

  const think = ThinkStep(
    id: 't',
    fen: start,
    accept: {'e2e3'},
    mistakes: {'e1d1': StepMistake(say: 'step.t.mistake.e1d1')},
  );
  const talk = TalkStep(id: 'talk', fen: afterE3);
  const wrongDemo = DemoStep(
    id: 'dw',
    fen: afterKd1,
    wrong: true,
    line: [
      DemoMove(uci: 'e8d8'),
      DemoMove(uci: 'd1c1'),
    ],
  );
  const end = TalkStep(id: 'end', fen: start);
  const steps = <LessonStep>[think, talk, wrongDemo, end];

  // As posições do ramo do erro, só as peças.
  const start0 = '4k3/8/8/8/8/8/4P3/4K3';
  const kd1 = '4k3/8/8/8/8/8/4P3/3K4';
  const kd8 = '3k4/8/8/8/8/8/4P3/3K4';
  const kc1 = '3k4/8/8/8/8/8/4P3/2K5';
  const kd2c8 = '2k5/8/8/8/8/8/3KP3/8';

  const sizes = [Size(360, 740), Size(412, 917)];

  late FakeSchoolProgressRepository progress;
  late Uri? opened;

  // A fonte do app (Roboto), não a de teste larga demais para o rodapé.
  setUpAll(Goldens.loadFonts);

  setUp(() {
    progress = FakeSchoolProgressRepository();
    opened = null;
  });

  Move mv(String uci) => Move.parse(uci)!;

  EngineFallback engine(
    int score, {
    bool fail = false,
    String reply = 'e8d8',
  }) => EngineFallback(
    evaluate: (_, _) async =>
        fail ? throw StateError('x') : Evaluation(centipawns: score),
    bestMove: (p) async => mv(reply),
  );

  Future<LessonCubit> pump(
    WidgetTester tester, {
    required Size size,
    List<LessonStep> lessonSteps = steps,
    EngineFallback? motor,
    bool collapse = true,
    bool typing = false,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(
        course: Course(
          modules: [
            CourseModule(
              id: 'test',
              lessons: [Lesson(id: id, steps: lessonSteps)],
            ),
          ],
        ),
        texts: texts,
      ),
      progress: progress,
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
      holdDelay: Duration.zero,
      practiceV2: true,
      typingDelay: typing ? const Duration(seconds: 30) : Duration.zero,
      engine: motor,
    );
    addTearDown(cubit.close);
    await cubit.load(id, 'pt');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => BlocProvider.value(
            value: cubit,
            child: LessonScreen(engine: motor),
          ),
        ),
        GoRoute(
          path: '/setup',
          builder: (_, state) {
            opened = state.uri;
            return const Scaffold(body: Text('Configurar partida'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    if (collapse) {
      // A folha abre sozinha e recolhe depois do tempo de leitura.
      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();
    }
    return cubit;
  }

  String placement(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(LessonKeys.board))
      .controller
      .fen
      .split(' ')
      .first;

  bool forwardEnabled(WidgetTester tester) =>
      tester
          .widget<IconButton>(find.byKey(LessonKeys.variationForward))
          .onPressed !=
      null;

  Future<void> dragMove(
    WidgetTester tester,
    String from,
    String to, {
    bool settle = true,
  }) async {
    final board = tester.widget<Chessboard>(find.byKey(LessonKeys.board));
    final rect = tester.getRect(find.byKey(LessonKeys.board));
    final side = board.orientation;
    await tester.tapAt(squareCenter(rect, from, orientation: side));
    await tester.pump();
    await tester.tapAt(squareCenter(rect, to, orientation: side));
    // Com os três pontos na tela nada assenta: só avança o relógio.
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final size in sizes) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    group('A1/A2/A3 $tag', () {
      testWidgets('A1: abre com o enunciado e os links', (tester) async {
        await pump(tester, size: size, collapse: false);
        expect(
          find.textContaining('Leve o peão ao destino.', findRichText: true),
          findsOneWidget,
        );
        expect(find.byKey(LessonKeys.showAnswerLink), findsOneWidget);
        expect(find.byKey(LessonKeys.yourTurnLine), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('A2: recolhida mostra "Sua vez" e os dois links', (
        tester,
      ) async {
        await pump(tester, size: size);
        expect(find.text('Sua vez: jogue com as brancas.'), findsOneWidget);
        expect(
          find.textContaining('Leve o peão ao destino.', findRichText: true),
          findsNothing,
        );
        expect(find.text('Ver enunciado completo'), findsOneWidget);
        expect(find.text('Ver resposta'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('A3: o link expande o enunciado e "Ocultar" recolhe', (
        tester,
      ) async {
        await pump(tester, size: size);
        await tester.tap(find.byKey(LessonKeys.fullStatementLink));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Leve o peão ao destino.', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Ocultar enunciado'), findsOneWidget);
        expect(find.text('Ver enunciado completo'), findsNothing);
        // O texto cresceu: o link desceu para além do rodapé; rola até ele.
        await tester.dragUntilVisible(
          find.byKey(LessonKeys.fullStatementLink),
          find
              .descendant(
                of: find.byKey(LessonKeys.scroll),
                matching: find.byType(Scrollable),
              )
              .first,
          const Offset(0, -80),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(LessonKeys.fullStatementLink));
        await tester.pumpAndSettle();
        expect(find.text('Ver enunciado completo'), findsOneWidget);
        expect(
          find.textContaining('Leve o peão ao destino.', findRichText: true),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('os links têm alvo de 48 dp', (tester) async {
        await pump(tester, size: size);
        for (final key in [
          LessonKeys.fullStatementLink,
          LessonKeys.showAnswerLink,
        ]) {
          expect(
            tester.getSize(find.byKey(key)).height,
            greaterThanOrEqualTo(48),
          );
        }
      });
    });

    group('rodapé $tag', () {
      testWidgets('pensando: ✕ ⏮ ⏭, com o ⏭ apagado até o correto', (
        tester,
      ) async {
        await pump(tester, size: size);
        expect(find.byKey(LessonKeys.lessonExitButton), findsOneWidget);
        expect(find.byKey(LessonKeys.variationBack), findsOneWidget);
        expect(forwardEnabled(tester), isFalse);
        expect(find.byKey(LessonKeys.showAnswerButton), findsNothing);
        for (final key in [
          LessonKeys.lessonExitButton,
          LessonKeys.variationBack,
          LessonKeys.variationForward,
        ]) {
          final box = tester.getSize(find.byKey(key));
          expect(box.width, greaterThanOrEqualTo(48));
          expect(box.height, greaterThanOrEqualTo(48));
        }
      });

      testWidgets('erro com ramo: Ver resposta ⏮ ⏭ no lugar do ✕', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size);
        await dragMove(tester, 'e1', 'd1');
        expect(cubit.state.thinkPlayed, 'e1d1');
        expect(find.byKey(LessonKeys.showAnswerButton), findsOneWidget);
        expect(find.byKey(LessonKeys.lessonExitButton), findsNothing);
        expect(find.byKey(LessonKeys.variationBack), findsOneWidget);
        expect(find.byKey(LessonKeys.variationForward), findsOneWidget);
        expect(
          tester.getSize(find.byKey(LessonKeys.showAnswerButton)).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Ver resposta do rodapé leva ao estado correto', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size);
        await dragMove(tester, 'e1', 'd1');
        await tester.tap(find.byKey(LessonKeys.showAnswerButton));
        await tester.pumpAndSettle();
        expect(cubit.state.correct, isTrue);
        expect(find.byKey(LessonKeys.correctTitle), findsOneWidget);
        expect(find.byKey(LessonKeys.lessonExitButton), findsOneWidget);
        expect(forwardEnabled(tester), isTrue);
        expect(find.byKey(LessonKeys.showAnswerButton), findsNothing);
      });
    });

    group('estado correto $tag', () {
      Future<void> check(WidgetTester tester, LessonCubit cubit) async {
        expect(cubit.state.correct, isTrue);
        expect(cubit.state.fen, afterE3);
        expect(find.byKey(LessonKeys.correctTitle), findsOneWidget);
        expect(find.text('Curta.'), findsOneWidget);
        expect(find.byKey(LessonKeys.fullExplanationLink), findsOneWidget);
        expect(find.text('Ver explicação completa'), findsOneWidget);
        expect(find.text('Alternativas que falham'), findsOneWidget);
        expect(
          find.byKey(LessonKeys.failedAlternative('e1d1')),
          findsOneWidget,
        );
        expect(find.byKey(LessonKeys.lessonExitButton), findsOneWidget);
        expect(forwardEnabled(tester), isTrue);
        expect(tester.takeException(), isNull);
      }

      testWidgets('acertando o lance', (tester) async {
        final cubit = await pump(tester, size: size);
        await dragMove(tester, 'e2', 'e3');
        await check(tester, cubit);
      });

      testWidgets('erro e depois Ver resposta', (tester) async {
        final cubit = await pump(tester, size: size);
        await dragMove(tester, 'e1', 'd1');
        await tester.tap(find.byKey(LessonKeys.showAnswerButton));
        await tester.pumpAndSettle();
        await check(tester, cubit);
        // O erro que o aluno cometeu já aparece como visto.
        expect(find.byKey(LessonKeys.alreadySeen('e1d1')), findsOneWidget);
      });

      testWidgets('Ver resposta direto', (tester) async {
        final cubit = await pump(tester, size: size);
        await tester.tap(find.byKey(LessonKeys.showAnswerLink));
        await tester.pumpAndSettle();
        await check(tester, cubit);
        expect(find.byKey(LessonKeys.alreadySeen('e1d1')), findsNothing);
      });

      testWidgets('"Ver explicação completa" troca a curta pela completa', (
        tester,
      ) async {
        await pump(tester, size: size);
        await dragMove(tester, 'e2', 'e3');
        await tester.ensureVisible(find.byKey(LessonKeys.fullExplanationLink));
        await tester.tap(find.byKey(LessonKeys.fullExplanationLink));
        await tester.pumpAndSettle();
        expect(find.text('Explicação completa do plano.'), findsOneWidget);
        expect(find.byKey(LessonKeys.fullExplanationLink), findsNothing);
      });

      testWidgets('alternativa abre o ramo sem selo e ✕ volta na rolagem', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size);
        await dragMove(tester, 'e2', 'e3');
        final alt = find.byKey(LessonKeys.failedAlternative('e1d1'));
        final scrollable = find.descendant(
          of: find.byKey(LessonKeys.scroll),
          matching: find.byType(Scrollable),
        );
        double offset() =>
            tester.state<ScrollableState>(scrollable.first).position.pixels;
        await tester.dragUntilVisible(
          alt,
          scrollable.first,
          const Offset(0, -80),
        );
        await tester.pumpAndSettle();
        final before = offset();
        await tester.tap(alt);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.byKey(LessonKeys.variationExit), findsOneWidget);
        expect(find.byType(WrongLineBadge), findsNothing);
        expect(cubit.state.seen, contains('e1d1'));
        await tester.tap(find.byKey(LessonKeys.variationExit));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.byKey(LessonKeys.variationExit), findsNothing);
        expect(find.byKey(LessonKeys.correctTitle), findsOneWidget);
        expect(offset(), closeTo(before, 1));
        expect(tester.takeException(), isNull);
      });
    });

    group('erro e ramo $tag', () {
      testWidgets('o erro previsto abre o ramo com o selo "Lance errado"', (
        tester,
      ) async {
        await pump(tester, size: size);
        await dragMove(tester, 'e1', 'd1');
        // A refutação anda sozinha ao entrar (crit. 5).
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.byType(WrongLineBadge), findsWidgets);
        expect(find.text('Lance errado'), findsWidgets);
        expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
        expect(placement(tester), kd8);
        expect(tester.takeException(), isNull);
      });

      testWidgets('lance sem ramo e sem motor: aviso, sem ramo', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size);
        await dragMove(tester, 'e1', 'f1');
        expect(cubit.state.wrongNotice, isTrue);
        expect(find.byKey(LessonKeys.wrongMoveNotice), findsOneWidget);
        expect(find.text('Lance errado. Tente outro lance.'), findsOneWidget);
        expect(find.byType(WrongLineBadge), findsNothing);
        expect(find.byKey(LessonKeys.variationStrip), findsNothing);
        // Os dois links ficam e o aluno segue no passo de pensar.
        expect(find.byKey(LessonKeys.showAnswerLink), findsOneWidget);
        expect(find.byKey(LessonKeys.fullStatementLink), findsOneWidget);
        expect(cubit.state.step, 0);
        expect(placement(tester), start0);
      });

      testWidgets('motor com erro: snackbar acima do rodapé e a vez volta', (
        tester,
      ) async {
        final cubit = await pump(
          tester,
          size: size,
          motor: engine(0, fail: true),
        );
        await dragMove(tester, 'e1', 'f1');
        expect(cubit.state.engineErrors, 1);
        expect(find.byKey(LessonKeys.engineErrorSnack), findsOneWidget);
        expect(
          find.text('Aconteceu um erro inesperado. Tente novamente.'),
          findsOneWidget,
        );
        // Acima do rodapé, nunca por cima dele.
        final snack = tester.getRect(
          find.text('Aconteceu um erro inesperado. Tente novamente.'),
        );
        final footer = tester.getRect(find.byKey(LessonKeys.footer));
        expect(snack.bottom, lessThanOrEqualTo(footer.top + 1));
        expect(placement(tester), start0);
        expect(cubit.state.step, 0);
        expect(tester.takeException(), isNull);
        // O próximo lance chama o motor de novo, do zero.
        await dragMove(tester, 'e1', 'f1');
        expect(cubit.state.engineErrors, 2);
      });

      testWidgets('o motor pensando mostra os três pontos na folha', (
        tester,
      ) async {
        final gate = Completer<Evaluation?>();
        final cubit = await pump(
          tester,
          size: size,
          motor: EngineFallback(
            evaluate: (_, _) => gate.future,
            bestMove: (_) async => mv('e8d8'),
          ),
        );
        await dragMove(tester, 'e1', 'f1', settle: false);
        expect(cubit.state.typing, isTrue);
        expect(find.byKey(LessonKeys.sheetTyping), findsOneWidget);
        expect(find.byType(TypingDots), findsOneWidget);
        // Os pontos entram no lugar do enunciado/comentário, não somam.
        expect(find.byKey(LessonKeys.wrongMoveNotice), findsNothing);
        gate.complete(const Evaluation(centipawns: -500));
        await tester.pumpAndSettle();
        expect(find.byKey(LessonKeys.sheetTyping), findsNothing);
        expect(cubit.state.thinkPlayed, 'e1f1');
        expect(tester.takeException(), isNull);
      });

      testWidgets('o motor mantém o resultado: outro lance correto', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size, motor: engine(500));
        await dragMove(tester, 'e1', 'f1');
        await tester.pumpAndSettle();
        expect(cubit.state.correct, isTrue);
        expect(cubit.state.fen, afterE3);
        expect(find.byKey(LessonKeys.correctTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('o motor perde o resultado: o ramo abre com a resposta', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size, motor: engine(-500));
        await dragMove(tester, 'e1', 'f1');
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(cubit.state.engineLine, ['e1f1', 'e8d8']);
        expect(find.byType(WrongLineBadge), findsWidgets);
        expect(find.byKey(LessonKeys.showAnswerButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('ramo jogável $tag', () {
      // O ramo do erro: 1.Rd1 Rd8 2.Rc1 (e1d1, e8d8, d1c1). Depois da
      // refutação a vez é do aluno (brancas).
      Future<LessonCubit> enterBranch(
        WidgetTester tester, {
        EngineFallback? motor,
      }) async {
        final cubit = await pump(tester, size: size, motor: motor);
        await dragMove(tester, 'e1', 'd1');
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(placement(tester), kd8);
        return cubit;
      }

      testWidgets('9b: o lance da linha anda como o ⏭ e fecha a linha', (
        tester,
      ) async {
        await enterBranch(tester);
        await dragMove(tester, 'd1', 'c1');
        expect(placement(tester), kc1);
        expect(forwardEnabled(tester), isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('9b: o ⏮ volta e o lance da linha refaz a resposta', (
        tester,
      ) async {
        await enterBranch(tester);
        await tester.tap(find.byKey(LessonKeys.variationBack));
        await tester.pumpAndSettle();
        expect(placement(tester), kd1);
        await tester.tap(find.byKey(LessonKeys.variationBack));
        await tester.pumpAndSettle();
        expect(placement(tester), start0);
        expect(tester.takeException(), isNull);
      });

      testWidgets('9c: motor mantém: a peça volta e anda o ⏭', (tester) async {
        await enterBranch(tester, motor: engine(500));
        await dragMove(tester, 'd1', 'd2');
        expect(placement(tester), kc1);
        expect(find.byKey(LessonKeys.engineErrorSnack), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('9c: motor perde: abre o sub-ramo e a resposta anima', (
        tester,
      ) async {
        await enterBranch(tester, motor: engine(-500, reply: 'd8c8'));
        await dragMove(tester, 'd1', 'd2');
        // O lance do aluno entra no sub-ramo e o adversário responde.
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(placement(tester), kd2c8);
        expect(find.byKey(LessonKeys.variationStrip), findsOneWidget);
        // Dentro do sub-ramo o tabuleiro não aceita lance (PC).
        await dragMove(tester, 'd2', 'c2');
        expect(placement(tester), kd2c8);
        expect(tester.takeException(), isNull);
      });

      testWidgets('9c: o motor pensando põe os pontos na faixa', (
        tester,
      ) async {
        final gate = Completer<Evaluation?>();
        await enterBranch(
          tester,
          motor: EngineFallback(
            evaluate: (_, _) => gate.future,
            bestMove: (_) async => mv('e8d8'),
          ),
        );
        await dragMove(tester, 'd1', 'd2', settle: false);
        expect(find.byKey(LessonKeys.sheetTyping), findsOneWidget);
        gate.complete(const Evaluation(centipawns: -500));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.byKey(LessonKeys.sheetTyping), findsNothing);
      });

      testWidgets('9c: erro do motor: snackbar e o lance volta', (
        tester,
      ) async {
        await enterBranch(tester, motor: engine(0, fail: true));
        await dragMove(tester, 'd1', 'd2');
        expect(find.byKey(LessonKeys.engineErrorSnack), findsOneWidget);
        expect(placement(tester), kd8);
        expect(tester.takeException(), isNull);
      });
    });

    group('Ainda com dúvida? $tag', () {
      testWidgets('abre /setup com a posição e o objetivo (ganhar)', (
        tester,
      ) async {
        final cubit = await pump(tester, size: size);
        await tester.tap(find.byKey(LessonKeys.showAnswerLink));
        await tester.pumpAndSettle();
        final button = find.text('Abrir no tabuleiro livre');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(opened!.path, '/setup');
        expect(opened!.queryParameters['fen'], cubit.state.fen);
        expect(opened!.queryParameters['goal'], 'win');
      });
    });
  }
}
