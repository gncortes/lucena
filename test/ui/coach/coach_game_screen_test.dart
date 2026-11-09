import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/coach/coach_rules.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/core/widgets/animated_progress.dart';
import 'package:lucena/ui/core/widgets/busy_button.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../testing/fakes/fake_trivia_repository.dart';
import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

const _idNew = 'lichess_DeF67890';
const _idAnalyzing = 'lichess_GhI13579';

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

/// O pedido de análise só responde quando o teste deixa.
class _RepoSlowAnalyze extends FakeCoachRepository {
  _RepoSlowAnalyze(List<CoachGame> games)
    : super(account: CoachFixtures.account, games: games);

  final release = Completer<void>();

  @override
  Future<void> analyze(String id, {bool notify = true}) async {
    await release.future;
    await super.analyze(id, notify: notify);
  }
}

/// A leitura da partida falha.
class _RepoOffline extends FakeCoachRepository {
  _RepoOffline()
    : super(account: CoachFixtures.account, games: CoachFixtures.list());

  @override
  Stream<CoachGame?> game(String id) => Stream.error(StateError('sem rede'));
}

FakeCoachRepository _repo([List<CoachGame>? games]) => FakeCoachRepository(
  account: CoachFixtures.account,
  games: games ?? CoachFixtures.list(),
);

CoachGame _new() => CoachFixtures.list().firstWhere((p) => p.id == _idNew);

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

/// Rola até o item aparecer e toca nele.
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await assentar(tester);
}

/// BUG (lib): `treinador_exercicio_screen.dart:240` usa `context.select`
/// dentro do `boardBuilder`, que roda no layout (`LayoutBuilder`) e não no
/// `build`; em debug o provider lança uma asserção. Estes testes só querem
/// saber que a tela de exercícios abriu, então descartam essa exceção.
void _discardBoardBug(WidgetTester tester) => tester.takeException();

Finder _textAt(Key key, String shownText) =>
    find.descendant(of: find.byKey(key), matching: find.text(shownText));

/// O cartão "Como funciona" do canvas: os três itens, com [n] exercícios.
void _checkHowItWorks(int n) {
  expect(find.byKey(CoachKeys.howItWorks), findsWidgets);
  expect(find.text('Como funciona'), findsOneWidget);
  // Antes da análise o total é a previsão: "Até n exercícios".
  expect(
    find.textContaining(RegExp('^(Até )?$n exercícios\$')),
    findsOneWidget,
  );
  expect(find.text('Posições-chave que decidiram a partida.'), findsOneWidget);
  expect(find.text('Pense antes de jogar'), findsOneWidget);
  expect(find.text('Depois, a partida inteira'), findsOneWidget);
  expect(find.byIcon(Icons.extension_outlined), findsOneWidget);
  expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
}

Future<CoachBed> _open(
  WidgetTester tester,
  CoachGame game, {
  FakeCoachRepository? repo,
  bool plan = true,
  bool waitFor = true,
}) async {
  device411x914(tester);
  final bed = CoachBed(
    repo: repo ?? _repo([game, ...CoachFixtures.list()]),
    grants: plan ? withPlan() : CourseGrants.empty,
  );
  await bed.open(tester, Routes.coachGame(game.id), waitFor: waitFor);
  return bed;
}

void main() {
  group('leitura da partida', () {
    testWidgets('enquanto a partida não chega, mostra o esqueleto', (
      tester,
    ) async {
      device411x914(tester);
      final repo = _RepoSlow();
      // Sem o plano a partida nova fica no início (com plano, A10 G2).
      final bed = CoachBed(repo: repo, grants: CourseGrants.empty);
      await bed.open(tester, Routes.coachGame(_idNew));

      expect(find.byType(LoadSkeletonScreen), findsOneWidget);
      expect(find.byKey(CoachKeys.start), findsNothing);

      repo.release.complete();
      await assentar(tester);
      expect(find.byType(LoadSkeletonScreen), findsNothing);
      expect(find.byKey(CoachKeys.start), findsOneWidget);
    });

    testWidgets('sem rede, mostra o erro de conexão', (tester) async {
      device411x914(tester);
      final bed = CoachBed(repo: _RepoOffline(), grants: withPlan());
      await bed.open(tester, Routes.coachGame(_idNew));

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byKey(CoachKeys.start), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('partida que não existe mostra o erro de não encontrada', (
      tester,
    ) async {
      device411x914(tester);
      final bed = CoachBed(repo: _repo(), grants: withPlan());
      await bed.open(tester, Routes.coachGame('lichess_naoExiste'));

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.byKey(CoachKeys.start), findsNothing);
      expect(find.byKey(CoachKeys.loading), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // Sem o plano a partida nova pede o toque; com o plano ela já analisa (A10 G2).
  group('início (partida nova, sem plano)', () {
    testWidgets('mostra o cartão, os três passos e o botão de analisar', (
      tester,
    ) async {
      await _open(tester, _new(), plan: false);

      expect(find.byKey(CoachKeys.start), findsOneWidget);
      expect(find.text('Análise da partida'), findsOneWidget);
      expect(find.byKey(CoachKeys.gameCard), findsWidgets);
      _checkHowItWorks(4);
      expect(_textAt(CoachKeys.begin, 'Começar a análise'), findsOneWidget);
      expect(
        _textAt(CoachKeys.seeGames, 'Ver minhas partidas'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver minhas partidas" abre a aba Partidas', (tester) async {
      final bed = await _open(tester, _new(), plan: false);

      await _tap(tester, find.byKey(CoachKeys.seeGames));
      expect(bed.path, '/treinador?aba=partidas');
      expect(find.byKey(CoachKeys.games), findsOneWidget);
    });

    testWidgets('o voltar fecha a tela', (tester) async {
      await _open(tester, _new(), plan: false);

      await tester.tap(find.byKey(CoachKeys.back));
      await assentar(tester);
      expect(find.text('stub.home'), findsOneWidget);
    });

    testWidgets('analisar pede a análise e passa à espera', (tester) async {
      final bed = await _open(tester, _new(), plan: false);

      await tester.tap(find.byKey(CoachKeys.begin));
      await assentar(tester);

      expect(bed.repo.analysisRequests.map((e) => e.$1), [_idNew]);
      expect(find.byKey(CoachKeys.loading), findsOneWidget);
      expect(find.byKey(CoachKeys.start), findsNothing);
      expect(find.text('Análise da partida'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('quando a análise termina, mostra os exercícios', (
      tester,
    ) async {
      final repo = _repo()..analyzeCompletes = true;
      await _open(tester, _new(), repo: repo, plan: false);

      await tester.tap(find.byKey(CoachKeys.begin));
      await assentar(tester);

      expect(find.byKey(CoachKeys.loading), findsNothing);
      expect(find.byKey(CoachKeys.start), findsOneWidget);
      expect(_textAt(CoachKeys.begin, 'Começar os exercícios'), findsOneWidget);
      expect(find.byKey(CoachKeys.howItWorks), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('pedido recusado', () {
    testWidgets('acabou a cota grátis: abre a venda do plano', (tester) async {
      final repo = _repo()
        ..analyzeFailure = 'permission-denied'
        ..analyzeReason = 'cota';
      final bed = await _open(tester, _new(), repo: repo, plan: false);

      await tester.tap(find.byKey(CoachKeys.begin));
      await assentar(tester);

      expect(bed.path, '/pilares');
      expect(find.text('stub.pilares'), findsOneWidget);
    });

    testWidgets('teto do mês: mostra o aviso e fica no início', (tester) async {
      final repo = _repo()
        ..analyzeFailure = 'permission-denied'
        ..analyzeReason = 'teto';
      final bed = await _open(tester, _new(), repo: repo);

      await tester.tap(find.byKey(CoachKeys.begin));
      await assentar(tester);

      expect(
        find.text(
          'As análises deste mês acabaram. Elas voltam no mês que vem.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.start), findsOneWidget);
      expect(bed.path, Routes.coachGame(_idNew));
    });

    testWidgets('falha do servidor: mostra o aviso de tentar novamente', (
      tester,
    ) async {
      final repo = _repo()..analyzeFailure = 'unavailable';
      await _open(tester, _new(), repo: repo);

      await tester.tap(find.byKey(CoachKeys.begin));
      await assentar(tester);

      expect(
        find.text('Não foi possível pedir a análise. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.start), findsOneWidget);
    });
  });

  group('espera da análise', () {
    Future<void> openAnalyzing(WidgetTester tester) async {
      final game = CoachFixtures.list().firstWhere((p) => p.id == _idAnalyzing);
      await _open(tester, game);
    }

    testWidgets('mostra a frase, a porcentagem, a curiosidade e o aviso', (
      tester,
    ) async {
      await openAnalyzing(tester);

      expect(find.byKey(CoachKeys.loading), findsOneWidget);
      expect(find.text('Análise da partida'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(CoachKeys.loadingPhrase)).data,
        'Preparando seus exercícios',
      );
      expect(
        tester.widget<Text>(find.byKey(CoachKeys.loadingPercentage)).data,
        matches(RegExp(r'^\d+%$')),
      );
      expect(find.byKey(CoachKeys.trivia), findsOneWidget);
      expect(find.text('Você sabia?'), findsOneWidget);
      expect(
        find.text(
          'Estamos olhando sua partida lance a lance. Pode levar alguns '
          'minutos.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Pode sair do app: avisamos quando os exercícios estiverem prontos.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.loadingBar), findsOneWidget);
      expect(find.byType(AnimatedProgress), findsOneWidget);
      expect(
        _textAt(CoachKeys.anotherTrivia, 'Outra curiosidade'),
        findsOneWidget,
      );
      expect(
        tester.widget(find.byKey(CoachKeys.anotherTrivia)),
        isA<OutlinedButton>(),
      );
      expect(
        tester.widget(find.byKey(CoachKeys.notifyMe)),
        isA<OutlinedButton>(),
      );
      expect(
        _textAt(CoachKeys.notifyMe, 'Me avise quando terminar'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('as frases se revezam e "Quase lá" só vem perto do fim', (
      tester,
    ) async {
      final game = CoachFixtures.list().firstWhere((p) => p.id == _idAnalyzing);
      final bed = await _open(tester, game);
      String phrase() =>
          tester.widget<Text>(find.byKey(CoachKeys.loadingPhrase)).data!;
      final vistas = <String>{phrase()};
      for (var i = 0; i < 3; i++) {
        bed.now.advance(const Duration(seconds: 4));
        for (var s = 0; s < 4; s++) {
          await tester.pump(const Duration(seconds: 1));
        }
        vistas.add(phrase());
      }
      expect(vistas, {
        'Preparando seus exercícios',
        'Separando os lances que mais ensinam',
        'Montando seu treino',
      });

      // Perto do fim (80% ou mais), "Quase lá" entra no revezamento.
      bed.now.advance(const Duration(seconds: 160));
      for (var i = 0; i < 4; i++) {
        bed.now.advance(const Duration(seconds: 4));
        for (var s = 0; s < 4; s++) {
          await tester.pump(const Duration(seconds: 1));
        }
        vistas.add(phrase());
      }
      expect(vistas, contains('Quase lá'));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Outra curiosidade" troca o texto da curiosidade', (
      tester,
    ) async {
      await openAnalyzing(tester);
      String shownText() =>
          tester.widget<TeacherSpeech>(find.byType(TeacherSpeech)).text!;

      final before = shownText();
      await tester.tap(find.byKey(CoachKeys.anotherTrivia));
      await assentar(tester);
      expect(shownText(), isNot(before));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Me avise quando terminar" pede o aviso e fecha a tela', (
      tester,
    ) async {
      final bed = await _open(
        tester,
        CoachFixtures.list().firstWhere((p) => p.id == _idAnalyzing),
      );

      await tester.tap(find.byKey(CoachKeys.notifyMe));
      await assentar(tester);

      expect(bed.repo.analysisRequests, [(_idAnalyzing, true)]);
      expect(find.text('stub.home'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('quando o servidor grava o resultado, a tela muda sozinha', (
      tester,
    ) async {
      final bed = await _open(
        tester,
        CoachFixtures.list().firstWhere((p) => p.id == _idAnalyzing),
      );
      expect(find.byKey(CoachKeys.loading), findsOneWidget);

      final analyzing = CoachFixtures.list().firstWhere(
        (p) => p.id == _idAnalyzing,
      );
      bed.repo.perGame(
        withStatus(analyzing, GameStatus.error, errorReason: 'variante'),
      );
      await assentar(tester);
      expect(find.byKey(CoachKeys.loading), findsNothing);
      expect(find.byKey(CoachKeys.error), findsOneWidget);
    });
  });

  group('erro da análise', () {
    testWidgets('erro comum: explica e deixa tentar novamente', (tester) async {
      final error = withStatus(_new(), GameStatus.error);
      final bed = await _open(tester, error);

      expect(find.byKey(CoachKeys.error), findsOneWidget);
      expect(
        find.text('Não foi possível analisar esta partida'),
        findsOneWidget,
      );
      expect(find.text('Tente novamente em alguns instantes.'), findsOneWidget);
      expect(_textAt(CoachKeys.errorRetry, 'Tentar novamente'), findsOneWidget);
      expect(find.byKey(CoachKeys.errorBack), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(CoachKeys.errorRetry));
      await assentar(tester);
      expect(bed.repo.analysisRequests.map((e) => e.$1), [_idNew]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('variante: não oferece tentar, leva à lista de partidas', (
      tester,
    ) async {
      final error = withStatus(
        _new(),
        GameStatus.error,
        errorReason: 'variante',
      );
      final bed = await _open(tester, error);

      expect(
        find.text(
          'Esta partida é de uma variante, e a análise só vale para o '
          'xadrez comum.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(CoachKeys.errorRetry), findsNothing);
      expect(
        _textAt(CoachKeys.errorBack, 'Ver todas as partidas'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(CoachKeys.errorBack));
      await assentar(tester);
      expect(bed.path, '/treinador?aba=partidas');
      expect(find.byKey(CoachKeys.games), findsOneWidget);
    });
  });

  group('partida pronta', () {
    testWidgets('sem exercício feito: convida a começar', (tester) async {
      final bed = await _open(tester, CoachFixtures.tiago());

      expect(find.byKey(CoachKeys.start), findsOneWidget);
      // O cartão traz a frase do resumo (DInicio), sem seta.
      expect(find.text('0 de 4 exercícios feitos'), findsNothing);
      expect(
        _textAt(
          CoachKeys.gameCard,
          'Você perdeu no lance 51, num final de torres que empatava.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(CoachKeys.gameCard),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );
      expect(_textAt(CoachKeys.begin, 'Começar os exercícios'), findsOneWidget);
      _checkHowItWorks(4);

      await tester.tap(find.byKey(CoachKeys.begin));
      await assentar(tester);
      expect(bed.path, Routes.coachExercises(CoachFixtures.idTiago));
      expect(find.byKey(CoachKeys.exercise), findsOneWidget);
      _discardBoardBug(tester);
    });

    testWidgets('com exercícios feitos: continua de onde parou', (
      tester,
    ) async {
      final partial = CoachFixtures.tiago().copyWith(
        progress: _progress(2, corrects: 1),
      );
      await _open(tester, partial);

      expect(find.byKey(CoachKeys.start), findsOneWidget);
      expect(_textAt(CoachKeys.begin, 'Continuar (2 de 4)'), findsOneWidget);
      expect(find.byKey(CoachKeys.summary), findsNothing);
    });
  });

  group('resumo da partida', () {
    CoachGame complete() =>
        CoachFixtures.tiago().copyWith(progress: _progress(4, corrects: 3));

    testWidgets('mostra precisão, exercícios, fases e posições-chave', (
      tester,
    ) async {
      await _open(tester, complete());

      expect(find.byKey(CoachKeys.summary), findsOneWidget);
      expect(find.text('Contra Tiago_Rook'), findsOneWidget);
      expect(find.byKey(CoachKeys.summaryGameCard), findsWidgets);
      expect(find.byKey(CoachKeys.summaryAccuracy), findsWidgets);
      expect(find.text('Sua precisão'), findsOneWidget);
      expect(find.byKey(CoachKeys.summaryExercises), findsWidgets);
      expect(find.text('3 de 4'), findsOneWidget);
      expect(find.text('certos na análise'), findsOneWidget);
      expect(find.text('Precisão por fase'), findsOneWidget);
      expect(find.byKey(CoachKeys.summaryPhases), findsWidgets);
      expect(find.text('Posições-chave'), findsOneWidget);
      await tester.ensureVisible(find.byKey(CoachKeys.keyPosition(4)));
      await tester.pump();
      expect(find.text('Lance 8 · Sacrificio h7'), findsOneWidget);
      expect(find.text('Lance 8 · Profilaxia'), findsOneWidget);
      expect(find.text('Recurso do adversário'), findsOneWidget);
      expect(find.text('Impedir a ameaça'), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        await tester.ensureVisible(find.byKey(CoachKeys.keyPosition(n)));
        await tester.pump();
        expect(find.byKey(CoachKeys.keyPosition(n)), findsWidgets);
      }
      expect(
        _textAt(CoachKeys.analysisSummary, 'Ver a análise completa'),
        findsOneWidget,
      );
      expect(_textAt(CoachKeys.redo, 'Refazer os exercícios'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver a análise completa" abre a análise da partida', (
      tester,
    ) async {
      final bed = await _open(tester, complete());

      await _tap(tester, find.byKey(CoachKeys.analysisSummary));
      expect(bed.path, Routes.coachAnalysis(CoachFixtures.idTiago));
      expect(find.byKey(CoachKeys.analysis), findsOneWidget);
    });

    testWidgets('uma posição-chave abre a análise no lance dela', (
      tester,
    ) async {
      final bed = await _open(tester, complete());
      final ex = complete().exercises.first;

      await _tap(tester, find.byKey(CoachKeys.keyPosition(ex.n)));
      expect(
        bed.path,
        Routes.coachAnalysis(
          CoachFixtures.idTiago,
          ply: CoachRules.halfMove(
            ex.chessMove,
            white: complete().color == GameColor.white,
          ),
        ),
      );
      expect(find.byKey(CoachKeys.analysis), findsOneWidget);
    });

    testWidgets('"Refazer os exercícios" abre os exercícios de novo', (
      tester,
    ) async {
      final bed = await _open(tester, complete());

      await _tap(tester, find.byKey(CoachKeys.redo));
      expect(
        bed.path,
        Routes.coachExercises(CoachFixtures.idTiago, redo: true),
      );
      expect(find.byKey(CoachKeys.exercise), findsOneWidget);
      _discardBoardBug(tester);
    });

    testWidgets('pronta sem exercícios vai direto ao resumo, sem refazer', (
      tester,
    ) async {
      await _open(tester, CoachFixtures.tiago(exercises: 0));

      expect(find.byKey(CoachKeys.summary), findsOneWidget);
      expect(find.byKey(CoachKeys.start), findsNothing);
      expect(find.text('–'), findsWidgets);
      expect(find.byKey(CoachKeys.redo), findsNothing);
      expect(find.text('Posições-chave'), findsNothing);
      expect(find.byKey(CoachKeys.analysisSummary), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('espera: o Viktor e o pé fixo', () {
    CoachGame analyzing() =>
        CoachFixtures.list().firstWhere((p) => p.id == _idAnalyzing);

    testWidgets('a curiosidade é dita pelo Viktor, com os pontos', (
      tester,
    ) async {
      await _open(tester, analyzing());

      final line = tester.widget<TeacherSpeech>(find.byType(TeacherSpeech));
      expect(line.speechContext, SpeechContext.teaching);
      expect(line.teacher.id, 'master');
      expect(line.text, contains('primeiro campeão do mundo'));
      expect(find.byKey(CoachKeys.triviaDots), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CoachKeys.triviaDots),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(FakeTriviaRepository.standard.length),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('frase à esquerda e % à direita, barra animada embaixo', (
      tester,
    ) async {
      await _open(tester, analyzing());

      final phrase = tester.getRect(find.byKey(CoachKeys.loadingPhrase));
      final pct = tester.getRect(find.byKey(CoachKeys.loadingPercentage));
      final bar = tester.getRect(find.byKey(CoachKeys.loadingBar));
      expect(phrase.left, lessThan(pct.left));
      expect((phrase.center.dy - pct.center.dy).abs(), lessThan(8));
      expect(bar.top, greaterThan(phrase.bottom));
      expect(bar.height, AnimatedProgress.height);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Me avise" e a nota ficam presos no pé, 48 dp ou mais', (
      tester,
    ) async {
      await _open(tester, analyzing());

      final screen = tester.getRect(find.byKey(CoachKeys.screen));
      final button = tester.getRect(find.byKey(CoachKeys.notifyMe));
      final note = tester.getRect(find.byKey(CoachKeys.loadingNote));
      expect(button.bottom, closeTo(screen.bottom - 16, 1));
      expect(button.height, greaterThanOrEqualTo(48));
      expect(button.width, closeTo(screen.width - 32, 1));
      expect(note.bottom, lessThan(button.top));
      expect(
        tester.getSize(find.byKey(CoachKeys.anotherTrivia)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('na fila do grátis', () {
    CoachGame queued() => withStatus(_new(), GameStatus.queued);

    testWidgets('frase da fila, barra sem número e "Me avise"', (tester) async {
      await _open(tester, queued());

      expect(find.byKey(CoachKeys.loading), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(CoachKeys.loadingPhrase)).data,
        'Sua partida está na fila',
      );
      expect(find.byKey(CoachKeys.loadingPercentage), findsNothing);
      expect(find.text('Preparando seus exercícios'), findsNothing);
      expect(find.byKey(CoachKeys.loadingQueue), findsOneWidget);
      expect(find.byKey(CoachKeys.loadingSubtitle), findsNothing);
      expect(
        tester.widget<AnimatedProgress>(find.byKey(CoachKeys.loadingBar)).value,
        isNull,
      );
      expect(
        _textAt(CoachKeys.notifyMe, 'Me avise quando terminar'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a fila não marca o início; ao virar analisando, marca', (
      tester,
    ) async {
      final bed = await _open(tester, queued());
      expect(await bed.preferences.startOfAnalysis(_idNew), isNull);

      bed.repo.perGame(withStatus(_new(), GameStatus.analyzing));
      await assentar(tester);
      expect(
        tester.widget<AnimatedProgress>(find.byKey(CoachKeys.loadingBar)).value,
        isNotNull,
      );
      expect(find.byKey(CoachKeys.loadingPercentage), findsOneWidget);
      expect(find.byKey(CoachKeys.loadingQueue), findsNothing);
      expect(await bed.preferences.startOfAnalysis(_idNew), isNotNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('início: pé fixo e cartão', () {
    testWidgets('os botões ficam presos no pé, nos dois estados', (
      tester,
    ) async {
      for (final game in [_new(), CoachFixtures.tiago()]) {
        await _open(tester, game, plan: game.status != GameStatus.newGame);
        // A cascata de entrada (H-ANI-16) termina antes de medir.
        await tester.pump(const Duration(seconds: 2));
        final screen = tester.getRect(find.byKey(CoachKeys.screen));
        final primaryAction = tester.getRect(find.byKey(CoachKeys.begin));
        final shownText = tester.getRect(find.byKey(CoachKeys.seeGames));
        final card = tester.getRect(find.byKey(CoachKeys.howItWorks).first);
        expect(shownText.bottom, closeTo(screen.bottom - 16, 1));
        expect(primaryAction.bottom, lessThan(shownText.top));
        expect(shownText.top - primaryAction.bottom, closeTo(12, 1));
        expect(card.bottom, lessThan(primaryAction.top));
        expect(primaryAction.height, greaterThanOrEqualTo(48));
        expect(shownText.height, greaterThanOrEqualTo(48));
        expect(
          tester.widget(find.byKey(CoachKeys.seeGames)),
          isA<OutlinedButton>(),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('o número de exercícios vem da config', (tester) async {
      final repo = _repo()
        ..currentConfig = const CoachConfig(exercisesPerGame: 6);
      await _open(tester, _new(), repo: repo);
      expect(find.text('Até 6 exercícios'), findsOneWidget);
    });
  });

  group('erro: tentar de novo', () {
    testWidgets('o botão mostra o envio enquanto o pedido não responde', (
      tester,
    ) async {
      final error = withStatus(_new(), GameStatus.error);
      final repo = _RepoSlowAnalyze([error]);
      await _open(tester, error, repo: repo);

      await tester.tap(find.byKey(CoachKeys.errorRetry));
      await tester.pump();
      expect(find.byType(BusyButton), findsOneWidget);
      expect(tester.widget<BusyButton>(find.byType(BusyButton)).busy, isTrue);
      repo.release.complete();
      await assentar(tester);
      expect(repo.analysisRequests, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('resumo: cartões e estados', () {
    CoachGame complete({String? opponent}) {
      final base = CoachFixtures.tiagoJson();
      final json = opponent == null
          ? base
          : {
              ...base,
              'adversario': {'nome': opponent, 'rating': 1500},
            };
      return CoachGame.fromJson(
        CoachFixtures.idTiago,
        json,
      )!.copyWith(progress: _progress(4, corrects: 3));
    }

    testWidgets('título com nome longo quebra a linha, sem reticências', (
      tester,
    ) async {
      const name = 'Fulano_De_Tal_Com_Nome_Bem_Longo_2026';
      await _open(tester, complete(opponent: name));

      final title = find.text('Contra $name');
      expect(title, findsOneWidget);
      final text = tester.widget<Text>(title);
      expect(text.overflow, TextOverflow.visible);
      expect(text.maxLines, 2);
      expect(tester.getRect(title).height, greaterThan(24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('cartão da partida no topo, depois os números e as fases', (
      tester,
    ) async {
      await _open(tester, complete());

      final top = tester.getRect(find.byKey(CoachKeys.summaryGameCard).first);
      final accuracy = tester.getRect(
        find.byKey(CoachKeys.summaryAccuracy).first,
      );
      final phases = tester.getRect(find.byKey(CoachKeys.summaryPhases).first);
      expect(top.bottom, lessThan(accuracy.top));
      expect(accuracy.bottom, lessThan(phases.top));
      expect(
        find.descendant(
          of: find.byKey(CoachKeys.summaryPhases),
          matching: find.byType(AnimatedProgress),
        ),
        findsNWidgets(3),
      );
      expect(find.text('62%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '"Refazer" é o primário e "Ver a análise" o contornado, no pé',
      (tester) async {
        await _open(tester, complete());

        final screen = tester.getRect(find.byKey(CoachKeys.screen));
        final redo = tester.getRect(find.byKey(CoachKeys.redo));
        final analysis = tester.getRect(find.byKey(CoachKeys.analysisSummary));
        expect(redo.bottom, lessThan(analysis.top));
        expect(analysis.bottom, closeTo(screen.bottom - 16, 1));
        expect(tester.widget(find.byKey(CoachKeys.redo)), isA<FilledButton>());
        expect(
          tester.widget(find.byKey(CoachKeys.analysisSummary)),
          isA<OutlinedButton>(),
        );
      },
    );

    testWidgets('✓ e ✗ vêm dos resultados do aparelho', (tester) async {
      await _open(tester, complete());
      await tester.ensureVisible(find.byKey(CoachKeys.keyPosition(4)));
      await tester.pump();

      Finder iconData(int n, IconData i) => find.descendant(
        of: find.byKey(CoachKeys.keyPosition(n)),
        matching: find.byIcon(i),
      );
      expect(iconData(1, Icons.check_circle_outline), findsOneWidget);
      expect(iconData(3, Icons.check_circle_outline), findsOneWidget);
      expect(iconData(4, Icons.highlight_off), findsOneWidget);
    });

    testWidgets('sem resultados no aparelho, a posição fica neutra', (
      tester,
    ) async {
      final remote = CoachFixtures.tiago().copyWith(
        progress: const GameProgress(remoteDone: 4, remoteCorrect: 3),
      );
      await _open(tester, remote);

      expect(find.byKey(CoachKeys.summary), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.highlight_off), findsNothing);
      await tester.ensureVisible(find.byKey(CoachKeys.keyPosition(4)));
      await tester.pump();
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('3 de 4'), findsOneWidget);
    });
  });

  group('A10: aviso → espera → análise', () {
    testWidgets('G2: com o plano, a partida nova já começa a analisar', (
      tester,
    ) async {
      final bed = await _open(tester, _new());

      expect(bed.repo.analysisRequests, [(_idNew, false)]);
      expect(find.byKey(CoachKeys.loading), findsOneWidget);
      expect(find.byKey(CoachKeys.begin), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('G2: sem o plano, a partida nova espera o toque', (
      tester,
    ) async {
      final bed = await _open(tester, _new(), plan: false);

      expect(bed.repo.analysisRequests, isEmpty);
      expect(find.byKey(CoachKeys.start), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('G3: a espera explica o que vem (Como funciona)', (
      tester,
    ) async {
      await _open(tester, _new());

      expect(find.byKey(CoachKeys.loading), findsOneWidget);
      _checkHowItWorks(4);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
