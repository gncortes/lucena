import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_app.dart';

/// Os goldens (T51, G7): cada componente em tema claro e escuro, português e
/// árabe, 360 e 412 dp, com a fonte do app (Roboto e, no árabe, Noto Naskh),
/// para não depender da fonte do sistema.
abstract final class Goldens {
  static bool _loaded = false;

  /// Carrega as fontes uma vez por arquivo de teste.
  static Future<void> loadFonts() async {
    if (_loaded) return;
    _loaded = true;
    final root = Platform.environment['FLUTTER_ROOT'];
    final material = '$root/bin/cache/artifacts/material_fonts';
    Future<void> family(String name, List<String> files) async {
      final loader = FontLoader(name);
      for (final file in files) {
        final bytes = File(file).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    }

    await family('Roboto', [
      for (final weight in ['Regular', 'Medium', 'Bold', 'Black'])
        '$material/Roboto-$weight.ttf',
    ]);
    await family('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
    await family('NotoNaskhArabic', [
      'test/goldens/fonts/NotoNaskhArabic-Regular.ttf',
      'test/goldens/fonts/NotoNaskhArabic-Bold.ttf',
    ]);
    await family('LucenaFigurine', ['assets/fonts/LucenaFigurine.ttf']);
  }

  static final variants = [
    for (final theme in [ThemeMode.light, ThemeMode.dark])
      for (final locale in [Locale('pt'), Locale('ar')])
        for (final width in [360.0, 412.0])
          GoldenVariant(theme: theme, locale: locale, width: width),
  ];

  /// Um teste por variante, com o golden em `goldens/<name>/<variante>.png`.
  static void matrix(
    String name,
    Widget Function(GoldenVariant variant) build, {
    double height = 640,
  }) {
    for (final variant in variants) {
      testWidgets('$name · ${variant.id}', (tester) async {
        await loadFonts();
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(variant.width, height);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          TestApp(
            locale: variant.locale,
            themeMode: variant.theme,
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(variant.width, height),
                disableAnimations: true,
              ),
              child: Builder(
                builder: (context) {
                  // O árabe cai no Noto Naskh, como no aparelho.
                  final theme = Theme.of(context);
                  return Theme(
                    data: theme.copyWith(
                      textTheme: theme.textTheme.apply(
                        fontFamilyFallback: const ['NotoNaskhArabic'],
                      ),
                    ),
                    child: Scaffold(
                      body: Align(
                        alignment: Alignment.topCenter,
                        child: RepaintBoundary(
                          key: _boundary,
                          // O fundo do tema, para o golden mostrar o
                          // contraste de verdade.
                          child: ColoredBox(
                            color: theme.scaffoldBackgroundColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: build(variant),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(_boundary),
          matchesGoldenFile('goldens/$name/${variant.id}.png'),
        );
      });
    }
  }

  static const _boundary = Key('golden.boundary');
}

class GoldenVariant {
  const GoldenVariant({
    required this.theme,
    required this.locale,
    required this.width,
  });

  final ThemeMode theme;
  final Locale locale;
  final double width;

  String get id =>
      '${theme.name}_${locale.languageCode}_${width.toStringAsFixed(0)}';

  bool get arabic => locale.languageCode == 'ar';
}
