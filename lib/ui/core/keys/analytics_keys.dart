import 'package:flutter/widgets.dart';

abstract final class AnalyticsKeys {
  /// "Ajudar a melhorar o Lucena", em Privacidade e anúncios.
  static const optInSwitch = Key('analytics.optIn');

  /// A folha do Modo equipe (7 toques na versão) e a chave dela.
  static const teamSheet = Key('analytics.team.sheet');
  static const teamSwitch = Key('analytics.team.switch');
}
