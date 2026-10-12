import 'package:flutter_test/flutter_test.dart';

/// O centro da tela visível, em dp: a altura menos as barras do sistema (a
/// regra do centro do tabuleiro nas telas de jogo).
double visibleCenterY(WidgetTester tester) {
  final view = tester.view;
  final ratio = view.devicePixelRatio;
  final height = view.physicalSize.height / ratio;
  final top = view.viewPadding.top / ratio;
  final bottom = view.viewPadding.bottom / ratio;
  return (top + height - bottom) / 2;
}
