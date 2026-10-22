import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Uma chamada ao Lichess que não deu certo (rede, resposta inesperada).
class LichessServiceException implements Exception {
  const LichessServiceException(this.reason);

  final String reason;

  @override
  String toString() => 'LichessServiceException($reason)';
}

/// O site e a API do Lichess: a página de autorização (OAuth 2 com PKCE, sem
/// segredo do app e sem cadastro do cliente), a troca do código pelo token, a
/// conta e a revogação. O token nunca vai para o log.
class LichessService {
  LichessService({http.Client? client, Future<bool> Function(Uri)? launch})
    : _client = client ?? http.Client(),
      _launch = launch ?? _openBrowser;

  /// O Lichess aceita qualquer identificador de cliente.
  static const clientId = 'com.gncortes.lucena';

  /// Para onde o Lichess devolve a pessoa: o `intent-filter` do esquema
  /// próprio no `AndroidManifest.xml`.
  static final redirectUri = Uri.parse('com.gncortes.lucena://lichess-auth');

  static const _host = 'lichess.org';
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final Future<bool> Function(Uri) _launch;

  static Future<bool> _openBrowser(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// A página "O Lucena quer acessar a sua conta", sem escopos: só o perfil
  /// público e os ratings.
  Uri authorizeUrl({required String challenge, required String state}) =>
      Uri.https(_host, '/oauth', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': '$redirectUri',
        'code_challenge_method': 'S256',
        'code_challenge': challenge,
        'state': state,
      });

  /// Abre a página no navegador. Falso: nenhum navegador abriu.
  Future<bool> open(Uri url) async {
    try {
      return await _launch(url);
    } on Object {
      return false;
    }
  }

  /// Troca o código do retorno pelo token de acesso.
  Future<String> exchange({
    required String code,
    required String verifier,
  }) async {
    final json = await _call(
      () => _client.post(
        Uri.https(_host, '/api/token'),
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'code_verifier': verifier,
          'redirect_uri': '$redirectUri',
          'client_id': clientId,
        },
      ),
    );
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const LichessServiceException('no token');
    }
    return token;
  }

  /// `GET /api/account`: o usuário e os ratings.
  Future<Map<String, Object?>> account(String token) => _call(
    () => _client.get(
      Uri.https(_host, '/api/account'),
      headers: {'Authorization': 'Bearer $token'},
    ),
  );

  /// Tira o acesso do Lucena no Lichess. Sem rede, o token só some do
  /// aparelho.
  Future<void> revoke(String token) async {
    try {
      await _client
          .delete(
            Uri.https(_host, '/api/token'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);
    } on Object {
      // O token expira sozinho (um ano).
    }
  }

  Future<Map<String, Object?>> _call(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on Object {
      throw const LichessServiceException('network');
    }
    if (response.statusCode != 200) {
      throw LichessServiceException('status ${response.statusCode}');
    }
    try {
      return (jsonDecode(response.body) as Map).cast<String, Object?>();
    } on Object {
      throw const LichessServiceException('body');
    }
  }
}
