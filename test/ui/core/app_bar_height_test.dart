import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_bar_height.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';

/// Regra transversal da app bar (T85, canvas 23fd0701): 64 em todas as telas,
/// colada no topo.
void main() {
  test('o tema e o token dão 64', () {
    expect(AppBarHeight.standard, 64);
    expect(AppTheme.light.appBarTheme.toolbarHeight, 64);
  });

  testWidgets('LucenaAppBar sem altura: o Scaffold reserva 64 no topo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: LucenaAppBar(title: const Text('Título')),
          body: const SizedBox.expand(),
        ),
      ),
    );
    final bar = find.byType(AppBar);
    expect(tester.getSize(bar).height, 64);
    expect(tester.getTopLeft(bar).dy, 0);
    expect(tester.getTopLeft(find.byType(SizedBox).last).dy, 64);
  });
}
