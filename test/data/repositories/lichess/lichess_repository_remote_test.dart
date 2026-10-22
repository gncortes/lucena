import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository_remote.dart';
import 'package:lucena/data/services/lichess_service.dart';
import 'package:lucena/domain/models/platform_rating.dart';

import '../../../../testing/fakes/fake_deep_link_service.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_secure_storage_service.dart';

const _account = {
  'id': 'ana_xadrez',
  'username': 'Ana_Xadrez',
  'perfs': {
    'bullet': {'games': 40, 'rating': 1650, 'rd': 60, 'prog': 3},
    'blitz': {'games': 312, 'rating': 1712, 'rd': 50, 'prog': -4},
    'rapid': {'games': 3, 'rating': 1500, 'rd': 300, 'prog': 0, 'prov': true},
  },
};

void main() {
  late FakeSecureStorageService storage;
  late FakeDeepLinkService links;
  late List<http.Request> requests;
  late List<Uri> opened;
  late bool online;
  late bool browser;
  final now = FakeNow(DateTime.utc(2026, 10, 20, 21, 40));

  setUp(() {
    storage = FakeSecureStorageService();
    links = FakeDeepLinkService();
    requests = [];
    opened = [];
    online = true;
    browser = true;
  });

  RemoteLichessRepository repository() {
    final client = MockClient((request) async {
      requests.add(request);
      if (!online) throw http.ClientException('offline');
      return switch ((request.method, request.url.path)) {
        ('POST', '/api/token') => http.Response(
          jsonEncode({'token_type': 'Bearer', 'access_token': 'lio_secret'}),
          200,
        ),
        ('GET', '/api/account') => http.Response(jsonEncode(_account), 200),
        ('DELETE', '/api/token') => http.Response('', 204),
        _ => http.Response('', 404),
      };
    });
    return RemoteLichessRepository(
      service: LichessService(
        client: client,
        launch: (url) async {
          opened.add(url);
          return browser;
        },
      ),
      storage: storage,
      links: links,
      now: now,
      random: Random(7),
    );
  }

  // O Lichess devolve a pessoa com o `state` da página aberta.
  Uri callback({String? code = 'abc', String? error, String? state}) {
    final params = opened.last.queryParameters;
    return LichessService.redirectUri.replace(
      queryParameters: {
        'code': ?code,
        'error': ?error,
        'state': state ?? params['state']!,
      },
    );
  }

  Future<void> untilOpened() async {
    while (opened.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('abre a página com PKCE S256 e, na volta, lê os ratings', () async {
    final lichess = repository();
    final connecting = lichess.connect();
    await untilOpened();
    final page = opened.single;
    expect(page.host, 'lichess.org');
    expect(page.path, '/oauth');
    expect(page.queryParameters['code_challenge_method'], 'S256');
    expect(page.queryParameters.containsKey('scope'), isFalse);

    links.open(callback());
    final rating = await connecting;

    expect(rating.user, 'Ana_Xadrez');
    expect(rating.readAt, now());
    expect(rating.blitz, const ModeRating(rating: 1712, games: 312));
    expect(
      rating.rapid,
      const ModeRating(rating: 1500, games: 3, provisional: true),
    );
    expect(rating.mainMode, RatingMode.blitz);
    // O verificador mandado na troca é o do desafio da página.
    final exchange = requests.firstWhere((r) => r.url.path == '/api/token');
    final verifier = exchange.bodyFields['code_verifier']!;
    expect(
      base64Url
          .encode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', ''),
      page.queryParameters['code_challenge'],
    );
    expect(exchange.bodyFields['code'], 'abc');
    expect(requests.last.headers['Authorization'], 'Bearer lio_secret');
    expect(storage.values[RemoteLichessRepository.tokenKey], 'lio_secret');
    expect(
      storage.values.containsKey(RemoteLichessRepository.pendingKey),
      isFalse,
    );
    expect(await lichess.isConnected(), isTrue);
  });

  test('recusar no Lichess: cancelado, sem token', () async {
    final lichess = repository();
    final connecting = lichess.connect();
    await untilOpened();
    links.open(callback(code: null, error: 'access_denied'));

    await expectLater(
      connecting,
      throwsA(
        isA<LichessException>().having(
          (e) => e.failure,
          'failure',
          LichessFailure.cancelled,
        ),
      ),
    );
    expect(await lichess.isConnected(), isFalse);
  });

  test('volta com outro state: cancelado', () async {
    final lichess = repository();
    final connecting = lichess.connect();
    await untilOpened();
    links.open(callback(state: 'outro'));

    await expectLater(connecting, throwsA(isA<LichessException>()));
    expect(requests, isEmpty);
  });

  test('cancel() desiste da espera', () async {
    final lichess = repository();
    final connecting = lichess.connect();
    await untilOpened();
    lichess.cancel();

    await expectLater(
      connecting,
      throwsA(
        isA<LichessException>().having(
          (e) => e.failure,
          'failure',
          LichessFailure.cancelled,
        ),
      ),
    );
  });

  test('sem navegador ou sem rede: falha de rede', () async {
    browser = false;
    await expectLater(
      repository().connect(),
      throwsA(
        isA<LichessException>().having(
          (e) => e.failure,
          'failure',
          LichessFailure.network,
        ),
      ),
    );

    browser = true;
    online = false;
    final lichess = repository();
    final connecting = lichess.connect();
    await untilOpened();
    links.open(callback());
    await expectLater(
      connecting,
      throwsA(
        isA<LichessException>().having(
          (e) => e.failure,
          'failure',
          LichessFailure.network,
        ),
      ),
    );
    expect(await lichess.isConnected(), isFalse);
  });

  test('o app fechado no navegador: a volta abre o app e termina', () async {
    final first = repository();
    final connecting = first.connect();
    await untilOpened();
    // O app morre; a volta chega como o endereço que abriu o app.
    connecting.ignore();
    links.initial = callback();

    final rating = await repository().resume();

    expect(rating?.user, 'Ana_Xadrez');
    expect(storage.values[RemoteLichessRepository.tokenKey], 'lio_secret');
    // Abrir de novo pelo mesmo endereço não troca o código outra vez.
    expect(await repository().resume(), isNull);
  });

  test('sem volta pendente, resume() não faz nada', () async {
    expect(await repository().resume(), isNull);
    links.initial = Uri.parse('https://playlucena.com/p/abc');
    expect(await repository().resume(), isNull);
  });

  test('desconectar revoga e apaga o token', () async {
    storage.values[RemoteLichessRepository.tokenKey] = 'lio_secret';
    final lichess = repository();

    await lichess.disconnect();

    expect(requests.single.method, 'DELETE');
    expect(requests.single.headers['Authorization'], 'Bearer lio_secret');
    expect(await lichess.isConnected(), isFalse);
  });

  test('desconectar sem rede ainda apaga o token', () async {
    storage.values[RemoteLichessRepository.tokenKey] = 'lio_secret';
    online = false;
    final lichess = repository();

    await lichess.disconnect();

    expect(await lichess.isConnected(), isFalse);
  });

  test('atualizar lê a conta de novo; sem rede, falha', () async {
    storage.values[RemoteLichessRepository.tokenKey] = 'lio_secret';
    final lichess = repository();
    expect((await lichess.account()).blitz?.rating, 1712);

    online = false;
    await expectLater(lichess.account(), throwsA(isA<LichessException>()));
  });
}
