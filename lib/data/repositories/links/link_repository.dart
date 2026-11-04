import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre um endereço fora do app (navegador ou app do link). Diz se abriu, para
/// a tela avisar quando não deu (Gap 6 do Sobre).
abstract class LinkRepository {
  Future<bool> open(Uri url);
}

/// O `url_launcher`, no app externo.
class UrlLauncherLinkRepository implements LinkRepository {
  const UrlLauncherLinkRepository();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
