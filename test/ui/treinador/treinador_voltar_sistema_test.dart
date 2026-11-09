import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

const _idTiago = TreinadorFixtures.idTiago;

/// O Voltar do sistema (Android) em cada tela do Treinador: volta uma tela
/// e nunca fecha o app (`SystemNavigator.pop`).
final _android = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  late List<String> fechou;
  // No Android 16 o sistema só entrega o Voltar ao app com isto ligado.
  bool? trata;

  setUp(() => fechou = []);

  Future<TreinadorBed> abrirComoNoApp(WidgetTester tester) async {
    aparelho411x914(tester);
    trata = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') fechou.add(call.method);
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          trata = call.arguments as bool;
        }
        return null;
      },
    );
    final bed = TreinadorBed(
      repo: FakeTreinadorRepository(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      ),
    );
    await bed.abrir(tester, Routes.home);
    // A Home abre o Treinador com `go`: ele vira a base da pilha.
    bed.router.go(Routes.treinador());
    await assentar(tester);
    return bed;
  }

  Future<void> voltar(WidgetTester tester) async {
    expect(trata, isTrue, reason: 'o app não pediu o Voltar ao sistema');
    await tester.binding.handlePopRoute();
    await assentar(tester);
  }

  testWidgets('partida empilhada sobre o Treinador: volta à lista', (
    tester,
  ) async {
    final bed = await abrirComoNoApp(tester);
    unawaited(bed.router.push(Routes.treinadorPartida(_idTiago)));
    await assentar(tester);
    expect(find.byKey(TreinadorKeys.back), findsOneWidget);

    await voltar(tester);
    expect(fechou, isEmpty, reason: 'o Voltar fechou o app');
    expect(bed.caminho, startsWith('/treinador'));
    expect(find.byKey(TreinadorKeys.screen), findsOneWidget);
  }, variant: _android);

  testWidgets('análise sobre a partida: volta à partida', (tester) async {
    final bed = await abrirComoNoApp(tester);
    unawaited(bed.router.push(Routes.treinadorPartida(_idTiago)));
    await assentar(tester);
    unawaited(bed.router.push(Routes.treinadorAnalise(_idTiago)));
    await assentar(tester);

    await voltar(tester);
    expect(fechou, isEmpty, reason: 'o Voltar fechou o app');
    expect(bed.caminho, Routes.treinadorPartida(_idTiago));
  }, variant: _android);

  testWidgets('Treinador na base: volta à Home', (tester) async {
    final bed = await abrirComoNoApp(tester);
    await voltar(tester);
    expect(fechou, isEmpty, reason: 'o Voltar fechou o app');
    expect(bed.caminho, Routes.home);
  }, variant: _android);
}
