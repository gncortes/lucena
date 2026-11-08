import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/daily/view_models/daily_start_cubit.dart';
import 'package:lucena/ui/daily/widgets/daily_start_screen.dart';

import '../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 22, 9));

  Future<DailyStartCubit> pump(
    WidgetTester tester, {
    required bool none,
    bool load = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = DailyStartCubit(
      daily: FakeDailyFinalRepository(none: none),
      rating: FakeRatingRepository(),
      now: now,
    );
    addTearDown(cubit.close);
    final router = GoRouter(
      initialLocation: Routes.daily,
      routes: [
        GoRoute(
          path: Routes.daily,
          builder: (context, state) =>
              BlocProvider.value(value: cubit, child: const DailyStartScreen()),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(body: Text('INICIO')),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    if (load) {
      await cubit.load();
      await tester.pumpAndSettle();
    }
    return cubit;
  }

  testWidgets('carregando: título, esqueleto e Compartilhar desabilitado', (
    tester,
  ) async {
    // H-DES-04 e a regra "ícones fixos entre estados" (README T85).
    await pump(tester, none: false, load: false);
    expect(find.byKey(DailyKeys.loading), findsOneWidget);
    expect(find.text('Final do dia'), findsOneWidget);
    final share = tester.widget<IconButton>(find.byKey(DailyKeys.appBarShare));
    expect(share.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(DailyKeys.appBarShare),
        matching: find.byIcon(Icons.share_outlined),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sem final hoje: o Início com o aviso', (tester) async {
    await pump(tester, none: true);
    expect(find.text('INICIO'), findsOneWidget);
    expect(find.byKey(DailyKeys.noFinalNotice), findsOneWidget);
    expect(
      find.text('Hoje não há final do dia. Volte amanhã.'),
      findsOneWidget,
    );
  });
}
