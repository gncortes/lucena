/// Os endereços que abrem o app (App Links). A E1.01 troca [NoDeepLinkService]
/// por um que leia o sistema (pacote `app_links`) quando o domínio e o
/// `assetlinks.json` estiverem no ar. Sem isso, nenhum endereço chega.
abstract class DeepLinkService {
  /// O endereço que abriu o app (partida fria). Nulo: abriu pelo ícone.
  Future<Uri?> initialUri();

  /// Os endereços que chegam com o app aberto.
  Stream<Uri> get uris;
}

/// Sem App Links ainda: nada abre o app por endereço.
class NoDeepLinkService implements DeepLinkService {
  const NoDeepLinkService();

  @override
  Future<Uri?> initialUri() async => null;

  @override
  Stream<Uri> get uris => const Stream.empty();
}
