import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/coach/view_models/link_account_cubit.dart';

import '../../../testing/fakes/fake_coach_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';

/// Um repositório em que ligar a conta falha com um erro qualquer.
class _RepoThatBreaks extends FakeCoachRepository {
  @override
  Future<void> linkAccount(Platform platform, String username) =>
      Future.error(StateError('sem rede'));
}

/// Um repositório em que ligar a conta espera o teste soltar.
class _RepoWithGate extends FakeCoachRepository {
  final gate = Completer<void>();

  @override
  Future<void> linkAccount(Platform platform, String username) async {
    await gate.future;
    return super.linkAccount(platform, username);
  }
}

void main() {
  late FakeCoachRepository repo;
  late FakeLichessRepository lichess;

  LinkAccountCubit create({
    Platform platform = Platform.chesscom,
    FakeCoachRepository? r,
  }) {
    final c = LinkAccountCubit(
      repository: r ?? repo,
      lichess: lichess,
      platform: platform,
    );
    addTearDown(c.close);
    return c;
  }

  setUp(() {
    repo = FakeCoachRepository();
    lichess = FakeLichessRepository();
  });

  test('começa vazio, na plataforma escolhida, sem poder enviar', () {
    final c = create(platform: Platform.chesscom);
    expect(c.state.platform, Platform.chesscom);
    expect(c.state.username, isEmpty);
    expect(c.state.canSend, isFalse);
    expect(c.state.sending, isFalse);
    expect(c.state.linked, isFalse);
    expect(c.state.failure, isNull);
  });

  group('digitar', () {
    test('com texto pode enviar; só espaços não', () {
      final c = create();
      c.typeText('   ');
      expect(c.state.canSend, isFalse);
      c.typeText('  gabriel ');
      expect(c.state.canSend, isTrue);
    });

    test('digitar limpa a falha anterior', () async {
      repo.linkFailure = LinkAccountFailure.doesNotExist;
      final c = create();
      c.typeText('fantasma');
      await c.link();
      expect(c.state.failure, LinkAccountFailure.doesNotExist);
      c.typeText('fantasm');
      expect(c.state.failure, isNull);
    });
  });

  group('ligar', () {
    test('sucesso: liga a conta com o usuário sem espaços', () async {
      final c = create();
      c.typeText('  gabriel_lucena ');
      await c.link();
      expect(c.state.linked, isTrue);
      expect(c.state.sending, isFalse);
      expect(c.state.failure, isNull);
      expect(repo.links, [(Platform.chesscom, 'gabriel_lucena')]);
    });

    test('usa a plataforma do chess.com', () async {
      final c = create();
      c.typeText('hikaru');
      await c.link();
      expect(repo.links, [(Platform.chesscom, 'hikaru')]);
    });

    test('a conta ligada chega ao repositório', () async {
      final c = create();
      c.typeText('gabriel_lucena');
      await c.link();
      final account = await repo.account().first;
      expect(account?.username, 'gabriel_lucena');
      expect(account?.platform, Platform.chesscom);
    });

    test('conta que não existe: falha naoExiste, sem ligar', () async {
      repo.linkFailure = LinkAccountFailure.doesNotExist;
      final c = create();
      c.typeText('fantasma');
      await c.link();
      expect(c.state.failure, LinkAccountFailure.doesNotExist);
      expect(c.state.linked, isFalse);
      expect(c.state.sending, isFalse);
      expect(c.state.canSend, isTrue);
    });

    test('sem plano: falha semPlano', () async {
      repo.linkFailure = LinkAccountFailure.noPlan;
      final c = create();
      c.typeText('gabriel_lucena');
      await c.link();
      expect(c.state.failure, LinkAccountFailure.noPlan);
      expect(c.state.linked, isFalse);
    });

    test('sem resposta do servidor: falha semResposta', () async {
      repo.linkFailure = LinkAccountFailure.noResponse;
      final c = create();
      c.typeText('gabriel_lucena');
      await c.link();
      expect(c.state.failure, LinkAccountFailure.noResponse);
    });

    test('sem login no Lucena: falha semLogin', () async {
      repo.linkFailure = LinkAccountFailure.noLogin;
      final c = create();
      c.typeText('gabriel_lucena');
      await c.link();
      expect(c.state.failure, LinkAccountFailure.noLogin);
    });

    test('erro qualquer vira semResposta', () async {
      final c = create(r: _RepoThatBreaks());
      c.typeText('gabriel_lucena');
      await c.link();
      expect(c.state.failure, LinkAccountFailure.noResponse);
      expect(c.state.sending, isFalse);
    });

    test('tentar de novo depois da falha liga', () async {
      repo.linkFailure = LinkAccountFailure.noResponse;
      final c = create();
      c.typeText('gabriel_lucena');
      await c.link();
      expect(c.state.linked, isFalse);
      await c.link();
      expect(c.state.linked, isTrue);
      expect(c.state.failure, isNull);
      expect(repo.links, hasLength(2));
    });

    test('sem usuário digitado não chama o repositório', () async {
      final c = create();
      await c.link();
      c.typeText('   ');
      await c.link();
      expect(repo.links, isEmpty);
      expect(c.state.sending, isFalse);
    });

    test('enquanto envia: enviando, não pode reenviar', () async {
      final r = _RepoWithGate();
      final c = create(r: r);
      c.typeText('gabriel_lucena');
      final firstOne = c.link();
      expect(c.state.sending, isTrue);
      expect(c.state.canSend, isFalse);
      await c.link();
      r.gate.complete();
      await firstOne;
      expect(r.links, hasLength(1));
      expect(c.state.linked, isTrue);
    });

    test('fechar durante o envio não emite depois', () async {
      final r = _RepoWithGate();
      final c = create(r: r);
      c.typeText('gabriel_lucena');
      final sent = c.link();
      await c.close();
      r.gate.complete();
      await expectLater(sent, completes);
    });
  });

  group('Lichess pelo login de lá', () {
    test('sem login: abre o Lichess e manda o token ao servidor', () async {
      final c = create(platform: Platform.lichess);
      await c.linkLichess();
      expect(lichess.connects, 1);
      expect(repo.lichessTokens, ['token-falso-do-lichess']);
      expect(c.state.linked, isTrue);
      final account = await repo.account().first;
      expect(account?.platform, Platform.lichess);
    });

    test('com login do Perfil: usa o token que já existe', () async {
      lichess.connected = true;
      final c = create(platform: Platform.lichess);
      await c.linkLichess();
      expect(lichess.connects, 0);
      expect(c.state.linked, isTrue);
    });

    test(
      'token que não vale mais: sai, entra de novo e tenta uma vez',
      () async {
        lichess.connected = true;
        repo.revokedTokens.add('token-falso-do-lichess');
        lichess.hold = true;
        final c = create(platform: Platform.lichess);
        final done = c.linkLichess();
        await pumpEventQueue();
        lichess.token = 'token-falso-novo-do-lichess';
        lichess.complete();
        await done;
        expect(lichess.disconnects, 1);
        expect(lichess.connects, 1);
        expect(repo.lichessTokens, [
          'token-falso-do-lichess',
          'token-falso-novo-do-lichess',
        ]);
        expect(c.state.linked, isTrue);
      },
    );

    test('o login novo também não vale: falha lichessLogin', () async {
      lichess.connected = true;
      repo.revokedTokens.add('token-falso-do-lichess');
      final c = create(platform: Platform.lichess);
      await c.linkLichess();
      expect(repo.lichessTokens, hasLength(2));
      expect(c.state.failure, LinkAccountFailure.lichessLogin);
      expect(c.state.linked, isFalse);
    });

    test('voltou sem autorizar: cancelado, sem erro', () async {
      lichess.hold = true;
      final c = create(platform: Platform.lichess);
      final done = c.linkLichess();
      await pumpEventQueue();
      lichess.cancel();
      await done;
      expect(c.state.cancelled, isTrue);
      expect(c.state.failure, isNull);
      expect(c.state.sending, isFalse);
      expect(repo.lichessTokens, isEmpty);
    });

    test('muitas tentativas: falha tooMany', () async {
      repo.linkFailure = LinkAccountFailure.tooMany;
      final c = create(platform: Platform.lichess);
      await c.linkLichess();
      expect(c.state.failure, LinkAccountFailure.tooMany);
      expect(c.state.linked, isFalse);
    });
  });
}
