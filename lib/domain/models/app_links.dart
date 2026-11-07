import '../../config/ambiente.dart';

/// O endereço público do app. O domínio de cada ambiente vem do
/// [Ambiente.siteHost] (único lugar de ambiente em Dart).
abstract final class AppLinks {
  /// O domínio dos links que o app gera (sem `https://`): o site do ambiente
  /// deste build (dev: lucena-dev-gnc; prod: lucena-2f4de, até o [finalHost]).
  static String get host => Ambiente.atual().siteHost;

  /// O domínio definitivo. O app já abre os links dele.
  static const finalHost = 'playlucena.com';

  /// O começo do caminho de um desafio: `<host>/p/<código>`.
  static const challengeSegment = 'p';

  /// O caminho do final do dia, no link que vai com a imagem: `<host>/dia`.
  static const dailySegment = 'dia';

  /// O endereço de [path] no domínio do app.
  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.https(host, path, query);

  /// O link é do app? O site do ambiente e, como antes, o de prod (o
  /// provisório, ou o definitivo com ou sem `www`).
  static bool isOwn(Uri uri) =>
      uri.scheme == 'https' &&
      (uri.host == host ||
          uri.host == Ambiente.prod.siteHost ||
          uri.host == finalHost ||
          uri.host == 'www.$finalHost');
}
