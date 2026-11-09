import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/emulator_admin.dart';
import 'robots/emulator_robot.dart';
import 'robots/coach_robot.dart';

// Treinador de partidas (T87, frente app-análise) contra o Firebase emulator
// com as Functions de verdade (tools/t87_emulador_patrol.sh: projeto
// lucena-dev-gnc, portas próprias, semente da conta `t87-app`). As três
// pessoas do brief: assinante no Lichess (a semente), grátis sem conta do
// Lucena e assinante no chess.com, ligando contas reais dos sites.
const _uid = 't87-app';
const _email = 'treinador@teste.lucena';
const _ready = 'chesscom_186809755562';
const _error = 'lichess_iVshKPMF';
const _new = 'lichess_J3C5rR4Z';

String _game(String uid, String id) => 'users/$uid/partidas/$id';

/// A semana da cota grátis no servidor (`semanaBR` de politica.ts): a
/// segunda-feira, no fuso de Brasília.
String _weekBr(DateTime currentTime) {
  final br = currentTime.toUtc().subtract(const Duration(hours: 3));
  final second = DateTime.utc(
    br.year,
    br.month,
    br.day,
  ).subtract(Duration(days: br.weekday - 1));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${second.year}-${two(second.month)}-${two(second.day)}';
}

Future<void> _signIn(EmulatorRobot app, String email) async {
  await app.openProfile();
  await app.signIn(email, EmulatorAdmin.studentPassword);
  await app.go(Routes.home);
  await $home(app).waitUntilVisible(timeout: const Duration(seconds: 20));
}

PatrolFinder $home(EmulatorRobot app) => app.$(HomeKeys.analysisButton);

/// Espera a lista do Treinador mostrar a partida [id] (o servidor importa
/// e o Firestore manda a lista pela rede do emulador).
Future<void> _waitInList(EmulatorRobot app, String id) => app.pumpUntil(
  () => find.byKey(CoachKeys.game(id)).evaluate().isNotEmpty,
  timeout: const Duration(seconds: 60),
);

/// Tira a conta ligada e a cota de uma rodada anterior: o emulador guarda
/// o Firestore entre as rodadas.
Future<void> _noLinkedAccount(EmulatorAdmin admin, String uid) async {
  await admin.delete('users/$uid/treinador/conta');
  await admin.delete('treinador_contas/$uid');
}

/// Espera a conta do Treinador chegar (as abas aparecem) depois de abrir.
Future<void> _waitTabs(EmulatorRobot app) => app.pumpUntil(
  () => find.byKey(CoachKeys.tabGames).hitTestable().evaluate().isNotEmpty,
);

void main() {
  patrolTest('assinante no Lichess: exercícios gravam no servidor, a análise '
      'marca vista, fechar à força mantém, erro e partida nova vão à fila', (
    $,
  ) async {
    final app = EmulatorRobot($);
    final t = CoachRobot($);
    await app.open(
      beforeApp: () async {
        // A semente entra com uma senha de teste conhecida, sem ler a dela.
        await app.admin.setPassword(_uid, EmulatorAdmin.studentPassword);
        await app.admin.merge(_game(_uid, _ready), {'progresso': null});
        // Erro e nova como na semente (uma rodada anterior as pôs na fila).
        for (final (id, status) in [(_error, 'erro'), (_new, 'nova')]) {
          await app.admin.merge(_game(_uid, id), {
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
    await _signIn(app, _email);
    await t.openFromHome();
    t.wait(CoachKeys.tabToday);
    // O acesso chega pelo Firestore depois de entrar.
    await app.pumpUntil(
      () =>
          find.byKey(CoachKeys.noPlan).evaluate().isEmpty &&
          find.byKey(CoachKeys.tabGames).evaluate().isNotEmpty,
    );

    // As seis partidas da semente chegam pelo Firestore.
    await t.tab(CoachKeys.tabGames);
    await _waitInList(app, _ready);
    t.wait(CoachKeys.game(_error));
    t.wait(CoachKeys.game(_new));

    // Pronta com dois exercícios: o primeiro errado e depois certo.
    await t.openGame(_ready);
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    await t.miss();
    await $(CoachKeys.retry).waitUntilVisible();
    await $(CoachKeys.retry).tap();
    await $.pumpAndSettle();
    await t.solveAndAdvance();

    // O resultado vai ao servidor uma vez, como "de primeira" ou não.
    final firstOne = await $.tester.runAsync(
      () => app.admin.waitFor(_game(_uid, _ready), (doc) {
        final p = doc?['progresso'];
        return p is Map && (p['resultados'] as Map?)?['1'] != null;
      }),
    );
    expect(
      ((firstOne!['progresso'] as Map)['resultados'] as Map)['1'],
      isFalse,
    );

    // Fechar à força no segundo: volta no segundo.
    await app.restart();
    await t.openFromHome();
    await _waitTabs(app);
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_ready);
    await app.pumpUntil(
      () => find.byKey(CoachKeys.begin).hitTestable().evaluate().isNotEmpty,
    );
    await $(CoachKeys.begin).tap();
    await t.waitExercise();
    expect(t.index, 1);
    await t.solveAndAdvance();
    await $(CoachKeys.end).waitUntilVisible();

    // A análise completa: `viuAnalise` no servidor.
    await $(CoachKeys.analysisEnd).tap();
    await $(CoachKeys.analysis).waitUntilVisible();
    final seen = await $.tester.runAsync(
      () => app.admin.waitFor(
        _game(_uid, _ready),
        (doc) => (doc?['progresso'] as Map?)?['viuAnalise'] == true,
      ),
    );
    final results =
        (seen!['progresso'] as Map)['resultados'] as Map<Object?, Object?>;
    expect(results.keys.toSet(), {'1', '2'});
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // Fechar à força: a partida abre no resumo.
    await app.restart();
    await t.openFromHome();
    await _waitTabs(app);
    await t.tab(CoachKeys.tabGames);
    await t.openGame(_ready);
    t.wait(CoachKeys.summary);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();

    // Erro no servidor: "Tentar de novo" põe na fila (sem gastar cota).
    await t.openGame(_error);
    t.wait(CoachKeys.error);
    await $(CoachKeys.errorRetry).tap();
    await t.waitLoading();
    await $.tester.runAsync(
      () => app.admin.waitFor(
        _game(_uid, _error),
        (doc) => ['na_fila', 'analisando', 'pronta'].contains(doc?['status']),
      ),
    );
    await $.platform.android.pressBack();
    await $.pump(const Duration(seconds: 1));
    t.wait(CoachKeys.games);

    // Nova: "Analisar" pede ao servidor e a tela espera.
    await t.openGame(_new);
    await $(CoachKeys.begin).tap();
    await t.waitLoading();
    await $.tester.runAsync(
      () => app.admin.waitFor(
        _game(_uid, _new),
        (doc) => ['na_fila', 'analisando', 'pronta'].contains(doc?['status']),
      ),
    );
    await $.platform.android.pressBack();
    await $.pump(const Duration(seconds: 1));
    t.wait(CoachKeys.games);
  });

  patrolTest('grátis sem conta do Lucena: ligar pede a conta; com a conta, '
      'liga o Lichess de verdade e a cota da semana leva à venda', ($) async {
    final app = EmulatorRobot($);
    final t = CoachRobot($);
    final email = EmulatorAdmin.student(87);
    late String uid;
    await app.open(
      beforeApp: () async {
        uid = (await app.admin.signIn(
          email,
          EmulatorAdmin.studentPassword,
          create: true,
        )).uid;
        await _noLinkedAccount(app.admin, uid);
      },
    );

    // Sem conta do Lucena: o pedido de entrar.
    await t.openFromHome();
    await t.link(CoachKeys.linkLichess, 'penguingim1');
    t.wait(CoachKeys.accountError);
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    expect($home(app), findsOneWidget);

    // Com a conta: liga a conta real do Lichess e as partidas chegam.
    await _signIn(app, email);
    await t.openFromHome();
    await t.link(CoachKeys.linkLichess, 'penguingim1');
    await app.pumpUntil(
      () => find.byKey(CoachKeys.tabToday).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    t.wait(CoachKeys.noPlan);

    // Cota da semana gasta; uma partida nova: "Analisar" leva à venda.
    final modelGame = await $.tester.runAsync(
      () => app.admin.read(_game(_uid, _new)),
    );
    await $.tester.runAsync(() async {
      await app.admin.merge('treinador_contas/$uid', {
        'semana': {'id': _weekBr(DateTime.timestamp()), 'n': 3},
      });
      await app.admin.write(_game(uid, _new), {
        for (final e in modelGame!.entries)
          if (e.value is String || e.value is int || e.value is Map) ...{
            e.key: e.value,
          },
        'status': 'nova',
        'jogadaEm': DateTime.timestamp(),
      });
    });
    await t.tab(CoachKeys.tabGames);
    await _waitInList(app, _new);
    await t.openGame(_new);
    await $(CoachKeys.begin).tap();
    await app.pumpUntil(
      () => find.byKey(CoachKeys.start).evaluate().isEmpty,
      timeout: const Duration(seconds: 30),
    );
    t.hasNot(CoachKeys.loading);
    final doc = await $.tester.runAsync(() => app.admin.read(_game(uid, _new)));
    expect(doc!['status'], 'nova', reason: 'a cota não deixou entrar na fila');
    await $.platform.android.pressBack();
    await $.pumpAndSettle();
    t.wait(CoachKeys.start);
  });

  patrolTest('assinante no chess.com: liga a conta real e as partidas '
      'importadas aparecem na lista', ($) async {
    final app = EmulatorRobot($);
    final t = CoachRobot($);
    final email = EmulatorAdmin.student(88);
    await app.open(
      beforeApp: () async {
        final uid = (await app.admin.signIn(
          email,
          EmulatorAdmin.studentPassword,
          create: true,
        )).uid;
        await _noLinkedAccount(app.admin, uid);
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
    await _signIn(app, email);
    await t.openFromHome();
    await t.link(CoachKeys.linkChesscom, 'hikaru');
    await app.pumpUntil(
      () => find.byKey(CoachKeys.tabToday).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    await app.pumpUntil(() => find.byKey(CoachKeys.noPlan).evaluate().isEmpty);
    await t.tab(CoachKeys.tabGames);
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
