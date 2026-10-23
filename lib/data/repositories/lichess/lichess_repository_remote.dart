import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../domain/models/platform_rating.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/deep_link_service.dart';
import '../../services/lichess_service.dart';
import '../../services/secure_storage_service.dart';
import 'lichess_repository.dart';

/// OAuth 2 com PKCE feito à mão: o navegador abre a página do Lichess e a volta
/// chega pelo esquema próprio do app ([LichessService.redirectUri]). O
/// verificador fica no armazenamento seguro até a volta, para ela funcionar
/// mesmo se o app foi fechado no navegador.
class RemoteLichessRepository implements LichessRepository {
  RemoteLichessRepository({
    required this._service,
    required this._storage,
    required this._links,
    required this._now,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const tokenKey = 'lichess.token';
  static const pendingKey = 'lichess.pending';

  /// A última leitura, junto do token (some com ele ao desconectar).
  static const lastKey = 'lichess.last';

  final LichessService _service;
  final SecureStorageService _storage;
  final DeepLinkService _links;
  final Now _now;
  final Random _random;
  Completer<Uri>? _waiting;

  @override
  Future<PlatformRating> connect() async {
    cancel();
    final verifier = _randomText();
    final state = _randomText();
    final waiting = _waiting = Completer<Uri>();
    final callbacks = _links.uris.where(_isCallback).listen((uri) {
      if (!waiting.isCompleted) waiting.complete(uri);
    });
    try {
      await _storage.write(pendingKey, '$state $verifier');
      final url = _service.authorizeUrl(
        challenge: _challenge(verifier),
        state: state,
      );
      if (!await _service.open(url)) {
        throw const LichessException(LichessFailure.network);
      }
      return await _finish(await waiting.future);
    } finally {
      await callbacks.cancel();
      if (identical(_waiting, waiting)) _waiting = null;
    }
  }

  @override
  void cancel() {
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null && !waiting.isCompleted) {
      waiting.completeError(const LichessException(LichessFailure.cancelled));
    }
  }

  @override
  Future<PlatformRating?> resume() async {
    final uri = await _links.initialUri();
    if (uri == null || !_isCallback(uri)) return null;
    if (await _storage.read(pendingKey) == null) return null;
    return _finish(uri);
  }

  @override
  Future<PlatformRating> account() async {
    final token = await _storage.read(tokenKey);
    if (token == null) throw const LichessException(LichessFailure.cancelled);
    try {
      return await _remember(
        parseAccount(await _service.account(token), _now()),
      );
    } on LichessServiceException {
      throw const LichessException(LichessFailure.network);
    }
  }

  @override
  Future<PlatformRating?> lastRead() async {
    final saved = await _storage.read(lastKey);
    if (saved == null) return null;
    try {
      return decodeRating(jsonDecode(saved) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    final token = await _storage.read(tokenKey);
    await _storage.delete(tokenKey);
    await _storage.delete(lastKey);
    if (token != null) await _service.revoke(token);
  }

  @override
  Future<bool> isConnected() async => await _storage.read(tokenKey) != null;

  Future<PlatformRating> _finish(Uri uri) async {
    final pending = (await _storage.read(pendingKey))?.split(' ');
    await _storage.delete(pendingKey);
    final params = uri.queryParameters;
    final code = params['code'];
    if (pending == null ||
        pending.length != 2 ||
        params['state'] != pending[0] ||
        params.containsKey('error') ||
        code == null) {
      throw const LichessException(LichessFailure.cancelled);
    }
    try {
      final token = await _service.exchange(code: code, verifier: pending[1]);
      await _storage.write(tokenKey, token);
      return await _remember(
        parseAccount(await _service.account(token), _now()),
      );
    } on LichessServiceException {
      throw const LichessException(LichessFailure.network);
    }
  }

  Future<PlatformRating> _remember(PlatformRating rating) async {
    await _storage.write(lastKey, jsonEncode(encodeRating(rating)));
    return rating;
  }

  static bool _isCallback(Uri uri) =>
      uri.scheme == LichessService.redirectUri.scheme &&
      uri.host == LichessService.redirectUri.host;

  /// 32 bytes ao acaso em base64url, sem o `=` do fim (43 caracteres).
  String _randomText() =>
      _base64Url(List<int>.generate(32, (_) => _random.nextInt(256)));

  static String _challenge(String verifier) =>
      _base64Url(sha256.convert(ascii.encode(verifier)).bytes);

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  /// A resposta de `/api/account`. Lança [LichessException] se vier sem
  /// usuário.
  static PlatformRating parseAccount(Map<String, Object?> json, DateTime now) {
    final user = json['username'];
    if (user is! String) throw const LichessException(LichessFailure.network);
    final perfs = json['perfs'];
    ModeRating? mode(String name) {
      final perf = perfs is Map ? perfs[name] : null;
      if (perf is! Map) return null;
      final rating = perf['rating'];
      if (rating is! num) return null;
      final games = perf['games'];
      return ModeRating(
        rating: rating.round(),
        games: games is num ? games.toInt() : 0,
        provisional: perf['prov'] == true,
      );
    }

    return PlatformRating(
      user: user,
      readAt: now,
      bullet: mode('bullet'),
      blitz: mode('blitz'),
      rapid: mode('rapid'),
    );
  }

  static Map<String, Object?> encodeRating(PlatformRating rating) {
    Map<String, Object?>? mode(ModeRating? mode) => mode == null
        ? null
        : {
            'rating': mode.rating,
            'games': mode.games,
            'prov': mode.provisional,
          };
    return {
      'user': rating.user,
      'readAt': rating.readAt.toIso8601String(),
      'bullet': mode(rating.bullet),
      'blitz': mode(rating.blitz),
      'rapid': mode(rating.rapid),
    };
  }

  static PlatformRating decodeRating(Map<String, Object?> json) {
    ModeRating? mode(Object? value) => value is Map
        ? ModeRating(
            rating: value['rating'] as int,
            games: value['games'] as int,
            provisional: value['prov'] == true,
          )
        : null;
    return PlatformRating(
      user: json['user']! as String,
      readAt: DateTime.parse(json['readAt']! as String),
      bullet: mode(json['bullet']),
      blitz: mode(json['blitz']),
      rapid: mode(json['rapid']),
    );
  }
}
