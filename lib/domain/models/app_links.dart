/// O endereço público do app. O domínio fica só aqui: quando a E1.01 comprar o
/// definitivo, a troca é nesta constante.
abstract final class AppLinks {
  /// O domínio dos links (sem `https://`). Provisório: o Firebase Hosting, até
  /// o [finalHost] ser comprado.
  static const host = 'lucena-2f4de.web.app';

  /// O domínio definitivo. O app já abre os links dele.
  static const finalHost = 'playlucena.com';

  /// O começo do caminho de um desafio: `<host>/p/<código>`.
  static const challengeSegment = 'p';

  /// O caminho do final do dia, no link que vai com a imagem: `<host>/dia`.
  static const dailySegment = 'dia';

  /// O endereço de [path] no domínio do app.
  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.https(host, path, query);

  /// O link é do app (o provisório, ou o definitivo com ou sem `www`)?
  static bool isOwn(Uri uri) =>
      uri.host == host || uri.host == finalHost || uri.host == 'www.$finalHost';
}
