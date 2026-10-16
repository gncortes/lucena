import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_wiki.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<ExerciseCubit> pump(
    WidgetTester tester,
    String exercise, {
    FakeWebPages? webPages,
    FakeNow? now,
    FakeEndgameLessonRepository? lessons,
    EndgameProgress progress = const EndgameProgress(),
  }) async {
    final cubit = ExerciseCubit(
      now: now ?? FakeNow(DateTime.utc(2026, 10, 11)),
      lessons: lessons ?? FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(progress),
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', exercise, 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        webPages: webPages,
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> move(WidgetTester tester, String from, String to) async {
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    await tester.tapAt(squareCenter(board, from));
    await tester.pump();
    await tester.tapAt(squareCenter(board, to));
    await tester.pumpAndSettle();
  }

  testWidgets('T65: lifecycle congela o cronômetro do exercício', (
    tester,
  ) async {
    final now = FakeNow(DateTime.utc(2026, 10, 11));
    final cubit = await pump(tester, 'e03', now: now);
    now.advance(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    now.advance(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(cubit.elapsed, const Duration(seconds: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    now.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(cubit.elapsed, const Duration(seconds: 10));
  });

  const sizes = [Size(360, 740), Size(412, 917)];

  void setSize(WidgetTester tester, Size size) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder said(String text) => find.descendant(
    of: find.byKey(LessonScriptKeys.speech),
    matching: find.textContaining(text, findRichText: true),
  );

  for (final size in sizes) {
    testWidgets('$size: balão em cima, tabuleiro, lista abaixo, sem overflow', (
      tester,
    ) async {
      setSize(tester, size);
      await pump(tester, 'e02');
      final speechRect = tester.getRect(find.byKey(LessonScriptKeys.speech));
      final board = tester.getRect(find.byKey(ExerciseKeys.board));
      expect(speechRect.bottom, lessThanOrEqualTo(board.top + 1));
      expect(said('Win again.'), findsOneWidget);
      // O selo de acerto não existe mais: o feedback mora no balão.
      expect(find.byKey(ExerciseKeys.correct), findsNothing);
      final hint = tester.getSize(find.byKey(ExerciseKeys.hintButton));
      expect(hint.width, greaterThanOrEqualTo(48));
      expect(hint.height, greaterThanOrEqualTo(48));
      expect(find.byKey(ExerciseKeys.showSolution), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$size: errar o primeiro lance zera, mostra Ver solução e '
        'termina com Próximo exercício à direita, margem 16', (tester) async {
      setSize(tester, size);
      final cubit = await pump(tester, 'e02');
      await move(tester, 'c1', 'c2');
      expect(said('No.'), findsOneWidget);
      expect(said('Try another move.'), findsOneWidget);
      expect(cubit.state.played, isEmpty);
      expect(cubit.state.worth, 0);
      expect(
        tester.getSemantics(find.byKey(ExerciseKeys.stars)).label,
        'No longer worth points',
      );
      // O lance errado não entra na lista.
      expect(find.byKey(LessonScriptKeys.move('m0')), findsNothing);
      await tester.ensureVisible(find.byKey(ExerciseKeys.showSolution));
      await tester.tap(find.byKey(ExerciseKeys.showSolution));
      await tester.pumpAndSettle();
      expect(cubit.state.phase, ExercisePhase.done);
      expect(cubit.state.earned, 0);
      expect(find.byKey(ExerciseKeys.showSolution), findsNothing);
      final next = find.byKey(ExerciseKeys.nextButton);
      expect(next, findsOneWidget);
      final rect = tester.getRect(next);
      expect(rect.right, closeTo(size.width - 16, 1));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, lessThan(size.width - 32));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lance certo no meio: "Correct." e "Your turn." no balão, e a '
      'lista traz o lance e a resposta', (tester) async {
    setSize(tester, sizes.first);
    await pump(tester, 'e02');
    await move(tester, 'c1', 'c4');
    expect(said('Correct.'), findsOneWidget);
    expect(said('Your turn.'), findsOneWidget);
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    expect(
      tester.getRect(find.byKey(LessonScriptKeys.move('m0'))).top,
      greaterThanOrEqualTo(board.bottom - 1),
    );
    expect(find.byKey(LessonScriptKeys.move('m0')), findsOneWidget);
    expect(find.byKey(LessonScriptKeys.move('m1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro depois do primeiro lance tira um ponto e não zera', (
    tester,
  ) async {
    setSize(tester, sizes.first);
    final cubit = await pump(tester, 'e02');
    await move(tester, 'c1', 'c4');
    await move(tester, 'c4', 'c3');
    expect(cubit.state.worth, 1);
    expect(said('No.'), findsOneWidget);
    expect(find.byKey(ExerciseKeys.showSolution), findsNothing);
    expect(
      tester.getSemantics(find.byKey(ExerciseKeys.stars)).label,
      isNot('No longer worth points'),
    );
  });

  testWidgets('resolvido: o borrar nasce desligado e a notação mostra tudo', (
    tester,
  ) async {
    setSize(tester, sizes.first);
    final cubit = await pump(tester, 'e02');
    await move(tester, 'c1', 'c4');
    await move(tester, 'c4', 'c5');
    expect(cubit.state.phase, ExercisePhase.done);
    expect(find.byKey(ExerciseKeys.hiddenMovesToggle), findsOneWidget);
    for (final node in cubit.state.review) {
      expect(find.byKey(LessonScriptKeys.hiddenMove(node.id)), findsNothing);
    }
    expect(said('Click the covered moves'), findsNothing);
    expect(cubit.state.review.any((node) => node.depth > 0), isTrue);
  });

  testWidgets('borrar ligado: os lances que o aluno jogou ficam à vista; só '
      'as variantes ficam cobertas e cada clique revela uma', (tester) async {
    setSize(tester, sizes.first);
    final cubit = await pump(tester, 'e02');
    await move(tester, 'c1', 'c4');
    await move(tester, 'c4', 'c5');
    await tester.ensureVisible(find.byKey(ExerciseKeys.hiddenMovesToggle));
    await tester.tap(find.byKey(ExerciseKeys.hiddenMovesToggle));
    await tester.pumpAndSettle();
    final review = cubit.state.review;
    final main = review.where((node) => node.depth == 0);
    final side = review.where((node) => node.depth > 0).toList();
    expect(main, hasLength(3));
    for (final node in main) {
      expect(find.byKey(LessonScriptKeys.hiddenMove(node.id)), findsNothing);
    }
    for (final node in side) {
      expect(find.byKey(LessonScriptKeys.hiddenMove(node.id)), findsWidgets);
    }
    expect(said('Click the covered moves'), findsOneWidget);
    final first = side.first;
    await tester.ensureVisible(
      find.byKey(LessonScriptKeys.hiddenMove(first.id)).first,
    );
    await tester.tap(find.byKey(LessonScriptKeys.hiddenMove(first.id)).first);
    await tester.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.hiddenMove(first.id)), findsNothing);
    expect(cubit.state.cursorId, first.id);
    expect(cubit.state.fen, first.fenAfter);
    expect(said('Click the covered moves'), findsNothing);
    // Desligado de novo, nada coberto.
    await tester.ensureVisible(find.byKey(ExerciseKeys.hiddenMovesToggle));
    await tester.tap(find.byKey(ExerciseKeys.hiddenMovesToggle));
    await tester.pumpAndSettle();
    for (final node in side) {
      expect(find.byKey(LessonScriptKeys.hiddenMove(node.id)), findsNothing);
    }
  });

  testWidgets('resolvido: o balão corta em 2 linhas com reticências e o '
      'clique abre a fala inteira', (tester) async {
    setSize(tester, sizes.first);
    final long = List.filled(
      30,
      'The rook cuts the king off the file.',
    ).join(' ');
    final texts = {
      ...FakeEndgameLessonRepository.sampleTexts.toJson(),
      'rook.lucena.ex.e02.solution': long,
    };
    final cubit = await pump(
      tester,
      'e02',
      lessons: FakeEndgameLessonRepository(texts: LessonTexts.fromJson(texts)),
    );
    await move(tester, 'c1', 'c4');
    await move(tester, 'c4', 'c5');
    expect(cubit.state.phase, ExercisePhase.done);
    final text = tester.widget<Text>(
      find
          .descendant(
            of: find.byKey(LessonScriptKeys.speech),
            matching: find.byType(Text),
          )
          .first,
    );
    expect(text.maxLines, isNull);
    // Fala enorme: o balão usa só a sobra de cima da página (linhas
    // inteiras), rola dentro dela e não toma o tabuleiro.
    final box = tester.getRect(find.byKey(LessonScriptKeys.speech));
    final page = tester.getRect(find.byKey(ExerciseKeys.page));
    expect(box.top, greaterThanOrEqualTo(page.top));
    expect(box.height, lessThan(200));
    // Na folga do balão: uma casa citada no meio da fala é alvo de toque.
    await tester.tapAt(
      tester.getTopLeft(find.byKey(LessonScriptKeys.speech)) +
          const Offset(4, 4),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
  });

  testWidgets('exercício que não existe', (tester) async {
    await pump(tester, 'e99');
    expect(find.byKey(ExerciseKeys.missing), findsOneWidget);
  });

  testWidgets('treino livre: "Analisar no Lichess" abre a posição dentro do '
      'app e o X volta ao exercício', (tester) async {
    final pages = FakeWebPages(title: 'Analysis board • lichess.org');
    await pump(
      tester,
      'e03',
      webPages: pages,
      // Todos resolvidos: a nota fechada põe o botão do Lichess na tela.
      progress: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            stars: {'e01': 1, 'e02': 2, 'e03': 1},
          ),
        },
      ),
    );
    await tester.ensureVisible(find.byKey(ExerciseKeys.lichessButton));
    await tester.tap(find.byKey(ExerciseKeys.lichessButton));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsOneWidget);
    expect(pages.opened.single.host, 'lichess.org');
    expect(find.text('Analysis board • lichess.org'), findsOneWidget);

    await tester.tap(find.byKey(ExternalPageKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsNothing);
    expect(find.byKey(ExerciseKeys.lichessButton), findsOneWidget);
  });
}
