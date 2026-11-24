import 'dart:async';
import 'dart:io';

/// Diz se o aparelho alcança a internet agora (uma consulta de DNS curta).
/// Sem estado; nos testes, um falso do repositório.
class ConnectivityService {
  const ConnectivityService({
    this.host = 'pt.wikipedia.org',
    this.timeout = const Duration(seconds: 2),
  });

  final String host;
  final Duration timeout;

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }
}
