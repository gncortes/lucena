import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// O que a Play diz da versão instalada.
class PlayUpdateInfo {
  const PlayUpdateInfo({
    this.available,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
  });

  /// Nulo: a Play não respondeu (app fora da Play, sem rede, debug).
  final bool? available;
  final bool immediateAllowed;
  final bool flexibleAllowed;
}

/// A atualização pelo próprio app, da Play (E1.32 §3).
abstract class AppUpdateService {
  Future<PlayUpdateInfo> check();

  /// A atualização imediata, de tela cheia, toda da Play. Verdadeiro: a
  /// pessoa aceitou.
  Future<bool> immediate();

  /// A atualização flexível: baixa em segundo plano. Verdadeiro: baixou.
  Future<bool> flexible();

  /// Instala o que [flexible] baixou (o app reinicia).
  Future<void> completeFlexible();

  /// A página do app na Play.
  Future<void> openStore();
}

/// A página do Lucena na Play.
final playStorePage = Uri.parse(
  'https://play.google.com/store/apps/details?id=com.gncortes.lucena',
);

Future<void> _openStore() =>
    launchUrl(playStorePage, mode: LaunchMode.externalApplication);

/// Sem a Play no app (F-Droid, debug, testes): só a página da loja.
class NoAppUpdateService implements AppUpdateService {
  const NoAppUpdateService();

  @override
  Future<PlayUpdateInfo> check() async => const PlayUpdateInfo();

  @override
  Future<bool> immediate() async => false;

  @override
  Future<bool> flexible() async => false;

  @override
  Future<void> completeFlexible() async {}

  @override
  Future<void> openStore() => _openStore();
}

class PlayAppUpdateService implements AppUpdateService {
  const PlayAppUpdateService();

  @override
  Future<PlayUpdateInfo> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return PlayUpdateInfo(
        available: switch (info.updateAvailability) {
          UpdateAvailability.updateAvailable ||
          UpdateAvailability.developerTriggeredUpdateInProgress => true,
          UpdateAvailability.updateNotAvailable => false,
          UpdateAvailability.unknown => null,
        },
        immediateAllowed: info.immediateUpdateAllowed,
        flexibleAllowed: info.flexibleUpdateAllowed,
      );
    } on PlatformException {
      // Instalado fora da Play: a Play não sabe deste app.
      return const PlayUpdateInfo();
    }
  }

  @override
  Future<bool> immediate() async {
    try {
      return await InAppUpdate.performImmediateUpdate() ==
          AppUpdateResult.success;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> flexible() async {
    try {
      return await InAppUpdate.startFlexibleUpdate() == AppUpdateResult.success;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> completeFlexible() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on PlatformException {
      // Sem nada baixado: fica como está.
    }
  }

  @override
  Future<void> openStore() => _openStore();
}
