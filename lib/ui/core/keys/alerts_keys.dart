import 'package:flutter/widgets.dart';

/// Perfil > Avisos (E1.21).
abstract final class AlertsKeys {
  static const screen = Key('alerts.screen');
  static const allowed = Key('alerts.allowed');
  static const allowedSettings = Key('alerts.allowedSettings');
  static const offBanner = Key('alerts.offBanner');
  static const offOpen = Key('alerts.offOpen');
  static const tournaments = Key('alerts.tournaments');
  static const daily = Key('alerts.daily');
  static const news = Key('alerts.news');
  static const lessons = Key('alerts.lessons');
  static const reminder = Key('alerts.reminder');

  /// "Quer receber avisos do Lucena?", no fim do primeiro final.
  static const askSheet = Key('alerts.ask.sheet');
  static const askYes = Key('alerts.ask.yes');
  static const askLater = Key('alerts.ask.later');
}
