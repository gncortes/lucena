import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucena/data/repositories/chesscom/chesscom_repository.dart';
import 'package:lucena/data/repositories/chesscom/chesscom_repository_remote.dart';
import 'package:lucena/data/services/chesscom_service.dart';
import 'package:lucena/domain/models/platform_rating.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  final now = FakeNow(DateTime.utc(2026, 10, 20));
  late List<http.Request> requests;

  RemoteChessComRepository repository(http.Response Function() reply) =>
      RemoteChessComRepository(
        ChessComService(
          client: MockClient((request) async {
            requests.add(request);
            return reply();
          }),
        ),
        now: now,
      );

  setUp(() => requests = []);

  Map<String, Object?> mode(int rating, int win, int loss, int draw) => {
    'last': {'rating': rating, 'date': 1, 'rd': 50},
    'record': {'win': win, 'loss': loss, 'draw': draw},
  };

  test('lê o blitz, o bullet e o rápido do usuário', () async {
    final chess = repository(
      () => http.Response(
        jsonEncode({
          'chess_blitz': mode(1405, 100, 90, 10),
          'chess_rapid': mode(1500, 5, 4, 1),
          'chess_daily': mode(1200, 1, 0, 0),
        }),
        200,
      ),
    );

    final rating = await chess.stats(' Ana_CC ');

    expect(requests.single.url.path, '/pub/player/ana_cc/stats');
    expect(requests.single.headers['User-Agent'], contains('Lucena'));
    expect(rating.user, 'Ana_CC');
    expect(rating.blitz, const ModeRating(rating: 1405, games: 200));
    expect(rating.rapid, const ModeRating(rating: 1500, games: 10));
    expect(rating.bullet, isNull);
    expect(rating.mainMode, RatingMode.blitz);
  });

  test('usuário que não existe: não achado', () async {
    await expectLater(
      repository(() => http.Response('{"code":0}', 404)).stats('ninguem'),
      throwsA(
        isA<ChessComException>().having(
          (e) => e.failure,
          'failure',
          ChessComFailure.notFound,
        ),
      ),
    );
  });

  test('usuário sem partidas rápidas, blitz ou bullet: não achado', () async {
    await expectLater(
      repository(
        () => http.Response(
          jsonEncode({'chess_daily': mode(1200, 1, 0, 0)}),
          200,
        ),
      ).stats('so_diario'),
      throwsA(
        isA<ChessComException>().having(
          (e) => e.failure,
          'failure',
          ChessComFailure.notFound,
        ),
      ),
    );
  });

  test('sem rede ou erro do servidor: falha de rede', () async {
    await expectLater(
      repository(() => throw http.ClientException('offline')).stats('ana'),
      throwsA(
        isA<ChessComException>().having(
          (e) => e.failure,
          'failure',
          ChessComFailure.network,
        ),
      ),
    );
    await expectLater(
      repository(() => http.Response('', 500)).stats('ana'),
      throwsA(
        isA<ChessComException>().having(
          (e) => e.failure,
          'failure',
          ChessComFailure.network,
        ),
      ),
    );
  });
}
