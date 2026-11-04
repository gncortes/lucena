import 'package:flutter/widgets.dart';

/// Perfil > Avisos (E1.21).
abstract final class AlertsKeys {
  static const screen = Key('alerts.screen');
  static const allowed = Key('alerts.allowed');
  static const allowedSettings = Key('alerts.allowedSettings');
  static const offBanner = Key('alerts.offBanner');
  static const offOpen = Key('alerts.offOpen');

  /// "Permitir" na faixa desligada: pede a permissão do Android (Gap 7).
  static const offAllow = Key('alerts.offAllow');

  /// A tela de erro quando as chaves não puderam ser lidas (Gap 4).
  static const error = Key('alerts.error');

  /// O aviso de que a chave não foi gravada (Gap 1).
  static const saveFailure = Key('alerts.saveFailure');
  static const tournaments = Key('alerts.tournaments');
  static const daily = Key('alerts.daily');
  static const news = Key('alerts.news');
  static const lessons = Key('alerts.lessons');
  static const region = Key('alerts.region');
}
