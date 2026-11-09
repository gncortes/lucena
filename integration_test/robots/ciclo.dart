import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

/// O binding do Patrol deixa o ciclo de vida do app nulo, e o Flutter só
/// pede o Voltar ao sistema (Android 16, `setFrameworkHandlesBack`) com o app
/// em primeiro plano: sem isto, o Voltar nativo fecha o app no teste. No
/// aparelho de verdade o sistema já entrega `resumed`.
void retomado(PatrolIntegrationTester $) =>
    $.tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
