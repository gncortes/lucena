/// O endereço público do app. O domínio do ambiente deste build é passado
/// pela configuração na abertura (`AppLinks.configure`, em `config/`); sem
/// ela (testes), vale o de dev.
abstract final class AppLinks {
  /// O site de produção e o de desenvolvimento (sem `https://`).
  static const prodHost = 'playlucenachess.com';
  static const devHost = 'dev.playlucenachess.com';

  static String _host = devHost;

  /// O domínio dos links que o app gera (sem `https://`): o site do ambiente
  /// deste build (dev: dev.playlucenachess.com; prod: playlucenachess.com).
  static String get host => _host;

  /// Liga os links ao site do ambiente; chamado uma vez na abertura do app.
  static void configure({required String siteHost}) => _host = siteHost;

  /// O começo do caminho de um desafio: `<host>/p/<código>`.
  static const challengeSegment = 'p';

  /// O caminho do final do dia, no link que vai com a imagem: `<host>/dia`.
  static const dailySegment = 'dia';

  /// O endereço de [path] no domínio do app.
  static Uri uri(String path, [Map<String, String>? query]) =>
      Uri.https(host, path, query);

  /// O link é do app? O site do ambiente e o de prod (com ou sem `www`).
  static bool isOwn(Uri uri) =>
      uri.scheme == 'https' &&
      (uri.host == host || uri.host == prodHost || uri.host == 'www.$prodHost');
}
