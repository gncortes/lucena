import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/movimento_reduzido.dart';
import 'package:lucena/ui/core/motion/tabuleiro_animado.dart';
import 'package:lucena/ui/core/motion/tabuleiro_hero.dart';

/// H-ANI-10: o tabuleiro de [boardKey] está dentro do [TabuleiroAnimado] e
/// desliza a peça no tempo do kit (300 ms; nada com movimento reduzido).
void expectTabuleiroAnimado(WidgetTester tester, Key boardKey) {
  final board = find.byKey(boardKey);
  expect(
    find.ancestor(of: board, matching: find.byType(TabuleiroAnimado)),
    findsOneWidget,
  );
  expect(
    tester.widget<Chessboard>(board).settings.animationDuration,
    TabuleiroAnimado.duracaoDoLance(tester.element(board)),
  );
}

/// H-ANI-11/12: o retorno do lance está sobre o tabuleiro de [boardKey], com a
/// casa pintada e o selo ([Icons.check] no acerto, [Icons.close] no erro) na
/// peça.
void expectRetornoDoLance(
  WidgetTester tester,
  Key boardKey, {
  required bool acerto,
}) {
  expect(
    find.ancestor(
      of: find.byKey(boardKey),
      matching: find.byKey(MotionKeys.tabuleiroDoRetorno),
    ),
    findsOneWidget,
  );
  Finder selo(IconData icone) => find.descendant(
    of: find.byKey(MotionKeys.seloNaPeca),
    matching: find.byIcon(icone),
  );
  expect(selo(acerto ? Icons.check : Icons.close), findsOneWidget);
  expect(selo(acerto ? Icons.close : Icons.check), findsNothing);
}

/// Sem retorno do lance na tela.
void expectSemRetornoDoLance() {
  expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsNothing);
}

/// A opacidade da [parte] de uma entrada do kit: o primeiro `Opacity` dentro
/// dela, ou 1 quando ela não anima (pronta).
double opacidadeDaParte(WidgetTester tester, Finder parte) {
  final achados = find.descendant(of: parte, matching: find.byType(Opacity));
  return achados.evaluate().isEmpty
      ? 1
      : tester.widget<Opacity>(achados.first).opacity;
}

/// H-ANI-25: o resultado se monta pela [EntradaDeResultado], com as [partes]
/// (`estrela`, `titulo`, `subtitulo`, `placar`, `viktor`, `botoes`) e
/// [bolinhas] bolinhas. Chame logo depois de montar a tela: com [animando],
/// os botões ainda não apareceram; sem (movimento reduzido ou resultado já
/// visto), tudo já está pronto.
void expectEntradaDeResultado(
  WidgetTester tester, {
  required List<String> partes,
  int bolinhas = 0,
  required bool animando,
}) {
  for (final nome in partes) {
    expect(
      find.byKey(MotionKeys.parteDoResultado(nome)),
      findsOneWidget,
      reason: nome,
    );
  }
  for (var i = 0; i < bolinhas; i++) {
    expect(find.byKey(MotionKeys.bolinhaDoResultado(i)), findsOneWidget);
  }
  expect(find.byKey(MotionKeys.bolinhaDoResultado(bolinhas)), findsNothing);
  final ultima = partes.last;
  expect(
    opacidadeDaParte(tester, find.byKey(MotionKeys.parteDoResultado(ultima))),
    animando ? 0 : 1,
    reason: '$ultima no primeiro quadro',
  );
}

/// H-ANI-16: o texto da tela entra pela [EntradaEmCascata], com [itens]
/// itens. Chame logo depois de montar a tela: com [animando], o último item
/// ainda não apareceu; sem, tudo pronto.
void expectEntradaEmCascata(
  WidgetTester tester, {
  required int itens,
  required bool animando,
}) {
  for (var i = 0; i < itens; i++) {
    expect(find.byKey(MotionKeys.itemDaCascata(i)), findsOneWidget);
  }
  expect(find.byKey(MotionKeys.itemDaCascata(itens)), findsNothing);
  expect(
    opacidadeDaParte(tester, find.byKey(MotionKeys.itemDaCascata(itens - 1))),
    animando ? 0 : 1,
  );
}

/// H-ANI-02: o tabuleiro de [boardKey] está no [TabuleiroHero] de [id]; sem
/// movimento reduzido, o `Hero` tem a marca `tabuleiro-<id>`.
void expectTabuleiroHero(WidgetTester tester, Key boardKey, String id) {
  final hero = find.ancestor(
    of: find.byKey(boardKey),
    matching: find.byType(TabuleiroHero),
  );
  expect(hero, findsOneWidget);
  expect(tester.widget<TabuleiroHero>(hero).id, id);
  final reduzido = MovimentoReduzido.of(tester.element(find.byKey(boardKey)));
  expect(
    find.ancestor(
      of: find.byKey(boardKey),
      matching: find.byWidgetPredicate(
        (w) => w is Hero && w.tag == TabuleiroHero.tag(id),
      ),
    ),
    reduzido ? findsNothing : findsOneWidget,
  );
}
