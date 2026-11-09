import '../../../testing/board_center.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/lesson_script/widgets/script_move_list.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/core/widgets/move_highlight.dart';
import 'package:lucena/ui/coach/view_models/coach_exercise_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

const _idTiago = CoachFixtures.idTiago;

/// A partida só chega quando o teste deixa.
class _RepoSlow extends FakeCoachRepository {
  _RepoSlow()
    : super(account: CoachFixtures.account, games: CoachFixtures.list());

  final release = Completer<void>();

  @override
  Stream<CoachGame?> game(String id) async* {
    await release.future;
    yield* super.game(id);
  }
}

FakeCoachRepository _repo() => FakeCoachRepository(
  account: CoachFixtures.account,
  games: CoachFixtures.list(),
);

GameProgress _progress(int doneCount, {int corrects = 0}) => GameProgress(
  results: [
    for (var n = 1; n <= doneCount; n++)
      ExerciseResult(
        n: n,
        solved: n <= corrects,
        points: n <= corrects ? 10 : 0,
      ),
  ],
);

CoachExerciseState _state(WidgetTester tester) => tester
    .element(find.byKey(CoachKeys.exercise))
    .read<CoachExerciseCubit>()
    .state;

/// Joga [uci] tocando a casa de saída e a de chegada.
Future<void> _play(WidgetTester tester, String uci) async {
  final move = Move.parse(uci)! as NormalMove;
  final board = find.byKey(CoachKeys.exerciseBoard);
  final rect = tester.getRect(board);
  final side = tester.widget<Chessboard>(board).orientation;
  await tester.tapAt(squareCenter(rect, move.from.name, orientation: side));
  await tester.pump();
  await tester.tapAt(squareCenter(rect, move.to.name, orientation: side));
  await assentar(tester);
}

/// Um lance legal que não é a solução do exercício aberto.
String _wrongMove(WidgetTester tester) {
  final ex = _state(tester).exercise!;
  final pos = Chess.fromSetup(Setup.parseFen(ex.fen));
  for (final MapEntry(key: from, value: destinationsList)
      in pos.legalMoves.entries) {
    for (final to in destinationsList.squares) {
      final uci = NormalMove(from: from, to: to).uci;
      if (uci != ex.solution && !ex.solution.startsWith(uci)) return uci;
    }
  }
  throw StateError('sem lance errado');
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await assentar(tester);
}

void main() {
  testWidgets('partida que não existe: tela de não encontrado', (tester) async {
    device411x914(tester);
    final bed = CoachBed(repo: _repo());
    await bed.open(tester, Routes.coachExercises('lichess_naoExiste'));

    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byKey(CoachKeys.exercise), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enquanto a partida não chega: esqueleto de carregamento', (
    tester,
  ) async {
    device411x914(tester);
    final repo = _RepoSlow();
    final bed = CoachBed(repo: repo);
    await bed.open(tester, Routes.coachExercises(_idTiago));

    expect(find.byType(LoadSkeletonScreen), findsOneWidget);
    // Não libera a partida (ao chegar, o tabuleiro cairia no BUG abaixo):
    // passados 20 s, é falta de conexão (com "Tentar de novo"), não "não
    // encontrada".
    await tester.pump(const Duration(seconds: 9));
    await tester.pump();
    expect(find.byType(LoadSkeletonScreen), findsNothing);
    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(
      tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
      LoadErrorKind.offline,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgetsA8('A8: tabuleiro no centro útil e de ponta a ponta', (
    tester,
  ) async {
    setCentroAparelho(tester);
    final bed = CoachBed(repo: _repo());
    await bed.open(tester, Routes.coachExercises(_idTiago));

    expect(find.byKey(CoachKeys.exerciseBoard), findsOneWidget);
    expectTabuleiroNoCentro(tester);
    await tester.pumpWidget(const SizedBox());
  });

  group('fim dos exercícios', () {
    Future<CoachBed> openEnd(WidgetTester tester, {int corrects = 4}) async {
      device411x914(tester);
      final repo = _repo();
      await repo.saveProgress(_idTiago, _progress(4, corrects: corrects));
      final bed = CoachBed(repo: repo);
      await bed.open(tester, Routes.coachExercises(_idTiago));
      return bed;
    }

    testWidgets('tudo certo: nota, título e contagem, sem overflow', (
      tester,
    ) async {
      await openEnd(tester);

      expect(find.byKey(CoachKeys.end), findsOneWidget);
      expect(find.byKey(CoachKeys.endNote), findsOneWidget);
      expect(find.text('4 de 4 certos'), findsOneWidget);
      expect(find.text('Sua partida contra Tiago_Rook · 5+0'), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        expect(find.byKey(CoachKeys.endDot(n)), findsOneWidget);
      }
      expect(find.byKey(CoachKeys.analysisEnd), findsOneWidget);
      expect(find.byKey(CoachKeys.endYourGame), findsOneWidget);
      expect(find.byKey(CoachKeys.endClose), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('acertos pela metade: título e contagem mudam', (tester) async {
      await openEnd(tester, corrects: 2);

      expect(find.text('4 de 4 certos'), findsNothing);
      expect(find.text('2 de 4 certos'), findsOneWidget);
      // Verde nos certos, vermelho nos errados.
      Color? color(int n) =>
          ((tester
                      .widget<Container>(
                        find.descendant(
                          of: find.byKey(CoachKeys.endDot(n)),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration)!
                  as BoxDecoration)
              .color;
      expect(color(1), AppColors.trainingDayCorrect);
      expect(color(2), AppColors.trainingDayCorrect);
      expect(color(3), AppColors.trainingDayWrong);
      expect(color(4), AppColors.trainingDayWrong);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ver a análise completa abre a análise da partida', (
      tester,
    ) async {
      final bed = await openEnd(tester);
      await _tap(tester, find.byKey(CoachKeys.analysisEnd));

      // A10 G4: abre na primeira posição-chave, não no lance 0.
      expect(bed.path, startsWith('${Routes.coachAnalysis(_idTiago)}?lance='));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Onde você mais erra leva à aba Seu jogo', (tester) async {
      final bed = await openEnd(tester);
      await _tap(tester, find.byKey(CoachKeys.endYourGame));

      expect(bed.path, Routes.coach(tab: 'seuJogo'));
      expect(find.byKey(CoachKeys.end), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Fechar volta para a tela de onde veio', (tester) async {
      final bed = await openEnd(tester);
      await _tap(tester, find.byKey(CoachKeys.endClose));

      expect(bed.path, Routes.home);
      expect(find.text('stub.home'), findsOneWidget);
    });

    testWidgets('o X leva a fechar: sem a seta de voltar', (tester) async {
      await openEnd(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byKey(CoachKeys.back), findsNothing);
    });
  });

  group('exercício no tabuleiro', () {
    testWidgets('abre no primeiro: título, estrelas e botão de solução', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));

      expect(find.text('Exercício 1 de 4'), findsOneWidget);
      expect(find.byKey(CoachKeys.exerciseBoard), findsOneWidget);
      expect(find.byKey(CoachKeys.exerciseStars), findsOneWidget);
      expect(find.byKey(CoachKeys.seeSolution), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lance errado: Tentar novamente devolve a posição', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      final fen = _state(tester).fen;
      await _play(tester, _wrongMove(tester));
      expect(find.byKey(CoachKeys.retry), findsOneWidget);
      await _tap(tester, find.byKey(CoachKeys.retry));
      expect(_state(tester).fen, fen);
      expect(_state(tester).phase, ExerciseStep.playing);
    });

    testWidgets('estrela cheia vale pontos; vazia depois do erro', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      IconData? star() =>
          tester.widget<Icon>(find.byKey(CoachKeys.exerciseStars)).icon;
      expect(star(), Icons.star_rounded);
      await _play(tester, _wrongMove(tester));
      expect(star(), Icons.star_outline_rounded);
    });

    testWidgets(
      'dica: marca a peça, depois o lance; a estrela segue cheia enquanto vale pontos',
      (tester) async {
        device411x914(tester);
        final bed = CoachBed(repo: _repo());
        await bed.open(tester, Routes.coachExercises(_idTiago));
        final solution =
            Move.parse(_state(tester).exercise!.solution)! as NormalMove;
        Set<Shape> marks() => tester
            .widget<Chessboard>(find.byKey(CoachKeys.exerciseBoard))
            .shapes;
        IconData? star() =>
            tester.widget<Icon>(find.byKey(CoachKeys.exerciseStars)).icon;
        final hint = find.byKey(CoachKeys.hint);
        expect(hint, findsOneWidget);
        expect(
          tester.widget<IconButton>(hint).tooltip,
          'Dica (custa um ponto)',
        );
        expect(marks(), isEmpty);

        await _tap(tester, hint);
        expect(star(), Icons.star_rounded);
        expect(marks().single, isA<Circle>());
        expect((marks().single as Circle).orig, solution.from);

        await _tap(tester, hint);
        final arrow = marks().single as Arrow;
        expect((arrow.orig, arrow.dest), (solution.from, solution.to));
        // O lance já está à vista: a lâmpada sai.
        expect(hint, findsNothing);

        await _play(tester, solution.uci);
        expect(_state(tester).progress.results.single.points, 1);
        expect(_state(tester).progress.results.single.hints, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dica some no erro e depois de resolver', (tester) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      await _play(tester, _wrongMove(tester));
      expect(find.byKey(CoachKeys.hint), findsNothing);
      await _tap(tester, find.byKey(CoachKeys.retry));
      // Depois do erro, a dica zera o exercício.
      expect(
        tester.widget<IconButton>(find.byKey(CoachKeys.hint)).tooltip,
        'Dica (o exercício deixa de pontuar)',
      );
      await _tap(tester, find.byKey(CoachKeys.seeSolution));
      expect(find.byKey(CoachKeys.hint), findsNothing);
    });

    testWidgets('notação: o lance errado leva "?"; a solução vem em SAN', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      expect(find.byType(ScriptMoveList), findsNothing);
      await _play(tester, _wrongMove(tester));
      expect(find.byType(ScriptMoveList), findsOneWidget);
      expect(
        tester
            .widget<ScriptMoveList>(find.byType(ScriptMoveList))
            .moves
            .single
            .symbol,
        '?',
      );
      // O lance no destaque da análise de partida: fundo secundário com
      // contorno, não o chip azul cheio.
      expect(
        tester.widget<ScriptMoveList>(find.byType(ScriptMoveList)).highlight,
        MoveHighlight.outlined,
      );
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ScriptMoveList),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final colors = Theme.of(tester.element(find.byType(ScriptMoveList)))
          .colorScheme;
      expect(
        box.decoration,
        MoveHighlight.outlinedDecoration(colors, selected: true),
      );
      await _tap(tester, find.byKey(CoachKeys.seeSolution));
      final chessMove = tester
          .widget<ScriptMoveList>(find.byType(ScriptMoveList))
          .moves
          .single;
      expect(chessMove.symbol, '!');
      expect(chessMove.san, isNotEmpty);
    });

    testWidgets('lance certo: Próximo exercício avança o título', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      await _play(tester, _state(tester).exercise!.solution);
      expect(find.byKey(CoachKeys.next), findsOneWidget);
      await _tap(tester, find.byKey(CoachKeys.next));
      expect(find.text('Exercício 2 de 4'), findsOneWidget);
    });

    testWidgets('Ver a solução mostra a resposta e libera o próximo', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      await _tap(tester, find.byKey(CoachKeys.seeSolution));
      expect(find.byKey(CoachKeys.next), findsOneWidget);
    });

    testWidgets('o último exercício leva ao resumo', (tester) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo());
      await bed.open(tester, Routes.coachExercises(_idTiago));
      for (var i = 0; i < 4; i++) {
        await _tap(tester, find.byKey(CoachKeys.seeSolution));
        await _tap(tester, find.byKey(CoachKeys.next));
      }
      expect(find.byKey(CoachKeys.end), findsOneWidget);
    });
  });
}
