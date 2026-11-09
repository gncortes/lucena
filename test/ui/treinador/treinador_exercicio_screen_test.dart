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
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/lesson_script/widgets/script_move_list.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/core/widgets/move_highlight.dart';
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
      expect(find.text('4 de 4 certos'), findsOneWidget);
      expect(find.text('Sua partida contra Tiago_Rook · 5+0'), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        expect(find.byKey(TreinadorKeys.fimBolinha(n)), findsOneWidget);
      }
      expect(find.byKey(TreinadorKeys.fimAnalise), findsOneWidget);
      expect(find.byKey(TreinadorKeys.fimSeuJogo), findsOneWidget);
      expect(find.byKey(TreinadorKeys.fimFechar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('acertos pela metade: título e contagem mudam', (tester) async {
      await abrirFim(tester, acertos: 2);

      expect(find.text('4 de 4 certos'), findsNothing);
      expect(find.text('2 de 4 certos'), findsOneWidget);
      // Verde nos certos, vermelho nos errados.
      Color? cor(int n) =>
          ((tester
                      .widget<Container>(
                        find.descendant(
                          of: find.byKey(TreinadorKeys.fimBolinha(n)),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration)!
                  as BoxDecoration)
              .color;
      expect(cor(1), AppColors.trainingDayCorrect);
      expect(cor(2), AppColors.trainingDayCorrect);
      expect(cor(3), AppColors.trainingDayWrong);
      expect(cor(4), AppColors.trainingDayWrong);
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

    testWidgets('o X leva a fechar: sem a seta de voltar', (tester) async {
      await abrirFim(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byKey(TreinadorKeys.back), findsNothing);
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

    testWidgets('estrela cheia vale pontos; vazia depois do erro', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      IconData? estrela() =>
          tester.widget<Icon>(find.byKey(TreinadorKeys.exercicioEstrelas)).icon;
      expect(estrela(), Icons.star_rounded);
      await _jogar(tester, _lanceErrado(tester));
      expect(estrela(), Icons.star_outline_rounded);
    });

    testWidgets(
      'dica: marca a peça, depois o lance; a estrela segue cheia enquanto vale pontos',
      (tester) async {
        aparelho411x914(tester);
        final bed = TreinadorBed(repo: _repo());
        await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
        final solucao =
            Move.parse(_estado(tester).exercicio!.solucao)! as NormalMove;
        Set<Shape> marcas() => tester
            .widget<Chessboard>(find.byKey(TreinadorKeys.exercicioTabuleiro))
            .shapes;
        IconData? estrela() => tester
            .widget<Icon>(find.byKey(TreinadorKeys.exercicioEstrelas))
            .icon;
        final dica = find.byKey(TreinadorKeys.dica);
        expect(dica, findsOneWidget);
        expect(
          tester.widget<IconButton>(dica).tooltip,
          'Dica (custa um ponto)',
        );
        expect(marcas(), isEmpty);

        await _tocar(tester, dica);
        expect(estrela(), Icons.star_rounded);
        expect(marcas().single, isA<Circle>());
        expect((marcas().single as Circle).orig, solucao.from);

        await _tocar(tester, dica);
        final seta = marcas().single as Arrow;
        expect((seta.orig, seta.dest), (solucao.from, solucao.to));
        // O lance já está à vista: a lâmpada sai.
        expect(dica, findsNothing);

        await _jogar(tester, solucao.uci);
        expect(_estado(tester).progresso.resultados.single.pontos, 1);
        expect(_estado(tester).progresso.resultados.single.dicas, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dica some no erro e depois de resolver', (tester) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      await _jogar(tester, _lanceErrado(tester));
      expect(find.byKey(TreinadorKeys.dica), findsNothing);
      await _tocar(tester, find.byKey(TreinadorKeys.tentarDeNovo));
      // Depois do erro, a dica zera o exercício.
      expect(
        tester.widget<IconButton>(find.byKey(TreinadorKeys.dica)).tooltip,
        'Dica (o exercício deixa de pontuar)',
      );
      await _tocar(tester, find.byKey(TreinadorKeys.verSolucao));
      expect(find.byKey(TreinadorKeys.dica), findsNothing);
    });

    testWidgets('notação: o lance errado leva "?"; a solução vem em SAN', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo());
      await bed.abrir(tester, Routes.treinadorExercicios(_idTiago));
      expect(find.byType(ScriptMoveList), findsNothing);
      await _jogar(tester, _lanceErrado(tester));
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
      final caixa = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ScriptMoveList),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final cores = Theme.of(tester.element(find.byType(ScriptMoveList)))
          .colorScheme;
      expect(
        caixa.decoration,
        MoveHighlight.outlinedDecoration(cores, selected: true),
      );
      await _tocar(tester, find.byKey(TreinadorKeys.verSolucao));
      final lance = tester
          .widget<ScriptMoveList>(find.byType(ScriptMoveList))
          .moves
          .single;
      expect(lance.symbol, '!');
      expect(lance.san, isNotEmpty);
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
