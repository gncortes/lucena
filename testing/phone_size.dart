import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os dois aparelhos da matriz das telas (dp, densidade 1).
const phoneSizes = [Size(360, 740), Size(412, 917)];

/// Põe a janela do teste no tamanho [size] (em dp) e volta ao padrão no fim.
void setPhoneSize(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// O retângulo do widget de [key] na tela.
Rect rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

/// Confere [actual] contra [expected] com a tolerância de 1 dp do contrato.
Matcher closeToDp(double expected) => closeTo(expected, 1);
