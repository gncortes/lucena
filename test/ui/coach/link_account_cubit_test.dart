import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/ui/coach/view_models/link_account_cubit.dart';

import '../../../testing/fakes/fake_coach_repository.dart';

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

  LinkAccountCubit create({
    Platform platform = Platform.lichess,
    FakeCoachRepository? r,
  }) {
    final c = LinkAccountCubit(repository: r ?? repo, platform: platform);
    addTearDown(c.close);
    return c;
  }

  setUp(() => repo = FakeCoachRepository());

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
      expect(repo.links, [(Platform.lichess, 'gabriel_lucena')]);
    });

    test('usa a plataforma do chess.com', () async {
      final c = create(platform: Platform.chesscom);
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
      expect(account?.platform, Platform.lichess);
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
}
