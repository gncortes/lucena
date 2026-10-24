import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/push/push_repository.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/settings/settings_repository_local.dart';
import '../data/services/firebase/push_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/preferences_service.dart';
import '../domain/models/push_alert.dart';
import '../ui/core/l10n/l10n.dart';

/// Os textos da notificação de push no idioma do app (o escolhido nos
/// Ajustes ou o do aparelho). Vale também fora da árvore de widgets: no
/// isolate em que o FCM entrega o push com o app fechado.
Future<PushTexts> loadPushTexts(SettingsRepository settings) async {
  String? code;
  try {
    code = (await settings.load()).languageCode;
  } on Object catch (error) {
    debugPrint('Push sem o idioma dos Ajustes: $error');
  }
  final l10n = _lookup(
    localeFromCode(code) ?? PlatformDispatcher.instance.locale,
  );
  return PushTexts(
    tournaments: l10n.pushChannelTournaments,
    daily: l10n.dailyTitle,
    lessons: l10n.alertsLessons,
    news: l10n.alertsNews,
    play: l10n.featuredPlay,
    tournament: l10n.pushActionTournament,
  );
}

AppLocalizations _lookup(Locale locale) {
  for (final candidate in [locale, Locale(locale.languageCode)]) {
    try {
      return lookupAppLocalizations(candidate);
    } on FlutterError {
      continue;
    }
  }
  return lookupAppLocalizations(const Locale('en'));
}

/// O push que chega com o app fechado ou em segundo plano. O que veio com
/// `notification` o Android já mostrou (só com o toque, sem botões); o
/// "data-only" (com `titulo`/`texto`) o app mostra com a imagem e os botões.
@pragma('vm:entry-point')
Future<void> showPushInBackground(RemoteMessage remote) async {
  final message = FirebasePushService.message(remote);
  if (message.notified) return;
  final alert = PushAlert.fromData(message.data);
  if (alert == null) return;
  await backgroundPushRepository().show(alert);
}

/// O repositório mínimo para mostrar um push fora do app (sem tópicos).
PushRepository backgroundPushRepository() {
  final preferences = PreferencesService();
  return FirebasePushRepository(
    const NoPushService(),
    preferences,
    notifications: DeviceNotificationService(),
    texts: () => loadPushTexts(LocalSettingsRepository(preferences)),
  );
}

/// Registra [showPushInBackground] no FCM. Só com o Firebase ligado.
void listenPushInBackground() =>
    FirebaseMessaging.onBackgroundMessage(showPushInBackground);
