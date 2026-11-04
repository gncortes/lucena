import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/abertura_animada.dart';

import 'entrada_helpers.dart';

/// H-ANI-44: a abertura em fases (entrada, roscas em laço, final, saída).
void main() {
  late Completer<void> carga;
  late int agora;
  var terminou = 0;

  Widget app({bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: AberturaAnimada(
      carga: carga.future,
      aoTerminar: () => terminou++,
      child: const MaterialApp(home: Scaffold(body: Text('Início'))),
    ),
  );

  /// Monta e roda o primeiro quadro do relógio (tempo 0).
  Future<void> abre(WidgetTester tester, {bool reduzir = false}) async {
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(reduzir: reduzir));
    await tester.pump();
    agora = 0;
  }

  Future<void> ate(WidgetTester tester, int ms) async {
    await tester.pump(Duration(milliseconds: ms - agora));
    agora = ms;
  }

  PoseDoMascote pose(WidgetTester tester) =>
      (tester.widget<CustomPaint>(find.byKey(MotionKeys.mascote)).painter!
              as MascotePainter)
          .pose;

  double luzDoNome(WidgetTester tester) =>
      opacidadeAcima(tester, find.text('Lucena'));

  bool abertura(WidgetTester tester) =>
      find.byKey(MotionKeys.abertura).evaluate().isNotEmpty;

  /// O `Completer` nasce dentro do teste: criado no `setUp`, ele fica fora
  /// do relógio falso e o `then` só roda depois do teste.
  void teste(String nome, Future<void> Function(WidgetTester) corpo) =>
      testWidgets(nome, (tester) async {
        carga = Completer<void>();
        terminou = 0;
        await corpo(tester);
      });

  teste('entrada e roscas pelos valores do MascotePainter', (tester) async {
    carga.complete();
    await abre(tester);
    final inicio = pose(tester);
    expect(inicio.opacidadeAtras, 1);
    expect(inicio.bracoE.opacidade, 0);

    await ate(tester, 180);
    expect(pose(tester).escalaX, closeTo(1.04, .001));
    expect(pose(tester).escalaY, closeTo(.96, .001));

    await ate(tester, 500);
    expect(pose(tester).opacidadeAtras, 0);
    expect(pose(tester).bracoE.opacidade, closeTo(1, .03));
    expect(pose(tester).bracoD.opacidade, closeTo(1, .03));

    await ate(tester, 680);
    expect(pose(tester).bracoE.angulo, closeTo(0, .01));
    expect(pose(tester).bracoD.angulo, closeTo(58, .01));

    await ate(tester, 1000);
    expect(pose(tester).bracoD.angulo, closeTo(0, .01));
    expect(pose(tester).bracoE.angulo, closeTo(58, .01));
  });

  teste('carga pronta no quadro 0: final em 1160, saída em 1860', (
    tester,
  ) async {
    carga.complete();
    await abre(tester);
    await ate(tester, 1150);
    expect(luzDoNome(tester), 0);
    expect(pose(tester).bracoE.angulo, closeTo(58, 1));
    await ate(tester, 1260);
    // O final começou em 1160: os halteres sobem ao alto em 200 ms.
    expect(pose(tester).bracoE.angulo, lessThan(58));
    await ate(tester, 1610);
    expect(luzDoNome(tester), 1);
    expect(pose(tester).bracoE.angulo, 0);
    expect(pose(tester).bracoD.angulo, 0);

    await ate(tester, 1850);
    expect(opacidadeAcima(tester, find.byKey(MotionKeys.mascote)), 1);
    await ate(tester, 1960);
    expect(opacidadeAcima(tester, find.byKey(MotionKeys.mascote)), lessThan(1));
    expect(abertura(tester), isTrue);
    await ate(tester, 2160);
    expect(abertura(tester), isFalse);
    expect(find.text('Início'), findsOneWidget);
    expect(terminou, 1);
  });

  teste('carga lenta: as roscas seguem até o fim do ciclo', (tester) async {
    await abre(tester);
    await ate(tester, 1960);
    // 1960 = 1800 + 160: o braço esquerdo no alto da rosca.
    expect(pose(tester).bracoE.angulo, closeTo(0, .01));
    expect(pose(tester).bracoD.angulo, closeTo(58, .01));
    await ate(tester, 2000);
    carga.complete();
    await ate(tester, 2280);
    // 2280 = 1800 + 480: agora o direito no alto; o ciclo não foi cortado.
    expect(pose(tester).bracoD.angulo, closeTo(0, .01));
    expect(pose(tester).bracoE.angulo, closeTo(58, .01));
    expect(luzDoNome(tester), 0);
    expect(pose(tester).opacidadeAtras, 0);
    expect(pose(tester).bracoE.escala, 1);
    await ate(tester, 2440 + 450);
    expect(luzDoNome(tester), 1);
    await ate(tester, 2440 + 1000);
    expect(abertura(tester), isFalse);
  });

  teste('carga rápida (300 ms): a primeira tela só em 2160', (tester) async {
    await abre(tester);
    await ate(tester, 300);
    carga.complete();
    await ate(tester, 2150);
    expect(abertura(tester), isTrue);
    await ate(tester, 2160);
    expect(abertura(tester), isFalse);
  });

  teste('a gota só no primeiro ciclo', (tester) async {
    await abre(tester);
    await ate(tester, 520 + 400);
    expect(pose(tester).gotaOpacidade, 1);
    expect(pose(tester).gotaDesce, inExclusiveRange(0, 30));
    await ate(tester, 520 + 900);
    expect(pose(tester).gotaOpacidade, 0);
    await ate(tester, 1160 + 400);
    expect(pose(tester).gotaOpacidade, 0);
  });

  teste('toque: com a carga pronta pula para a saída; sem ela, nada', (
    tester,
  ) async {
    await abre(tester);
    await ate(tester, 900);
    await tester.tap(find.byKey(MotionKeys.abertura));
    await ate(tester, 1200);
    expect(abertura(tester), isTrue);
    expect(opacidadeAcima(tester, find.byKey(MotionKeys.mascote)), 1);

    carga.complete();
    await ate(tester, 1250);
    await tester.tap(find.byKey(MotionKeys.abertura));
    await ate(tester, 1400);
    expect(opacidadeAcima(tester, find.byKey(MotionKeys.mascote)), lessThan(1));
    await ate(tester, 1560);
    expect(abertura(tester), isFalse);
  });

  teste('voltar do segundo plano não abre de novo', (tester) async {
    carga.complete();
    await abre(tester);
    await ate(tester, 2200);
    expect(abertura(tester), isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(abertura(tester), isFalse);
    expect(find.text('Início'), findsOneWidget);
  });

  teste('movimento reduzido: pose do ícone, fade do nome, sem partes', (
    tester,
  ) async {
    await abre(tester, reduzir: true);
    final inicio = pose(tester);
    expect(inicio.opacidadeAtras, 1);
    expect(inicio.bracoE.opacidade, 0);
    expect(inicio.bracoD.opacidade, 0);
    await ate(tester, 150);
    expect(luzDoNome(tester), 1);
    final depois = pose(tester);
    expect(depois.escalaX, 1);
    expect(depois.escalaY, 1);
    expect(depois.bracoE.angulo, inicio.bracoE.angulo);
    expect(depois.inclinacao, 0);
    expect(depois.olhos, 1);

    // Espera só a carga e sai com fade de 100 ms, sem encolher.
    await ate(tester, 600);
    expect(abertura(tester), isTrue);
    carga.complete();
    await ate(tester, 650);
    await ate(tester, 760);
    expect(abertura(tester), isFalse);
  });

  // Defeito do MP4 de 04/11: ao sair, a abertura trocava a árvore e o app por
  // baixo montava de novo (esqueleto, Início e onboarding outra vez).
  teste('o app por baixo não monta de novo quando a abertura sai', (
    tester,
  ) async {
    var montagens = 0;
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AberturaAnimada(
        carga: carga.future,
        child: _Montagens(aoMontar: () => montagens++),
      ),
    );
    await tester.pump();
    carga.complete();
    await tester.pumpAndSettle();
    expect(abertura(tester), isFalse);
    expect(montagens, 1);
  });
}

class _Montagens extends StatefulWidget {
  const _Montagens({required this.aoMontar});

  final VoidCallback aoMontar;

  @override
  State<_Montagens> createState() => _MontagensState();
}

class _MontagensState extends State<_Montagens> {
  @override
  void initState() {
    super.initState();
    widget.aoMontar();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
