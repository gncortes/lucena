import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/treinador/view_models/treinador_exercicio_cubit.dart';
import 'package:patrol/patrol.dart';

import '../../testing/board_gestures.dart';
import '../../testing/fakes/fake_treinador_repository.dart';
import '../../testing/treinador_fixtures.dart';

/// O Treinador de partidas (T87): abas, partida, espera, exercícios e fim.
class TreinadorRobot {
  const TreinadorRobot(this.$);

  final PatrolIntegrationTester $;

  static const _espera = Duration(seconds: 20);

  /// Da tela inicial ao Treinador, pelo atalho "Análise".
  Future<void> abrirPelaHome() async {
    await $(HomeKeys.analysisButton).scrollTo().tap();
    await $(TreinadorKeys.screen).waitUntilVisible(timeout: _espera);
  }

  Future<void> aba(Key aba) async {
    await $(aba).tap();
    await $.pumpAndSettle();
  }

  /// Liga a conta do [site] com o [usuario] e confirma.
  Future<void> ligar(Key site, String usuario) async {
    await $(TreinadorKeys.ligarConta).waitUntilVisible(timeout: _espera);
    await $(site).tap();
    await $(TreinadorKeys.usuario).enterText(usuario);
    await $(TreinadorKeys.confirmarConta).tap();
    await $.pumpAndSettle();
  }

  /// Abre a partida [id] pela lista da aba Partidas.
  Future<void> abrirPartida(String id) async {
    await $(TreinadorKeys.partida(id)).scrollTo().tap();
    await $(TreinadorKeys.back).waitUntilVisible(timeout: _espera);
    await $.pumpAndSettle();
  }

  /// A tela de espera tem um relógio de 1 s: avança em passos fixos.
  Future<void> esperarCarregando() async {
    await $(TreinadorKeys.carregando).waitUntilVisible(timeout: _espera);
    await $.pump(const Duration(milliseconds: 500));
  }

  /// O servidor termina a análise de [id] com os exercícios da partida
  /// do Tiago, como o [FakeTreinadorRepository.analisarConclui] faz.
  void concluir(FakeTreinadorRepository fake, String id) {
    final atual = TreinadorFixtures.lista().firstWhere((p) => p.id == id);
    fake.porPartida(
      PartidaTreinador.fromJson(id, {
        ...atual.toJson(),
        ...TreinadorFixtures.tiagoJson(),
        'jogadaEm': atual.jogadaEm.toIso8601String(),
        'adversario': atual.adversario.toJson(),
        'cor': atual.cor.wire,
        'resultado': atual.resultado.wire,
      })!,
    );
  }

  TreinadorExercicioState get _exercicio => $.tester
      .element(find.byKey(TreinadorKeys.exercicio))
      .read<TreinadorExercicioCubit>()
      .state;

  int get indice => _exercicio.indice;

  FaseExercicio get fase => _exercicio.fase;

  Future<void> esperarExercicio() async {
    await $(TreinadorKeys.exercicioTabuleiro)
        .waitUntilVisible(timeout: _espera);
    await $.pumpAndSettle();
  }

  /// Joga a solução do exercício aberto.
  Future<void> acertar() => _jogar(_exercicio.exercicio!.solucao);

  /// Joga um lance legal que não é a solução.
  Future<void> errar() {
    final ex = _exercicio.exercicio!;
    final pos = Chess.fromSetup(Setup.parseFen(ex.fen));
    for (final MapEntry(key: from, value: tos) in pos.legalMoves.entries) {
      for (final to in tos.squares) {
        final uci = NormalMove(from: from, to: to).uci;
        if (uci != ex.solucao && !uci.startsWith(ex.solucao.substring(0, 4))) {
          return _jogar(uci);
        }
      }
    }
    throw StateError('sem lance errado em ${ex.fen}');
  }

  Future<void> _jogar(String uci) async {
    final move = Move.parse(uci)! as NormalMove;
    final board = find.byKey(TreinadorKeys.exercicioTabuleiro);
    final rect = $.tester.getRect(board);
    final lado = $.tester.widget<Chessboard>(board).orientation;
    await $.tester.tapAt(squareCenter(rect, move.from.name, orientation: lado));
    await $.pump();
    await $.tester.tapAt(squareCenter(rect, move.to.name, orientation: lado));
    await $.pumpAndSettle();
  }

  /// Acerta e passa ao próximo (ou à pontuação, no último).
  Future<void> acertarEAvancar() async {
    await acertar();
    await $(TreinadorKeys.proximo).waitUntilVisible(timeout: _espera);
    await $(TreinadorKeys.proximo).tap();
    await $.pumpAndSettle();
  }

  void espera(Key key) =>
      expect(find.byKey(key), findsWidgets, reason: 'faltou $key');

  void naoTem(Key key) =>
      expect(find.byKey(key), findsNothing, reason: 'sobrou $key');
}
