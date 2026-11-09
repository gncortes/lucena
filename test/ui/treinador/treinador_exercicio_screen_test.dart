import '../../../testing/board_center.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/treinador/view_models/treinador_exercicio_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

const _idTiago = TreinadorFixtures.idTiago;

/// A partida só chega quando o teste deixa.
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

FakeTreinadorRepository _repo() => FakeTreinadorRepository(
  conta: TreinadorFixtures.conta,
  partidas: TreinadorFixtures.lista(),
);

ProgressoPartida _progresso(int feitos, {int acertos = 0}) => ProgressoPartida(
  resultados: [
    for (var n = 1; n <= feitos; n++)
      ResultadoExercicio(
        n: n,
        acertou: n <= acertos,
        pontos: n <= acertos ? 10 : 0,
      ),
  ],
);

TreinadorExercicioState _estado(WidgetTester tester) => tester
    .element(find.byKey(TreinadorKeys.exercicio))
    .read<TreinadorExercicioCubit>()
    .state;

/// Joga [uci] tocando a casa de saída e a de chegada.
Future<void> _jogar(WidgetTester tester, String uci) async {
  final move = Move.parse(uci)! as NormalMove;
  final board = find.byKey(TreinadorKeys.exercicioTabuleiro);
  final rect = tester.getRect(board);
  final lado = tester.widget<Chessboard>(board).orientation;
  await tester.tapAt(squareCenter(rect, move.from.name, orientation: lado));
  await tester.pump();
  await tester.tapAt(squareCenter(rect, move.to.name, orientation: lado));
  await assentar(tester);
}

/// Um lance legal que não é a solução do exercício aberto.
String _lanceErrado(WidgetTester tester) {
  final ex = _estado(tester).exercicio!;
  final pos = Chess.fromSetup(Setup.parseFen(ex.fen));
  for (final MapEntry(key: from, value: destinos) in pos.legalMoves.entries) {
    for (final to in destinos.squares) {
      final uci = NormalMove(from: from, to: to).uci;
      if (uci != ex.solucao && !ex.solucao.startsWith(uci)) return uci;
    }
  }
  throw StateError('sem lance errado');
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await assentar(tester);
}

void main() {
  testWidgets('partida que não existe: tela de não encontrado', (tester) async {
    aparelho411x914(tester);
    final bed = TreinadorBed(repo: _repo());
    await bed.abrir(tester, Routes.treinadorExercicios('lichess_naoExiste'));

    expect(find.byType(LoadErrorScreen), findsOneWidget);
    expect(find.byKey(TreinadorKeys.exercicio), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enquanto a partida não chega: esqueleto de carregamento', (
    tester,
  ) async {
    aparelho411x914(tester);
    final repo = _RepoLento();
    final bed = TreinadorBed(repo: repo);
    await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));

    expect(find.byType(LoadSkeletonScreen), findsOneWidget);
    // Não libera a partida (ao chegar, o tabuleiro cairia no BUG abaixo):
    // passados 20 s, a tela vira não encontrado.
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(find.byType(LoadSkeletonScreen), findsNothing);
    expect(find.byType(LoadErrorScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgetsA8('A8: tabuleiro no centro útil e de ponta a ponta', (
    tester,
  ) async {
    setCentroAparelho(tester);
    final bed = TreinadorBed(repo: _repo());
    await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));

    expect(find.byKey(TreinadorKeys.exercicioTabuleiro), findsOneWidget);
    expectTabuleiroNoCentro(tester);
    await tester.pumpWidget(const SizedBox());
  });

  group('fim dos exercícios', () {
    Future<TreinadorBed> abrirFim(
      WidgetTester tester, {
      int acertos = 4,
    }) async {
      aparelho411x914(tester);
      final repo = _repo();
      await repo.salvarProgresso(_idTiago, _progresso(4, acertos: acertos));
      final bed = TreinadorBed(repo: repo);
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      return bed;
    }

    testWidgets('tudo certo: nota, título e contagem, sem overflow', (
      tester,
    ) async {
      await abrirFim(tester);

      expect(find.byKey(TreinadorKeys.fim), findsOneWidget);
      expect(find.byKey(TreinadorKeys.fimNota), findsOneWidget);
      expect(find.text('Resumo da partida'), findsOneWidget);
      expect(find.text('Perfeito!'), findsOneWidget);
      expect(find.textContaining('4 de 4 certos'), findsOneWidget);
      expect(find.textContaining('40 pontos'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.fimAnalise), findsOneWidget);
      expect(find.byKey(TreinadorKeys.fimSeuJogo), findsOneWidget);
      expect(find.byKey(TreinadorKeys.fimFechar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('acertos pela metade: título e contagem mudam', (tester) async {
      await abrirFim(tester, acertos: 2);

      expect(find.text('Perfeito!'), findsNothing);
      expect(find.textContaining('2 de 4 certos'), findsOneWidget);
      expect(find.textContaining('20 pontos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ver a análise completa abre a análise da partida', (
      tester,
    ) async {
      final bed = await abrirFim(tester);
      await _tocar(tester, find.byKey(TreinadorKeys.fimAnalise));

      expect(bed.caminho, Routes.treinadorAnalise(_idTiago));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Onde você mais erra leva à aba Seu jogo', (tester) async {
      final bed = await abrirFim(tester);
      await _tocar(tester, find.byKey(TreinadorKeys.fimSeuJogo));

      expect(bed.caminho, Routes.treinador(aba: 'seuJogo'));
      expect(find.byKey(TreinadorKeys.fim), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Fechar volta para a tela de onde veio', (tester) async {
      final bed = await abrirFim(tester);
      await _tocar(tester, find.byKey(TreinadorKeys.fimFechar));

      expect(bed.caminho, Routes.home);
      expect(find.text('stub.home'), findsOneWidget);
    });

    testWidgets('a seta de voltar também fecha', (tester) async {
      final bed = await abrirFim(tester);
      await _tocar(tester, find.byKey(TreinadorKeys.back));

      expect(bed.caminho, Routes.home);
    });
  });

  group('exercício no tabuleiro', () {
    testWidgets('abre no primeiro: título, estrelas e botão de solução', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));

      expect(find.text('Exercício 1 de 4'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.exercicioTabuleiro), findsOneWidget);
      expect(find.byKey(TreinadorKeys.exercicioEstrelas), findsOneWidget);
      expect(find.byKey(TreinadorKeys.verSolucao), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lance errado: Tentar novamente devolve a posição', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      final fen = _estado(tester).fen;
      await _jogar(tester, _lanceErrado(tester));
      expect(find.byKey(TreinadorKeys.tentarDeNovo), findsOneWidget);
      await _tocar(tester, find.byKey(TreinadorKeys.tentarDeNovo));
      expect(_estado(tester).fen, fen);
      expect(_estado(tester).fase, FaseExercicio.jogando);
    });

    testWidgets('lance certo: Próximo exercício avança o título', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      await _jogar(tester, _estado(tester).exercicio!.solucao);
      expect(find.byKey(TreinadorKeys.proximo), findsOneWidget);
      await _tocar(tester, find.byKey(TreinadorKeys.proximo));
      expect(find.text('Exercício 2 de 4'), findsOneWidget);
    });

    testWidgets('Ver a solução mostra a resposta e libera o próximo', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      await _tocar(tester, find.byKey(TreinadorKeys.verSolucao));
      expect(find.byKey(TreinadorKeys.proximo), findsOneWidget);
    });

    testWidgets('o último exercício leva ao resumo', (tester) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      for (var i = 0; i < 4; i++) {
        await _tocar(tester, find.byKey(TreinadorKeys.verSolucao));
        await _tocar(tester, find.byKey(TreinadorKeys.proximo));
      }
      expect(find.byKey(TreinadorKeys.fim), findsOneWidget);
    });
  });
}
