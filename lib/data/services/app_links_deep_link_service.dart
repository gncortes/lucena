import 'package:app_links/app_links.dart';

import 'deep_link_service.dart';

/// Os App Links do sistema (o `intent-filter` com `autoVerify` no
/// `AndroidManifest.xml` e o `assetlinks.json` no Hosting).
class AppLinksDeepLinkService implements DeepLinkService {
  AppLinksDeepLinkService([AppLinks? links]) : _links = links ?? AppLinks();

  final AppLinks _links;

  Uri? _initial;

  @override
  Future<Uri?> initialUri() async {
    try {
      return _initial = await _links.getInitialLink();
    } on Object {
      return null;
    }
  }

  // O stream do app_links repete o link da partida fria, que a abertura já
  // tratou: ele passa uma vez só.
  @override
  Stream<Uri> get uris {
    var first = true;
    return _links.uriLinkStream.where((uri) {
      final duplicate = first && uri == _initial;
      first = false;
      return !duplicate;
    });
  }
}
