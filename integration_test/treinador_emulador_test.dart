import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';
import 'robots/treinador_robot.dart';

// Treinador de partidas (T87, frente app-análise) contra o Firebase emulator
// com as Functions de verdade (tools/t87_emulador_patrol.sh: projeto
// lucena-dev-gnc, portas próprias, semente da conta `t87-app`). As três
// pessoas do brief: assinante no Lichess (a semente), grátis sem conta do
// Lucena e assinante no chess.com, ligando contas reais dos sites.
const _uid = 't87-app';
const _email = 'treinador@teste.lucena';
const _pronta = 'chesscom_186809755562';
const _erro = 'lichess_iVshKPMF';
const _nova = 'lichess_J3C5rR4Z';

String _partida(String uid, String id) => 'users/$uid/partidas/$id';

/// A semana da cota grátis no servidor (`semanaBR` de politica.ts): a
/// segunda-feira, no fuso de Brasília.
String _semanaBR(DateTime agora) {
  final br = agora.toUtc().subtract(const Duration(hours: 3));
  final segunda = DateTime.utc(
    br.year,
    br.month,
    br.day,
  ).subtract(Duration(days: br.weekday - 1));
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${segunda.year}-${dois(segunda.month)}-${dois(segunda.day)}';
}

Future<void> _entrar(EmulatorRobot app, String email) async {
  await app.openProfile();
  await app.signIn(email, EmulatorAdmin.studentPassword);
  await app.go(Routes.home);
  await $home(app).waitUntilVisible(timeout: const Duration(seconds: 20));
}

PatrolFinder $home(EmulatorRobot app) => app.$(HomeKeys.analysisButton);

/// Espera a lista do Treinador mostrar a partida [id] (o servidor importa
/// e o Firestore manda a lista pela rede do emulador).
Future<void> _esperarNaLista(EmulatorRobot app, String id) => app.pumpUntil(
  () => find.byKey(TreinadorKeys.partida(id)).evaluate().isNotEmpty,
  timeout: const Duration(seconds: 60),
);

/// Tira a conta ligada e a cota de uma rodada anterior: o emulador guarda
/// o Firestore entre as rodadas.
Future<void> _semContaLigada(EmulatorAdmin admin, String uid) async {
  await admin.delete('users/$uid/treinador/conta');
  await admin.delete('treinador_contas/$uid');
}

/// Espera a conta do Treinador chegar (as abas aparecem) depois de abrir.
Future<void> _esperarAbas(EmulatorRobot app) => app.pumpUntil(
  () =>
      find.byKey(TreinadorKeys.tabPartidas).hitTestable().evaluate().isNotEmpty,
);

void main() {
  patrolTest('assinante no Lichess: exercícios gravam no servidor, a análise '
      'marca vista, fechar à força mantém, erro e partida nova vão à fila', (
    $,
  ) async {
    final app = EmulatorRobot($);
    final t = TreinadorRobot($);
    await app.open(
      beforeApp: () async {
        // A semente entra com uma senha de teste conhecida, sem ler a dela.
        await app.admin.setPassword(_uid, EmulatorAdmin.studentPassword);
        await app.admin.merge(_partida(_uid, _pronta), {'progresso': null});
        // Erro e nova como na semente (uma rodada anterior as pôs na fila).
        for (final (id, status) in [(_erro, 'erro'), (_nova, 'nova')]) {
          await app.admin.merge(_partida(_uid, id), {
            'status': status,
            'erroMotivo': status == 'erro' ? 'tempo' : null,
          });
          await app.admin.delete('treinador_fila/${_uid}_$id');
        }
        // O acesso que o painel dá (presente); semente antiga dava "admin".
        await app.admin.merge('acessos/$_uid', {
          'cursos': {
            'treinador': {
              'origem': 'presente',
              'plano': 'teste',
              'dadoPor': 'patrol',
              'dadoEm': DateTime.timestamp(),
            },
          },
        });
      },
    );
    await _entrar(app, _email);
    await t.abrirPelaHome();
    t.espera(TreinadorKeys.tabHoje);
    // O acesso chega pelo Firestore depois de entrar.
    await app.pumpUntil(
      () =>
          find.byKey(TreinadorKeys.semPlano).evaluate().isEmpty &&
          find.byKey(TreinadorKeys.tabPartidas).evaluate().isNotEmpty,
    );

    // As seis partidas da semente chegam pelo Firestore.
    await t.aba(TreinadorKeys.tabPartidas);
    await _esperarNaLista(app, _pronta);
    t.espera(TreinadorKeys.partida(_erro));
    t.espera(TreinadorKeys.partida(_nova));

    // Pronta com dois exercícios: o primeiro errado e depois certo.
    await t.abrirPartida(_pronta);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    await t.errar();
    await $(TreinadorKeys.tentarDeNovo).waitUntilVisible();
    await $(TreinadorKeys.tentarDeNovo).tap();
    await $.pumpAndSettle();
    await t.acertarEAvancar();

    // O resultado vai ao servidor uma vez, como "de primeira" ou não.
    final primeiro = await $.tester.runAsync(
      () => app.admin.waitFor(_partida(_uid, _pronta), (doc) {
        final p = doc?['progresso'];
        return p is Map && (p['resultados'] as Map?)?['1'] != null;
      }),
    );
    expect(
      ((primeiro!['progresso'] as Map)['resultados'] as Map)['1'],
      isFalse,
    );

    // Fechar à força no segundo: volta no segundo.
    await app.restart();
    await t.abrirPelaHome();
    await _esperarAbas(app);
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_pronta);
    await app.pumpUntil(
      () =>
          find.byKey(TreinadorKeys.comecar).hitTestable().evaluate().isNotEmpty,
    );
    await $(TreinadorKeys.comecar).tap();
    await t.esperarExercicio();
    expect(t.indice, 1);
    await t.acertarEAvancar();
    await $(TreinadorKeys.fim).waitUntilVisible();

    // A análise completa: `viuAnalise` no servidor.
    await $(TreinadorKeys.fimAnalise).tap();
    await $(TreinadorKeys.analise).waitUntilVisible();
    final visto = await $.tester.runAsync(
      () => app.admin.waitFor(
        _partida(_uid, _pronta),
        (doc) => (doc?['progresso'] as Map?)?['viuAnalise'] == true,
      ),
    );
    final resultados =
        (visto!['progresso'] as Map)['resultados'] as Map<Object?, Object?>;
    expect(resultados.keys.toSet(), {'1', '2'});
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // Fechar à força: a partida abre no resumo.
    await app.restart();
    await t.abrirPelaHome();
    await _esperarAbas(app);
    await t.aba(TreinadorKeys.tabPartidas);
    await t.abrirPartida(_pronta);
    t.espera(TreinadorKeys.resumo);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // Erro no servidor: "Tentar de novo" põe na fila (sem gastar cota).
    await t.abrirPartida(_erro);
    t.espera(TreinadorKeys.erro);
    await $(TreinadorKeys.erroTentar).tap();
    await t.esperarCarregando();
    await $.tester.runAsync(
      () => app.admin.waitFor(
        _partida(_uid, _erro),
        (doc) => ['na_fila', 'analisando', 'pronta'].contains(doc?['status']),
      ),
    );
    await $.platform.android.pressBack();
    await $.pump(const Duration(seconds: 1));
    t.espera(TreinadorKeys.partidas);

    // Nova: "Analisar" pede ao servidor e a tela espera.
    await t.abrirPartida(_nova);
    await $(TreinadorKeys.comecar).tap();
    await t.esperarCarregando();
    await $.tester.runAsync(
      () => app.admin.waitFor(
        _partida(_uid, _nova),
        (doc) => ['na_fila', 'analisando', 'pronta'].contains(doc?['status']),
      ),
    );
    await $.platform.android.pressBack();
    await $.pump(const Duration(seconds: 1));
    t.espera(TreinadorKeys.partidas);
  });

  patrolTest('grátis sem conta do Lucena: ligar pede a conta; com a conta, '
      'liga o Lichess de verdade e a cota da semana leva à venda', ($) async {
    final app = EmulatorRobot($);
    final t = TreinadorRobot($);
    final email = EmulatorAdmin.student(87);
    late String uid;
    await app.open(
      beforeApp: () async {
        uid = (await app.admin.signIn(
          email,
          EmulatorAdmin.studentPassword,
          create: true,
        )).uid;
        await _semContaLigada(app.admin, uid);
      },
    );

    // Sem conta do Lucena: o pedido de entrar.
    await t.abrirPelaHome();
    await t.ligar(TreinadorKeys.ligarLichess, 'penguingim1');
    t.espera(TreinadorKeys.contaErro);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    expect($home(app), findsOneWidget);

    // Com a conta: liga a conta real do Lichess e as partidas chegam.
    await _entrar(app, email);
    await t.abrirPelaHome();
    await t.ligar(TreinadorKeys.ligarLichess, 'penguingim1');
    await app.pumpUntil(
      () => find.byKey(TreinadorKeys.tabHoje).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    t.espera(TreinadorKeys.semPlano);

    // Cota da semana gasta; uma partida nova: "Analisar" leva à venda.
    final modelo = await $.tester.runAsync(
      () => app.admin.read(_partida(_uid, _nova)),
    );
    await $.tester.runAsync(() async {
      await app.admin.merge('treinador_contas/$uid', {
        'semana': {'id': _semanaBR(DateTime.timestamp()), 'n': 3},
      });
      await app.admin.write(_partida(uid, _nova), {
        for (final e in modelo!.entries)
          if (e.value is String || e.value is int || e.value is Map) ...{
            e.key: e.value,
          },
        'status': 'nova',
        'jogadaEm': DateTime.timestamp(),
      });
    });
    await t.aba(TreinadorKeys.tabPartidas);
    await _esperarNaLista(app, _nova);
    await t.abrirPartida(_nova);
    await $(TreinadorKeys.comecar).tap();
    await app.pumpUntil(
      () => find.byKey(TreinadorKeys.inicio).evaluate().isEmpty,
      timeout: const Duration(seconds: 30),
    );
    t.naoTem(TreinadorKeys.carregando);
    final doc = await $.tester.runAsync(
      () => app.admin.read(_partida(uid, _nova)),
    );
    expect(doc!['status'], 'nova', reason: 'a cota não deixou entrar na fila');
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.espera(TreinadorKeys.inicio);
  });

  patrolTest('assinante no chess.com: liga a conta real e as partidas '
      'importadas aparecem na lista', ($) async {
    final app = EmulatorRobot($);
    final t = TreinadorRobot($);
    final email = EmulatorAdmin.student(88);
    await app.open(
      beforeApp: () async {
        final uid = (await app.admin.signIn(
          email,
          EmulatorAdmin.studentPassword,
          create: true,
        )).uid;
        await _semContaLigada(app.admin, uid);
        await app.admin.write('acessos/$uid', {
          'cursos': {
            'treinador': {
              'origem': 'presente',
              'plano': 'teste',
              'dadoPor': 'patrol',
              'dadoEm': DateTime.timestamp(),
            },
          },
        });
      },
    );
    await _entrar(app, email);
    await t.abrirPelaHome();
    await t.ligar(TreinadorKeys.ligarChesscom, 'hikaru');
    await app.pumpUntil(
      () => find.byKey(TreinadorKeys.tabHoje).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    await app.pumpUntil(
      () => find.byKey(TreinadorKeys.semPlano).evaluate().isEmpty,
    );
    await t.aba(TreinadorKeys.tabPartidas);
    await app.pumpUntil(
      () => find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'treinador.partida.chesscom_',
                ),
          )
          .evaluate()
          .isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    expect($home(app), findsOneWidget);
  });
}
