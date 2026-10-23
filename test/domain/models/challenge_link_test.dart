import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';

const _fen = '8/8/8/4k3/8/8/4K3/4Q3 w - - 0 1';

ChallengeLink _link() => ChallengeLink(
  fen: _fen,
  goal: PositionGoal.win,
  positionId: 'kq-k',
  userSide: Side.white,
  level: 1400,
  clock: TimeControl.tryParse('300+0'),
  locked: true,
  utm: const {'utm_source': 'whatsapp'},
);

void main() {
  test('o endereço usa o domínio e o caminho /p/<código>', () {
    final uri = _link().uri;
    expect(uri.host, AppLinks.host);
    expect(uri.pathSegments.first, 'p');
    expect(uri.pathSegments.last, _link().code);
    expect(_link().code, hasLength(5));
  });

  test('ida e volta devolve o mesmo desafio', () {
    final back = ChallengeLink.tryParse(_link().uri);
    expect(back, _link());
  });

  test('o + do relógio sobrevive ao endereço escrito à mão', () {
    final uri = Uri.parse(
      'https://playlucena.com/p/abcde?fen=${Uri.encodeQueryComponent(_fen)}'
      '&side=black&clock=180+2',
    );
    final link = ChallengeLink.tryParse(uri)!;
    expect(link.clock!.code, '180+2');
    expect(link.userSide, Side.black);
  });

  test('o mesmo desafio dá o mesmo código e outro dá código diferente', () {
    expect(_link().code, _link().code);
    expect(_link().copyWith(locked: false).code, isNot(_link().code));
  });

  test('o Stockfish viaja como sf e não leva nível', () {
    final link = _link().copyWith(opponent: OpponentKind.stockfish);
    expect(link.params['opp'], 'sf');
    expect(link.params.containsKey('lvl'), isFalse);
    final back = ChallengeLink.tryParse(link.uri)!;
    expect(back.opponent, OpponentKind.stockfish);
    expect(back.level, isNull);
  });

  test('só os utm conhecidos viajam', () {
    final link = _link().copyWith(
      utm: const {'utm_source': 'x', 'segredo': 'y'},
    );
    expect(link.uri.queryParameters.containsKey('segredo'), isFalse);
    expect(link.uri.queryParameters['utm_source'], 'x');
  });

  test('rejeita o que não é desafio', () {
    expect(ChallengeLink.tryParse(Uri.parse('https://playlucena.com/')), null);
    expect(
      ChallengeLink.tryParse(Uri.parse('https://playlucena.com/p/abcde')),
      null,
    );
    expect(
      ChallengeLink.tryParse(
        Uri.parse('https://playlucena.com/p/abcde?fen=lixo'),
      ),
      null,
    );
    expect(
      ChallengeLink.tryParse(Uri.parse('https://playlucena.com/x/abcde')),
      null,
    );
  });

  test('sem lado, joga quem tem a vez', () {
    final uri = Uri.parse(
      'https://playlucena.com/p/abcde?fen=${Uri.encodeQueryComponent('8/8/8/4k3/8/8/4K3/4Q3 b - - 0 1')}',
    );
    expect(ChallengeLink.tryParse(uri)!.userSide, Side.black);
  });

  test('o link criado no app leva utm_source=app e a geração', () {
    final link = ChallengeLink(
      fen: _fen,
      userSide: Side.white,
    ).sharedFrom('fim_partida', generation: 3);
    final query = link.uri.queryParameters;
    expect(query['utm_source'], 'app');
    expect(query['utm_medium'], 'compartilhar');
    expect(query['utm_campaign'], 'fim_partida');
    expect(query['g'], '3');

    final back = ChallengeLink.tryParse(link.uri)!;
    expect(back.generation, 3);
    expect(back.utm['utm_source'], 'app');
    // A geração e as utm não mudam o desafio.
    expect(back.code, ChallengeLink(fen: _fen, userSide: Side.white).code);
  });

  test('sem geração, o link não leva g', () {
    final link = ChallengeLink(fen: _fen, userSide: Side.white);
    expect(link.uri.queryParameters.containsKey('g'), isFalse);
    expect(ChallengeLink.tryParse(link.uri)!.generation, 0);
  });
}
