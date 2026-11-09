import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/treinador/view_models/treinador_exercicio_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/fakes/fake_course_grants.dart';
import '../testing/fakes/fake_treinador_repository.dart';
import '../testing/treinador_fixtures.dart';
import 'robots/app_robot.dart';
import 'robots/treinador_robot.dart';

// Treinador de partidas (T87, frente app-análise): as três pessoas do brief
// (grátis sem conta, assinante no Lichess, assinante no chess.com) e os
// erros do servidor, com Voltar do sistema e da seta, segundo plano e
// fechar à força no meio da espera, do exercício e da pontuação.
const _nova = 'lichess_DeF67890';
const _analisando = 'lichess_GhI13579';
const _derrota = 'lichess_JkL24680';

FakeCourseGrantsRepository _assinante() => FakeCourseGrantsRepository()
  ..current = const CourseGrants(
    courses: {'treinador': CourseGrant(origin: GrantOrigin.gift)},
  );

void main() {
  patrolTest('grátis sem conta: liga o Lichess (erros antes), vê o plano e '
      'a cota leva à venda', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final fake = FakeTreinadorRepository(partidas: TreinadorFixtures.lista());
    await app.open(treinador: fake);
    await t.abrirPelaHome();
    // Canvas DLigarConta: a barra das abas já aparece no passo de ligar.
    t.espera(TreinadorKeys.ligarConta);

    // A conta não existe.
    fake.falhaLigar = FalhaLigarConta.naoExiste;
    await t.ligar(TreinadorKeys.ligarLichess, 'ninguem_aqui');
    t.espera(TreinadorKeys.contaErro);

    // Sem internet (ou o Lichess fora do ar).
    fake.falhaLigar = FalhaLigarConta.semResposta;
    await $(TreinadorKeys.confirmarConta).tap();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.contaErro);

    // A conta do Lucena sem o direito: o botão do plano aparece.
    fake.falhaLigar = FalhaLigarConta.semPlano;
    await $(TreinadorKeys.confirmarConta).tap();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.conhecerPlano);

    // Troca de site e volta ao Lichess: agora liga.
    await $(TreinadorKeys.trocarSite).tap();
    await $.pumpAndSettle();
    await t.ligar(TreinadorKeys.ligarLichess, ' gabriel_lucena ');
    expect(fake.ligacoes.last, (Plataforma.lichess, 'gabriel_lucena'));
    await $(TreinadorKeys.tabHoje).waitUntilVisible();
    t.espera(TreinadorKeys.semPlano);

    // A cota da semana acabou: "Analisar" leva à venda; Voltar devolve.
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_nova);
    fake
      ..falhaAnalisar = 'permission-denied'
      ..motivoAnalisar = 'cota';
    await $(TreinadorKeys.comecar).tap();
    await $.pumpAndSettle();
    t.naoTem(TreinadorKeys.inicio);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.inicio);

    // Seta e Voltar do sistema até a tela inicial.
    await $(TreinadorKeys.back).tap();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.partidas);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    expect(find.byKey(HomeKeys.analysisButton), findsOneWidget);
  });

  patrolTest('assinante no Lichess: espera com segundo plano e fechar à '
      'força, exercícios com erro e Voltar no meio, pontuação e análise', (
    $,
  ) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final fake = FakeTreinadorRepository.comDados();
    await app.open(treinador: fake, courseGrants: _assinante());
    await t.abrirPelaHome();
    t.espera(TreinadorKeys.ultimaPartida);
    t.naoTem(TreinadorKeys.semPlano);

    // Pede a análise de uma partida nova: a espera.
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_nova);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarCarregando();
    expect(fake.pedidosAnalise.single, (_nova, false));

    // Segundo plano no meio da espera: continua esperando.
    await app.sendToBackgroundFor(const Duration(seconds: 40));
    await t.esperarCarregando();

    // Voltar do sistema na espera: a lista.
    await $.platform.android.pressBack();
    await $.pump(const Duration(seconds: 1));
    t.espera(TreinadorKeys.partidas);

    // "Me avise" pede o aviso e também volta à lista.
    await t.abrirPartida(_nova);
    await t.esperarCarregando();
    await $(TreinadorKeys.meAvise).tap();
    await $.pump(const Duration(seconds: 1));
    expect(fake.pedidosAnalise.last, (_nova, true));
    t.espera(TreinadorKeys.partidas);

    // Fechar à força na espera: a partida segue "analisando".
    await t.abrirPartida(_nova);
    await t.esperarCarregando();
    await app.restart();
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_nova);
    await t.esperarCarregando();

    // O servidor termina: a tela troca sozinha para os exercícios.
    t.concluir(fake, _nova);
    await $(TreinadorKeys.inicio).waitUntilVisible();
    await $.pumpAndSettle();
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();

    // Erra o primeiro, tenta de novo e acerta.
    await t.errar();
    await $(TreinadorKeys.tentarDeNovo).waitUntilVisible();
    expect(t.fase, FaseExercicio.errou);
    await $(TreinadorKeys.tentarDeNovo).tap();
    await $.pumpAndSettle();
    expect(t.fase, FaseExercicio.jogando);
    await t.acertarEAvancar();
    expect(t.indice, 1);

    // Voltar do sistema no meio do segundo: a partida mostra "Continuar".
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.inicio);

    // Segundo plano no exercício e fechar à força: volta ao segundo.
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    expect(t.indice, 1);
    await app.sendToBackgroundFor(const Duration(minutes: 5));
    await t.esperarExercicio();
    expect(t.indice, 1);
    await app.restart();
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_nova);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    expect(t.indice, 1);

    // Seta no meio do exercício também volta à partida.
    await $(TreinadorKeys.back).tap();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.inicio);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();

    // Os três que faltam, até a pontuação.
    await t.acertarEAvancar();
    await t.acertarEAvancar();
    await t.acertarEAvancar();
    await $(TreinadorKeys.fim).waitUntilVisible();
    t.espera(TreinadorKeys.fimNota);

    // Segundo plano e fechar à força na pontuação: a partida vai ao resumo.
    await app.sendToBackgroundFor(const Duration(minutes: 1));
    t.espera(TreinadorKeys.fim);
    await $(TreinadorKeys.fimAnalise).tap();
    await $(TreinadorKeys.analise).waitUntilVisible();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    await app.restart();
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_nova);
    t.espera(TreinadorKeys.resumo);
  });

  patrolTest('assinante no chess.com: filtros, resumo, posição-chave e '
      'análise completa', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final fake = FakeTreinadorRepository.comDados()
      ..contaAtual = const TreinadorConta(
        plataforma: Plataforma.chesscom,
        usuario: 'gabriel_cc',
      );
    await fake.salvarProgresso(
      TreinadorFixtures.idTiago,
      const ProgressoPartida(
        feitosRemoto: 4,
        acertosRemoto: 3,
        pontosRemoto: 30,
      ),
    );
    await app.open(treinador: fake, courseGrants: _assinante());
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);

    await $(TreinadorKeys.filtroRitmo('blitz')).tap();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.partida(_analisando));
    t.naoTem(TreinadorKeys.partida(_nova));
    await $(TreinadorKeys.filtroTodas).tap();
    await $(TreinadorKeys.filtroResultado('derrota')).tap();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.partida(_derrota));
    t.naoTem(TreinadorKeys.partida(_nova));
    await $(TreinadorKeys.filtroTodas).tap();
    await $.pumpAndSettle();

    // Partida já feita: abre no resumo.
    await t.abrirPartida(TreinadorFixtures.idTiago);
    t.espera(TreinadorKeys.resumo);
    await $(TreinadorKeys.posicaoChave(1)).scrollTo().tap();
    await $(TreinadorKeys.analise).waitUntilVisible();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.resumo);
    await $(TreinadorKeys.resumoAnalise).scrollTo().tap();
    await $(TreinadorKeys.analise).waitUntilVisible();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // Refazer abre os exercícios do começo.
    await $(TreinadorKeys.refazer).scrollTo().tap();
    await t.esperarExercicio();
    expect(t.indice, 0);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.resumo);
  });

  patrolTest('erros: análise com erro no servidor, pedido sem rede e partida '
      'que sumiu', ($) async {
    final app = AppRobot($);
    final t = TreinadorRobot($);
    final fake = FakeTreinadorRepository.comDados();
    fake.porPartida(
      TreinadorFixtures.lista()
          .firstWhere((p) => p.id == _analisando)
          .copyWith(status: StatusPartida.erro),
    );
    await app.open(treinador: fake, courseGrants: _assinante());
    await t.abrirPelaHome();
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_analisando);
    t.espera(TreinadorKeys.erro);

    // "Tentar de novo" sem rede: avisa e fica no erro.
    fake.falhaAnalisar = 'unavailable';
    await $(TreinadorKeys.erroTentar).tap();
    await $.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    t.espera(TreinadorKeys.erro);

    // Com rede: a espera.
    fake.falhaAnalisar = null;
    await $(TreinadorKeys.erroTentar).tap();
    await t.esperarCarregando();
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // A partida some do servidor com a tela aberta.
    await t.abrirPartida(_derrota);
    fake.partidasAtuais = [
      for (final p in TreinadorFixtures.lista())
        if (p.id != _derrota) p,
    ];
    await $.pumpAndSettle();
    t.naoTem(TreinadorKeys.inicio);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.partidas);
    t.naoTem(TreinadorKeys.partida(_derrota));
  });
}
