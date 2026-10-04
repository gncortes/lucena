import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';

import '../testing/e2e_dependencies.dart';
import '../testing/fakes/fake_now.dart';

void main() {
  testWidgets('abre na tela inicial', (tester) async {
    await tester.pumpWidget(LucenaApp(dependencies: e2eDependencies()));
    await tester.pumpAndSettle();

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
  });

  testWidgets('entrega às telas o relógio da composição', (tester) async {
    final now = FakeNow(DateTime.utc(2026, 5, 17));
    await tester.pumpWidget(LucenaApp(dependencies: e2eDependencies(now: now)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(HomeKeys.screen));

    expect(context.read<Now>(), same(now));
  });

  testWidgets('em português usa os textos em português', (tester) async {
    await tester.pumpWidget(
      LucenaApp(dependencies: e2eDependencies(), locale: const Locale('pt')),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        'Mascote do Lucena: um peão de xadrez levantando halteres',
      ),
      findsOneWidget,
    );
  });

  testWidgets('idioma sem tradução cai no inglês', (tester) async {
    await tester.pumpWidget(
      LucenaApp(dependencies: e2eDependencies(), locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Lucena mascot: a chess pawn lifting dumbbells'),
      findsOneWidget,
    );
  });
}
