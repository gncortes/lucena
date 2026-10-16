import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/speech_sheet_fade.dart';

/// Teste que termina com a folha da fala aberta não deixa o balão de cima
/// escondido para o teste seguinte do mesmo arquivo.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => SpeechSheetFade.open.value = false);
  await testMain();
}
