/// O endereço público do app. O domínio fica só aqui: quando a E1.01 comprar o
/// definitivo, a troca é nesta constante.
abstract final class AppLinks {
  /// O domínio dos links (sem `https://`).
  static const host = 'playlucena.com';

  /// O começo do caminho de um desafio: `playlucena.com/p/<código>`.
  static const challengeSegment = 'p';

  /// O endereço de [path] no domínio do app.
  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.https(host, path, query);

  /// O link é do app (o domínio, com ou sem `www`)?
  static bool isOwn(Uri uri) => uri.host == host || uri.host == 'www.$host';
}
