import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/maia_debug_keys.dart';
import 'package:lucena/ui/maia_debug/view_models/maia_debug_cubit.dart';
import 'package:lucena/ui/maia_debug/widgets/maia_debug_screen.dart';

import '../../../testing/fakes/fake_maia_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeMaiaRepository maia;
  late MaiaDebugCubit cubit;

  Future<void> pump(WidgetTester tester) async {
    maia = FakeMaiaRepository();
    cubit = MaiaDebugCubit(maia);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('en'),
        child: BlocProvider.value(value: cubit, child: const MaiaDebugScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('avaliar mostra os lances, as chances e o tempo', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(MaiaDebugKeys.evaluate));
    await tester.pumpAndSettle();

    expect(find.text('Computed in 120 ms'), findsOneWidget);
    expect(find.text('Win 80.0% · Draw 20.0% · Loss 0.0%'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(MaiaDebugKeys.move(0))).data, 'a1a4');
    expect(
      tester.widget<Text>(find.byKey(MaiaDebugKeys.probability(0))).data,
      '60.0%',
    );
    expect(tester.widget<Text>(find.byKey(MaiaDebugKeys.move(1))).data, 'a1d1');
  });

  testWidgets('trocar o nível muda o pedido', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(MaiaDebugKeys.level(2600)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MaiaDebugKeys.evaluate));
    await tester.pumpAndSettle();

    expect(maia.requests.single.$2, 2600);
  });

  testWidgets('FEN inválido mostra o erro e nenhum resultado', (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(MaiaDebugKeys.fen), 'xyz');
    await tester.tap(find.byKey(MaiaDebugKeys.evaluate));
    await tester.pumpAndSettle();

    expect(find.text('This is not a valid FEN.'), findsOneWidget);
    expect(find.byKey(MaiaDebugKeys.result), findsNothing);
  });
}
