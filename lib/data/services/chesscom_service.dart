import 'dart:convert';

import 'package:http/http.dart' as http;

/// A API pública do Chess.com não respondeu (rede, resposta inesperada).
class ChessComServiceException implements Exception {
  const ChessComServiceException(this.reason);

  final String reason;

  @override
  String toString() => 'ChessComServiceException($reason)';
}

/// A API pública do Chess.com (sem login): os ratings de um usuário.
class ChessComService {
  ChessComService({http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);

  final http.Client _client;

  /// `GET /pub/player/{usuário}/stats`. Nulo: o usuário não existe.
  Future<Map<String, Object?>?> stats(String user) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.https(
              'api.chess.com',
              '/pub/player/${Uri.encodeComponent(user.toLowerCase())}/stats',
            ),
            // O Chess.com pede para quem chama se identificar.
            headers: {'User-Agent': 'Lucena (com.gncortes.lucena)'},
          )
          .timeout(_timeout);
    } on Object {
      throw const ChessComServiceException('network');
    }
    if (response.statusCode == 404 || response.statusCode == 410) return null;
    if (response.statusCode != 200) {
      throw ChessComServiceException('status ${response.statusCode}');
    }
    try {
      return (jsonDecode(response.body) as Map).cast<String, Object?>();
    } on Object {
      throw const ChessComServiceException('body');
    }
  }
}
