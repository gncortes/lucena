import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Avaliar o Lucena" no Perfil: abre a página do app na Play. Não é o pedido
/// de avaliação (não conta nos 3 da E1.26).
abstract class StoreListingRepository {
  Future<void> open();
}

/// A página do app na Play, no app da loja (ou no navegador, sem ele).
class PlayStoreListingRepository implements StoreListingRepository {
  const PlayStoreListingRepository();

  static const _package = 'com.gncortes.lucena';

  @override
  Future<void> open() async {
    final store = Uri.parse('market://details?id=$_package');
    try {
      if (await launchUrl(store, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // Sem o app da loja: vai pelo navegador.
    }
    await launchUrl(
      Uri.https('play.google.com', '/store/apps/details', {'id': _package}),
      mode: LaunchMode.externalApplication,
    );
  }
}

/// Sem Play (F-Droid, testes): não abre nada.
class NoStoreListingRepository implements StoreListingRepository {
  const NoStoreListingRepository();

  @override
  Future<void> open() async {}
}
