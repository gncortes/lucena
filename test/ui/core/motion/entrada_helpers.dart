import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Leitura das entradas em ordem (H-ANI-16, 17, 24 e 25): a parte que não
/// anima não tem `Opacity` nem `Transform` próprios, e conta como pronta.

Widget? _primeiro<T extends Widget>(WidgetTester tester, Finder parte) {
  final achados = find.descendant(of: parte, matching: find.byType(T));
  return achados.evaluate().isEmpty ? null : tester.widget<T>(achados.first);
}

double opacidade(WidgetTester tester, Finder parte) =>
    (_primeiro<Opacity>(tester, parte) as Opacity?)?.opacity ?? 1;

/// Quanto a parte ainda está abaixo do lugar, em px.
double subida(WidgetTester tester, Finder parte) =>
    (_primeiro<Transform>(tester, parte) as Transform?)?.transform
        .getTranslation()
        .y ??
    0;

/// A escala da parte (o `Transform.scale` dentro do da subida).
double escala(WidgetTester tester, Finder parte) {
  final transforms = find.descendant(
    of: parte,
    matching: find.byType(Transform),
  );
  if (transforms.evaluate().length < 2) return 1;
  return tester.widget<Transform>(transforms.at(1)).transform.storage[0];
}
