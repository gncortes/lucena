import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

/// A partida nunca chega.
class _RepoMudo extends FakeTreinadorRepository {
  _RepoMudo()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      );

  @override
  Stream<PartidaTreinador?> partida(String id) => const Stream.empty();
}

void main() {
  testWidgets('enquanto a partida carrega: esqueleto com o título', (
    tester,
  ) async {
    aparelho411x914(tester);
    final repo = _RepoLento();
    final bed = TreinadorBed(repo: repo);
    await bed.abrir(tester, Routes.treinadorAnalise(TreinadorFixtures.idTiago));

    expect(find.byType(LoadSkeletonScreen), findsOneWidget);
    expect(find.byKey(TreinadorKeys.analise), findsNothing);
    repo.liberar.complete();
    await assentar(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('partida que não existe: não encontrado', (tester) async {
    aparelho411x914(tester);
    final bed = TreinadorBed();
    await bed.abrir(tester, Routes.treinadorAnalise('lichess_naoExiste'));

    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byKey(TreinadorKeys.analise), findsNothing);
  });

  testWidgets('partida que não chega em 20 s: tela de sem conexão', (
    tester,
  ) async {
    aparelho411x914(tester);
    final bed = TreinadorBed(repo: _RepoMudo());
    await bed.abrir(
      tester,
      Routes.treinadorAnalise(TreinadorFixtures.idTiago),
      esperar: false,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byKey(TreinadorKeys.analise), findsNothing);
  });

  testWidgets('Tentar de novo no erro leva ao Treinador', (tester) async {
    aparelho411x914(tester);
    final bed = TreinadorBed();
    await bed.abrir(tester, Routes.treinadorAnalise('lichess_naoExiste'));
    final acao = find.descendant(
      of: find.byType(LoadErrorScreen),
      matching: find.byType(FilledButton),
    );
    await tester.tap(acao.first);
    await assentar(tester);

    expect(bed.caminho, startsWith(Routes.treinador()));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('partida pronta: abre a análise, sem overflow', (tester) async {
    aparelho411x914(tester);
    final bed = TreinadorBed();
    await bed.abrir(tester, Routes.treinadorAnalise(TreinadorFixtures.idTiago));

    expect(find.byKey(TreinadorKeys.analise), findsOneWidget);
    // A mesma base da análise de partida do app, com o título do Treinador.
    expect(
      find.descendant(
        of: find.byKey(TreinadorKeys.analise),
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
    aparelho411x914(tester);
    final bed = TreinadorBed();
    await bed.abrir(
      tester,
      '${Routes.treinadorAnalise(TreinadorFixtures.idTiago)}?lance=12',
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
    aparelho411x914(tester);
    final bed = TreinadorBed();
    await bed.abrir(
      tester,
      '${Routes.treinadorAnalise(TreinadorFixtures.idTiago)}?lance=999',
    );

    expect(find.byKey(TreinadorKeys.analise), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _RepoLento extends FakeTreinadorRepository {
  _RepoLento()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      );

  final liberar = Completer<void>();

  @override
  Stream<PartidaTreinador?> partida(String id) async* {
    await liberar.future;
    yield* super.partida(id);
  }
}
