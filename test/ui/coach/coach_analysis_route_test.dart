import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

/// A partida nunca chega.
class _RepoSilent extends FakeCoachRepository {
  _RepoSilent()
    : super(account: CoachFixtures.account, games: CoachFixtures.list());

  @override
  Stream<CoachGame?> game(String id) => const Stream.empty();
}

void main() {
  testWidgets('enquanto a partida carrega: esqueleto com o título', (
    tester,
  ) async {
    device411x914(tester);
    final repo = _RepoSlow();
    final bed = CoachBed(repo: repo);
    await bed.open(tester, Routes.coachAnalysis(CoachFixtures.idTiago));

    expect(find.byType(LoadSkeletonScreen), findsOneWidget);
    expect(find.byKey(CoachKeys.analysis), findsNothing);
    repo.release.complete();
    await assentar(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('partida que não existe: não encontrado', (tester) async {
    device411x914(tester);
    final bed = CoachBed();
    await bed.open(tester, Routes.coachAnalysis('lichess_naoExiste'));

    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byKey(CoachKeys.analysis), findsNothing);
  });

  testWidgets('partida que não chega em 20 s: tela de sem conexão', (
    tester,
  ) async {
    device411x914(tester);
    final bed = CoachBed(repo: _RepoSilent());
    await bed.open(
      tester,
      Routes.coachAnalysis(CoachFixtures.idTiago),
      waitFor: false,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byKey(CoachKeys.analysis), findsNothing);
  });

  testWidgets('Tentar de novo no erro leva ao Treinador', (tester) async {
    device411x914(tester);
    final bed = CoachBed();
    await bed.open(tester, Routes.coachAnalysis('lichess_naoExiste'));
    final action = find.descendant(
      of: find.byType(LoadErrorScreen),
      matching: find.byType(FilledButton),
    );
    await tester.tap(action.first);
    await assentar(tester);

    expect(bed.path, startsWith(Routes.coach()));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('partida pronta: abre a análise, sem overflow', (tester) async {
    device411x914(tester);
    final bed = CoachBed();
    await bed.open(tester, Routes.coachAnalysis(CoachFixtures.idTiago));

    expect(find.byKey(CoachKeys.analysis), findsOneWidget);
    // A mesma base da análise de partida do app, com o título do Treinador.
    expect(
      find.descendant(
        of: find.byKey(CoachKeys.analysis),
        matching: find.byKey(GameDetailsKeys.screen),
      ),
      findsOneWidget,
    );
    expect(find.text('Análise da partida'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('?lance abre o lance com a classe e o comentário do servidor', (
    tester,
  ) async {
    device411x914(tester);
    final bed = CoachBed();
    await bed.open(
      tester,
      '${Routes.coachAnalysis(CoachFixtures.idTiago)}?lance=12',
    );

    await tester.tap(find.byKey(GameDetailsKeys.tabMoves));
    await assentar(tester);
    expect(
      tester.widget<Text>(find.byKey(GameDetailsKeys.moveComment)).data,
      startsWith('A dama sai cedo'),
    );
    await tester.dragUntilVisible(
      find.byKey(GameDetailsKeys.move(11)),
      find.byKey(GameDetailsKeys.panel),
      const Offset(0, -120),
    );
    expect(find.byKey(GameDetailsKeys.moveQuality(11)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('?lance abre a análise sem erro mesmo fora do intervalo', (
    tester,
  ) async {
    device411x914(tester);
    final bed = CoachBed();
    await bed.open(
      tester,
      '${Routes.coachAnalysis(CoachFixtures.idTiago)}?lance=999',
    );

    expect(find.byKey(CoachKeys.analysis), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

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
