import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/treinador/view_models/ligar_conta_cubit.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';

/// Um repositório em que ligar a conta falha com um erro qualquer.
class _RepoQueQuebra extends FakeTreinadorRepository {
  @override
  Future<void> ligarConta(Plataforma plataforma, String usuario) =>
      Future.error(StateError('sem rede'));
}

/// Um repositório em que ligar a conta espera o teste soltar.
class _RepoComPortao extends FakeTreinadorRepository {
  final portao = Completer<void>();

  @override
  Future<void> ligarConta(Plataforma plataforma, String usuario) async {
    await portao.future;
    return super.ligarConta(plataforma, usuario);
  }
}

void main() {
  late FakeTreinadorRepository repo;

  LigarContaCubit criar({
    Plataforma plataforma = Plataforma.lichess,
    FakeTreinadorRepository? r,
  }) {
    final c = LigarContaCubit(repository: r ?? repo, plataforma: plataforma);
    addTearDown(c.close);
    return c;
  }

  setUp(() => repo = FakeTreinadorRepository());

  test('começa vazio, na plataforma escolhida, sem poder enviar', () {
    final c = criar(plataforma: Plataforma.chesscom);
    expect(c.state.plataforma, Plataforma.chesscom);
    expect(c.state.usuario, isEmpty);
    expect(c.state.podeEnviar, isFalse);
    expect(c.state.enviando, isFalse);
    expect(c.state.ligada, isFalse);
    expect(c.state.falha, isNull);
  });

  group('digitar', () {
    test('com texto pode enviar; só espaços não', () {
      final c = criar();
      c.digitar('   ');
      expect(c.state.podeEnviar, isFalse);
      c.digitar('  gabriel ');
      expect(c.state.podeEnviar, isTrue);
    });

    test('digitar limpa a falha anterior', () async {
      repo.falhaLigar = FalhaLigarConta.naoExiste;
      final c = criar();
      c.digitar('fantasma');
      await c.ligar();
      expect(c.state.falha, FalhaLigarConta.naoExiste);
      c.digitar('fantasm');
      expect(c.state.falha, isNull);
    });
  });

  group('ligar', () {
    test('sucesso: liga a conta com o usuário sem espaços', () async {
      final c = criar();
      c.digitar('  gabriel_lucena ');
      await c.ligar();
      expect(c.state.ligada, isTrue);
      expect(c.state.enviando, isFalse);
      expect(c.state.falha, isNull);
      expect(repo.ligacoes, [(Plataforma.lichess, 'gabriel_lucena')]);
    });

    test('usa a plataforma do chess.com', () async {
      final c = criar(plataforma: Plataforma.chesscom);
      c.digitar('hikaru');
      await c.ligar();
      expect(repo.ligacoes, [(Plataforma.chesscom, 'hikaru')]);
    });

    test('a conta ligada chega ao repositório', () async {
      final c = criar();
      c.digitar('gabriel_lucena');
      await c.ligar();
      final conta = await repo.conta().first;
      expect(conta?.usuario, 'gabriel_lucena');
      expect(conta?.plataforma, Plataforma.lichess);
    });

    test('conta que não existe: falha naoExiste, sem ligar', () async {
      repo.falhaLigar = FalhaLigarConta.naoExiste;
      final c = criar();
      c.digitar('fantasma');
      await c.ligar();
      expect(c.state.falha, FalhaLigarConta.naoExiste);
      expect(c.state.ligada, isFalse);
      expect(c.state.enviando, isFalse);
      expect(c.state.podeEnviar, isTrue);
    });

    test('sem plano: falha semPlano', () async {
      repo.falhaLigar = FalhaLigarConta.semPlano;
      final c = criar();
      c.digitar('gabriel_lucena');
      await c.ligar();
      expect(c.state.falha, FalhaLigarConta.semPlano);
      expect(c.state.ligada, isFalse);
    });

    test('sem resposta do servidor: falha semResposta', () async {
      repo.falhaLigar = FalhaLigarConta.semResposta;
      final c = criar();
      c.digitar('gabriel_lucena');
      await c.ligar();
      expect(c.state.falha, FalhaLigarConta.semResposta);
    });

    test('sem login no Lucena: falha semLogin', () async {
      repo.falhaLigar = FalhaLigarConta.semLogin;
      final c = criar();
      c.digitar('gabriel_lucena');
      await c.ligar();
      expect(c.state.falha, FalhaLigarConta.semLogin);
    });

    test('erro qualquer vira semResposta', () async {
      final c = criar(r: _RepoQueQuebra());
      c.digitar('gabriel_lucena');
      await c.ligar();
      expect(c.state.falha, FalhaLigarConta.semResposta);
      expect(c.state.enviando, isFalse);
    });

    test('tentar de novo depois da falha liga', () async {
      repo.falhaLigar = FalhaLigarConta.semResposta;
      final c = criar();
      c.digitar('gabriel_lucena');
      await c.ligar();
      expect(c.state.ligada, isFalse);
      await c.ligar();
      expect(c.state.ligada, isTrue);
      expect(c.state.falha, isNull);
      expect(repo.ligacoes, hasLength(2));
    });

    test('sem usuário digitado não chama o repositório', () async {
      final c = criar();
      await c.ligar();
      c.digitar('   ');
      await c.ligar();
      expect(repo.ligacoes, isEmpty);
      expect(c.state.enviando, isFalse);
    });

    test('enquanto envia: enviando, não pode reenviar', () async {
      final r = _RepoComPortao();
      final c = criar(r: r);
      c.digitar('gabriel_lucena');
      final primeiro = c.ligar();
      expect(c.state.enviando, isTrue);
      expect(c.state.podeEnviar, isFalse);
      await c.ligar();
      r.portao.complete();
      await primeiro;
      expect(r.ligacoes, hasLength(1));
      expect(c.state.ligada, isTrue);
    });

    test('fechar durante o envio não emite depois', () async {
      final r = _RepoComPortao();
      final c = criar(r: r);
      c.digitar('gabriel_lucena');
      final envio = c.ligar();
      await c.close();
      r.portao.complete();
      await expectLater(envio, completes);
    });
  });
}
