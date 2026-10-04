import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';

import '../../../../testing/test_app.dart';

void main() {
  String mascotAsset(WidgetTester tester) {
    final image = tester.widget<Image>(find.byKey(HomeKeys.mascot));
    return (image.image as AssetImage).assetName;
  }

  testWidgets('mostra o mascote claro no tema claro', (tester) async {
    await tester.pumpWidget(const TestApp(child: HomeScreen()));

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(mascotAsset(tester), 'assets/branding/mascot_light.png');
  });

  testWidgets('mostra o mascote escuro no tema escuro', (tester) async {
    await tester.pumpWidget(
      const TestApp(themeMode: ThemeMode.dark, child: HomeScreen()),
    );

    expect(mascotAsset(tester), 'assets/branding/mascot_dark.png');
  });

  testWidgets('descreve o mascote para o leitor de tela', (tester) async {
    await tester.pumpWidget(const TestApp(child: HomeScreen()));

    expect(
      find.bySemanticsLabel('Lucena mascot: a chess pawn lifting dumbbells'),
      findsOneWidget,
    );
  });
}
