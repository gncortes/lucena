import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/coach_keys.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/coach_fixtures.dart';
import 'coach_harness.dart';

const _idTiago = CoachFixtures.idTiago;

/// O Voltar do sistema (Android) em cada tela do Treinador: volta uma tela
/// e nunca fecha o app (`SystemNavigator.pop`).
final _android = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  late List<String> closed;
  // No Android 16 o sistema só entrega o Voltar ao app com isto ligado.
  bool? handles;

  setUp(() => closed = []);

  Future<CoachBed> openAsInApp(WidgetTester tester) async {
    device411x914(tester);
    handles = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') closed.add(call.method);
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handles = call.arguments as bool;
        }
        return null;
      },
    );
    final bed = CoachBed(
      repo: FakeCoachRepository(
        account: CoachFixtures.account,
        games: CoachFixtures.list(),
      ),
    );
    await bed.open(tester, Routes.home);
    // A Home abre o Treinador com `go`: ele vira a base da pilha.
    bed.router.go(Routes.coach());
    await assentar(tester);
    return bed;
  }

  Future<void> back(WidgetTester tester) async {
    expect(handles, isTrue, reason: 'o app não pediu o Voltar ao sistema');
    await tester.binding.handlePopRoute();
    await assentar(tester);
  }

  testWidgets('partida empilhada sobre o Treinador: volta à lista', (
    tester,
  ) async {
    final bed = await openAsInApp(tester);
    unawaited(bed.router.push(Routes.coachGame(_idTiago)));
    await assentar(tester);
    expect(find.byKey(CoachKeys.back), findsOneWidget);

    await back(tester);
    expect(closed, isEmpty, reason: 'o Voltar fechou o app');
    expect(bed.path, startsWith('/treinador'));
    expect(find.byKey(CoachKeys.screen), findsOneWidget);
  }, variant: _android);

  testWidgets('análise sobre a partida: volta à partida', (tester) async {
    final bed = await openAsInApp(tester);
    unawaited(bed.router.push(Routes.coachGame(_idTiago)));
    await assentar(tester);
    unawaited(bed.router.push(Routes.coachAnalysis(_idTiago)));
    await assentar(tester);

    await back(tester);
    expect(closed, isEmpty, reason: 'o Voltar fechou o app');
    expect(bed.path, Routes.coachGame(_idTiago));
  }, variant: _android);

  testWidgets('Treinador na base: volta à Home', (tester) async {
    final bed = await openAsInApp(tester);
    await back(tester);
    expect(closed, isEmpty, reason: 'o Voltar fechou o app');
    expect(bed.path, Routes.home);
  }, variant: _android);
}
