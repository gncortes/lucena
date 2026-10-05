import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Como a suíte inteira roda: com o aparelho em tema claro e em inglês (o
/// padrão), em tema escuro (`--dart-define=E2E_VARIANT=dark`) ou em árabe
/// (`--dart-define=E2E_VARIANT=ar`).
enum E2EVariant { light, dark, arabic }

final e2eVariant = switch (const String.fromEnvironment('E2E_VARIANT')) {
  'dark' => E2EVariant.dark,
  'ar' => E2EVariant.arabic,
  _ => E2EVariant.light,
};

/// A variante trocou o idioma deste cenário: a tela não está no inglês que
/// ele espera. O `AppRobot.open` decide a cada abertura.
bool e2eTranslated = false;

/// O texto esperado tem palavras (e não só números, como um relógio).
bool _hasWords(String text) => RegExp(r'\p{L}', unicode: true).hasMatch(text);

/// Compara um texto da tela com o esperado. Na variante em árabe, um texto
/// com palavras só precisa existir (o conteúdo é conferido na suíte padrão);
/// números e relógios continuam exatos.
void expectText(String? actual, String expected) {
  if (e2eTranslated && _hasWords(expected)) {
    expect(
      actual,
      isNotEmpty,
      reason: 'esperado algum texto no lugar de "$expected"',
    );
  } else {
    expect(actual, expected);
  }
}

/// Dentro de [within] há o texto [text] (na variante em árabe, algum texto).
void expectTextIn(Finder within, String text) {
  if (e2eTranslated && _hasWords(text)) {
    expect(
      find.descendant(of: within, matching: find.byType(Text)),
      findsWidgets,
      reason: 'esperado algum texto no lugar de "$text"',
    );
  } else {
    expect(
      find.descendant(of: within, matching: find.text(text)),
      findsOneWidget,
    );
  }
}
