import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/core/keys/treinador_seu_jogo_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/treinador/widgets/linha_partida.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

/// A primeira leitura das partidas só chega quando o teste deixa.
class _RepoLento extends FakeTreinadorRepository {
  _RepoLento()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
        estatisticas: TreinadorFixtures.estatisticas(),
      );

  final liberar = Completer<void>();

  @override
  Stream<List<PartidaTreinador>> partidas() async* {
    await liberar.future;
    yield* super.partidas();
  }
}

/// A leitura das partidas falha (sem rede na primeira vez).
class _RepoSemRede extends FakeTreinadorRepository {
  _RepoSemRede()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
        estatisticas: TreinadorFixtures.estatisticas(),
      );

  bool falhar = true;

  @override
  Stream<List<PartidaTreinador>> partidas() =>
      falhar ? Stream.error(StateError('sem rede')) : super.partidas();

  @override
  Stream<TreinadorConta?> conta() =>
      falhar ? Stream.error(StateError('sem rede')) : super.conta();
}

/// A conta vem do cache e só a leitura das partidas falha.
class _RepoSoPartidasFalham extends FakeTreinadorRepository {
  _RepoSoPartidasFalham() : super(conta: TreinadorFixtures.conta);

  @override
  Stream<List<PartidaTreinador>> partidas() =>
      Stream.error(StateError('sem rede'));
}

FakeTreinadorRepository _comDados() => FakeTreinadorRepository(
  conta: TreinadorFixtures.conta,
  partidas: TreinadorFixtures.lista(),
  estatisticas: TreinadorFixtures.estatisticas(),
);

/// Rola até o item aparecer e toca nele.
Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await assentar(tester);
}

Finder _textoEm(Key key, String texto) =>
    find.descendant(of: find.byKey(key), matching: find.text(texto));

ProgressoPartida _progresso(int feitos, {int acertos = 0}) => ProgressoPartida(
  resultados: [
    for (var n = 1; n <= feitos; n++)
      ResultadoExercicio(
        n: n,
        acertou: n <= acertos,
        pontos: n <= acertos ? 10 : 0,
      ),
  ],
);

void main() {
  group('carregando e falha de leitura', () {
    testWidgets('enquanto as partidas não chegam, mostra o esqueleto', (
      tester,
    ) async {
      aparelho411x914(tester);
      final repo = _RepoLento();
      final bed = TreinadorBed(repo: repo, grants: comPlano());
      await bed.abrir(tester, Routes.treinador());

      expect(find.byType(LoadSkeletonScreen), findsOneWidget);
      expect(find.byKey(TreinadorKeys.screen), findsNothing);
      expect(find.text('Análise'), findsOneWidget);

      repo.liberar.complete();
      await assentar(tester);
      expect(find.byType(LoadSkeletonScreen), findsNothing);
      expect(find.byKey(TreinadorKeys.screen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem rede e sem dados, mostra o erro e tentar de novo '
        'recupera', (tester) async {
      aparelho411x914(tester);
      final repo = _RepoSemRede();
      final bed = TreinadorBed(repo: repo, grants: comPlano());
      await bed.abrir(tester, Routes.treinador());

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.screen), findsNothing);

      repo.falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await assentar(tester);
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(find.byKey(TreinadorKeys.hoje), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('conta em cache, partidas sem rede', () {
    testWidgets('mostra o erro de rede, não o vazio "Jogue uma partida"', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(
        repo: _RepoSoPartidasFalham(),
        grants: comPlano(),
      );
      await bed.abrir(tester, Routes.treinador());

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.byKey(TreinadorKeys.hojeVazio), findsNothing);
      expect(find.textContaining('Jogue uma partida'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('sem conta ligada', () {
    late TreinadorBed bed;

    setUp(() {
      bed = TreinadorBed(repo: FakeTreinadorRepository(), grants: comPlano());
    });

    testWidgets(
      'mostra "Conecte sua conta", os dois sites e a barra das abas',
      (tester) async {
        aparelho411x914(tester);
        await bed.abrir(tester, Routes.treinador());

        expect(find.byKey(TreinadorKeys.ligarConta), findsOneWidget);
        expect(find.text('Conecte sua conta'), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
        expect(
          _textoEm(TreinadorKeys.ligarLichess, 'Conectar o Lichess'),
          findsOneWidget,
        );
        expect(
          _textoEm(TreinadorKeys.ligarChesscom, 'Conectar o chess.com'),
          findsOneWidget,
        );
        // Canvas DLigarConta: o Lichess é o primário (cheio); o chess.com, contornado.
        expect(
          tester.widget(find.byKey(TreinadorKeys.ligarLichess)),
          isA<FilledButton>(),
        );
        expect(
          tester.widget(find.byKey(TreinadorKeys.ligarChesscom)),
          isA<OutlinedButton>(),
        );
        expect(
          find.text(
            'Só lemos partidas públicas. Você pode desconectar quando quiser.',
          ),
          findsOneWidget,
        );
        // O bloco fica no meio da altura e a barra das abas aparece.
        final bloco = tester.getCenter(find.byIcon(Icons.link)).dy;
        expect(bloco, inInclusiveRange(250, 450));
        expect(find.byKey(TreinadorKeys.tabHoje), findsOneWidget);
        expect(find.byKey(TreinadorKeys.hoje), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('escolher o Lichess mostra o campo do usuário; ligar leva '
        'às abas', (tester) async {
      aparelho411x914(tester);
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.ligarLichess));
      await assentar(tester);
      expect(find.byKey(TreinadorKeys.usuario), findsOneWidget);
      expect(find.text('Seu usuário no Lichess'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.ligarLichess), findsNothing);
      expect(
        _textoEm(TreinadorKeys.confirmarConta, 'Conectar a conta'),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.trocarSite, 'Trocar de site'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(TreinadorKeys.usuario), 'gabriel');
      await assentar(tester);
      await tester.tap(find.byKey(TreinadorKeys.confirmarConta));
      await assentar(tester);

      expect(bed.repo.ligacoes, [(Plataforma.lichess, 'gabriel')]);
      expect(find.byKey(TreinadorKeys.ligarConta), findsNothing);
      expect(find.byKey(TreinadorKeys.tabHoje), findsOneWidget);
      expect(find.byKey(TreinadorKeys.hojeVazio), findsOneWidget);
      expect(
        find.text('Jogue uma partida no Lichess e ela aparece aqui.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('escolher o chess.com mostra o nome do site no campo', (
      tester,
    ) async {
      aparelho411x914(tester);
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.ligarChesscom));
      await assentar(tester);
      expect(find.text('Seu usuário no chess.com'), findsOneWidget);

      await tester.enterText(find.byKey(TreinadorKeys.usuario), 'magnus');
      await assentar(tester);
      await tester.tap(find.byKey(TreinadorKeys.confirmarConta));
      await assentar(tester);
      expect(bed.repo.ligacoes, [(Plataforma.chesscom, 'magnus')]);
    });

    testWidgets('"Trocar de site" volta à escolha', (tester) async {
      aparelho411x914(tester);
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.ligarLichess));
      await assentar(tester);
      await tester.tap(find.byKey(TreinadorKeys.trocarSite));
      await assentar(tester);

      expect(find.byKey(TreinadorKeys.usuario), findsNothing);
      expect(find.byKey(TreinadorKeys.ligarLichess), findsOneWidget);
      expect(find.byKey(TreinadorKeys.ligarChesscom), findsOneWidget);
    });

    for (final (falha, texto) in [
      (FalhaLigarConta.naoExiste, 'Não achamos esse usuário no Lichess.'),
      (
        FalhaLigarConta.semResposta,
        'Sem resposta do servidor. Verifique sua conexão com a internet e '
            'tente novamente.',
      ),
      (
        FalhaLigarConta.semLogin,
        'Entre na sua conta do Lucena para conectar a conta de xadrez.',
      ),
    ]) {
      testWidgets('falha $falha mostra o texto do erro e não liga', (
        tester,
      ) async {
        aparelho411x914(tester);
        bed.repo.falhaLigar = falha;
        await bed.abrir(tester, Routes.treinador());

        await tester.tap(find.byKey(TreinadorKeys.ligarLichess));
        await assentar(tester);
        await tester.enterText(find.byKey(TreinadorKeys.usuario), 'ninguem');
        await assentar(tester);
        await tester.tap(find.byKey(TreinadorKeys.confirmarConta));
        await assentar(tester);

        expect(find.byKey(TreinadorKeys.contaErro), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(TreinadorKeys.contaErro)).data,
          texto,
        );
        expect(find.byKey(TreinadorKeys.ligarConta), findsOneWidget);
        expect(find.byKey(TreinadorKeys.conhecerPlano), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sem o plano de análise, o erro oferece conhecer o plano', (
      tester,
    ) async {
      aparelho411x914(tester);
      bed.repo.falhaLigar = FalhaLigarConta.semPlano;
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.ligarLichess));
      await assentar(tester);
      await tester.enterText(find.byKey(TreinadorKeys.usuario), 'gabriel');
      await assentar(tester);
      await tester.tap(find.byKey(TreinadorKeys.confirmarConta));
      await assentar(tester);

      expect(
        tester.widget<Text>(find.byKey(TreinadorKeys.contaErro)).data,
        'Para conectar a conta, você precisa do plano de análise.',
      );
      expect(
        _textoEm(TreinadorKeys.conhecerPlano, 'Conhecer o plano de análise'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(TreinadorKeys.conhecerPlano));
      await assentar(tester);
      expect(bed.caminho, '/pilares');
      expect(find.text('stub.pilares'), findsOneWidget);
    });

    testWidgets('o voltar fecha a tela e volta à home', (tester) async {
      aparelho411x914(tester);
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.back));
      await assentar(tester);
      expect(find.text('stub.home'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.screen), findsNothing);
    });
  });

  group('aba Hoje', () {
    testWidgets('com plano: a última partida, o botão e os exercícios que '
        'faltam', (tester) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _comDados(), grants: comPlano());
      await bed.abrir(tester, Routes.treinador());

      expect(find.byKey(TreinadorKeys.hoje), findsOneWidget);
      expect(find.text('Análise'), findsOneWidget);
      for (final aba in ['Hoje', 'Partidas', 'Seu jogo']) {
        expect(
          find.descendant(
            of: find.byKey(switch (aba) {
              'Hoje' => TreinadorKeys.tabHoje,
              'Partidas' => TreinadorKeys.tabPartidas,
              _ => TreinadorKeys.tabSeuJogo,
            }),
            matching: find.text(aba),
          ),
          findsOneWidget,
        );
      }
      expect(find.byKey(TreinadorKeys.semPlano), findsNothing);
      expect(find.text('Última partida'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.ultimaPartida), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.verUltimaPartida, 'Ver a partida'),
        findsOneWidget,
      );
      expect(find.text('Para fazer agora'), findsOneWidget);
      // O cartão traz o resumo da partida (Tiago_Rook, pronta).
      expect(
        _textoEm(
          TreinadorKeys.ultimaPartida,
          'Você perdeu no lance 51, num final de torres que empatava.',
        ),
        findsOneWidget,
      );
      // O próximo exercício pendente: o tema e a posição, no CourseItemTile.
      final item = TreinadorKeys.paraFazerExercicio(
        TreinadorFixtures.idTiago,
        1,
      );
      expect(find.byKey(item), findsOneWidget);
      expect(_textoEm(item, 'Sacrificio h7'), findsOneWidget);
      expect(
        _textoEm(item, 'Posição da sua partida contra Tiago_Rook, lance 8.'),
        findsOneWidget,
      );
      expect(_textoEm(item, 'Xeque duplo'), findsNothing);
      // Um item por partida: o próximo; os outros ficam para depois.
      expect(
        find.byKey(
          TreinadorKeys.paraFazerExercicio(TreinadorFixtures.idTiago, 3),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver a partida" abre a partida da lista', (tester) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _comDados(), grants: comPlano());
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.verUltimaPartida));
      await assentar(tester);

      expect(bed.caminho, '/treinador/partida/${TreinadorFixtures.idTiago}');
      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
    });

    testWidgets(
      'tocar no exercício para fazer abre a partida no exercício mostrado',
      (tester) async {
        aparelho411x914(tester);
        final bed = TreinadorBed(repo: _comDados(), grants: comPlano());
        await bed.abrir(tester, Routes.treinador());

        await _tocar(
          tester,
          find.byKey(
            TreinadorKeys.paraFazerExercicio(TreinadorFixtures.idTiago, 1),
          ),
        );
        expect(
          bed.caminho,
          startsWith(
            '/treinador/partida/${TreinadorFixtures.idTiago}/exercicios',
          ),
        );
      },
    );

    testWidgets('só o próximo exercício pendente de cada partida aparece', (
      tester,
    ) async {
      aparelho411x914(tester);
      final parcial = TreinadorFixtures.tiago().copyWith(
        progresso: _progresso(2, acertos: 1),
      );
      final bed = TreinadorBed(
        repo: FakeTreinadorRepository(
          conta: TreinadorFixtures.conta,
          partidas: [parcial],
        ),
        grants: comPlano(),
      );
      await bed.abrir(tester, Routes.treinador());

      for (final n in [1, 2, 4]) {
        expect(
          find.byKey(
            TreinadorKeys.paraFazerExercicio(TreinadorFixtures.idTiago, n),
          ),
          findsNothing,
        );
      }
      expect(
        find.byKey(
          TreinadorKeys.paraFazerExercicio(TreinadorFixtures.idTiago, 3),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem plano: mostra a caixa e conhecer o plano abre a venda', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _comDados());
      await bed.abrir(tester, Routes.treinador());

      expect(find.byKey(TreinadorKeys.semPlano), findsWidgets);
      expect(find.text('Análise de partidas'), findsOneWidget);
      expect(
        find.text(
          'Com o plano de análise, toda partida nova vira exercícios. '
          'Sem ele, são 3 análises grátis por semana.',
        ),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.conhecerPlano, 'Conhecer o plano de análise'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(TreinadorKeys.conhecerPlano));
      await assentar(tester);
      expect(bed.caminho, '/pilares');
    });

    testWidgets('sem partidas: mostra o aviso do site da conta', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(
        repo: FakeTreinadorRepository(conta: TreinadorFixtures.conta),
        grants: comPlano(),
      );
      await bed.abrir(tester, Routes.treinador());

      expect(find.byKey(TreinadorKeys.hojeVazio), findsOneWidget);
      expect(
        find.text('Jogue uma partida no Lichess e ela aparece aqui.'),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.ultimaPartida), findsNothing);
      expect(find.text('Exercícios para fazer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com todos os exercícios feitos, diz que está em dia', (
      tester,
    ) async {
      aparelho411x914(tester);
      final feita = TreinadorFixtures.tiago().copyWith(
        progresso: _progresso(4, acertos: 3),
      );
      final bed = TreinadorBed(
        repo: FakeTreinadorRepository(
          conta: TreinadorFixtures.conta,
          partidas: [feita],
        ),
        grants: comPlano(),
      );
      await bed.abrir(tester, Routes.treinador());

      expect(
        find.text('Você fez os exercícios de todas as partidas analisadas.'),
        findsOneWidget,
      );
      // O cartão da última partida mostra o resumo, não o estado.
      expect(find.text('3 de 4 certos'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(TreinadorKeys.tabPartidas));
      await assentar(tester);
      expect(
        find.text('Precisão 78% · 3 de 4 exercícios certos'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('aba Partidas', () {
    late TreinadorBed bed;

    setUp(() {
      bed = TreinadorBed(repo: _comDados(), grants: comPlano());
    });

    Future<void> abrirPartidas(WidgetTester tester) async {
      aparelho411x914(tester);
      await bed.abrir(tester, Routes.treinador());
      await tester.tap(find.byKey(TreinadorKeys.tabPartidas));
      await assentar(tester);
    }

    testWidgets('lista as cinco partidas com os filtros e o estado de '
        'cada uma', (tester) async {
      await abrirPartidas(tester);

      expect(find.byKey(TreinadorKeys.partidas), findsOneWidget);
      expect(find.byKey(TreinadorKeys.partidasBase), findsWidgets);
      expect(find.byType(LinhaPartida), findsNWidgets(5));
      // Canvas DPartidasFiltro: sem rótulos, "Todas" no resultado e a contagem.
      expect(find.text('Ritmo'), findsNothing);
      expect(find.text('Resultado'), findsNothing);
      expect(
        find.text('5 partidas do Lichess, da mais recente'),
        findsOneWidget,
      );
      for (final (key, texto) in [
        (TreinadorKeys.filtroTodas, 'Todas'),
        (TreinadorKeys.filtroRitmo('bullet'), 'Bullet'),
        (TreinadorKeys.filtroRitmo('blitz'), 'Blitz'),
        (TreinadorKeys.filtroRitmo('rapida'), 'Rápido'),
        (TreinadorKeys.filtroResultado('vitoria'), 'Vitórias'),
        (TreinadorKeys.filtroResultado('derrota'), 'Derrotas'),
        (TreinadorKeys.filtroResultado('empate'), 'Empates'),
      ]) {
        expect(_textoEm(key, texto), findsOneWidget, reason: '$key');
      }
      expect(find.text('Pronta para analisar'), findsNWidgets(3));
      expect(find.text('Analisando…'), findsOneWidget);
      expect(find.text('0 de 4 exercícios feitos'), findsOneWidget);
      // Uma fileira só: "Todas" aparece uma vez.
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Todos'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('o filtro de ritmo reduz a lista', (tester) async {
      await abrirPartidas(tester);

      await _tocar(tester, find.byKey(TreinadorKeys.filtroRitmo('rapida')));
      expect(find.byType(LinhaPartida), findsNWidgets(2));
      expect(
        find.byKey(TreinadorKeys.partida('lichess_DeF67890')),
        findsOneWidget,
      );
      expect(
        find.byKey(TreinadorKeys.partida('lichess_MnO11223')),
        findsOneWidget,
      );
      expect(
        find.byKey(TreinadorKeys.partida('lichess_JkL24680')),
        findsNothing,
      );
    });

    testWidgets('filtros sem partida mostram o vazio e limpar volta a lista', (
      tester,
    ) async {
      await abrirPartidas(tester);

      await _tocar(tester, find.byKey(TreinadorKeys.filtroRitmo('rapida')));
      await _tocar(
        tester,
        find.byKey(TreinadorKeys.filtroResultado('derrota')),
      );

      expect(find.byKey(TreinadorKeys.partidasVazio), findsOneWidget);
      expect(find.text('Nenhuma partida com esses filtros.'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.partidasBase), findsNothing);
      expect(
        _textoEm(TreinadorKeys.limparFiltros, 'Limpar filtros'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(TreinadorKeys.limparFiltros));
      await assentar(tester);
      expect(find.byType(LinhaPartida), findsNWidgets(5));
      expect(find.byKey(TreinadorKeys.partidasVazio), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar numa partida nova já começa a analisar (A10 G2)', (
      tester,
    ) async {
      await abrirPartidas(tester);

      await tester.tap(find.byKey(TreinadorKeys.partida('lichess_DeF67890')));
      await assentar(tester);

      expect(bed.caminho, '/treinador/partida/lichess_DeF67890');
      expect(find.byKey(TreinadorKeys.carregando), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sem partidas, mostra o aviso e não os filtros vazios', (
      tester,
    ) async {
      aparelho411x914(tester);
      bed = TreinadorBed(
        repo: FakeTreinadorRepository(conta: TreinadorFixtures.conta),
        grants: comPlano(),
      );
      await bed.abrir(tester, Routes.treinador());
      await tester.tap(find.byKey(TreinadorKeys.tabPartidas));
      await assentar(tester);

      expect(find.byKey(TreinadorKeys.partidasVazio), findsOneWidget);
      expect(
        find.text('Jogue uma partida no Lichess e ela aparece aqui.'),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.limparFiltros), findsNothing);
    });

    testWidgets('o filtro escolhido fica salvo para a próxima vez', (
      tester,
    ) async {
      await abrirPartidas(tester);
      await _tocar(tester, find.byKey(TreinadorKeys.filtroResultado('empate')));
      expect(find.byType(LinhaPartida), findsNWidgets(1));

      // Reabre a tela: o filtro volta como estava.
      bed.router.go('/');
      await assentar(tester);
      unawaited(bed.router.push(Routes.treinador(aba: 'partidas')));
      await assentar(tester);
      expect(find.byType(LinhaPartida), findsNWidgets(1));
    });
  });

  group('aba Seu jogo', () {
    testWidgets('a aba mostra o Seu jogo de verdade, sem o "em breve"', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _comDados(), grants: comPlano());
      await bed.abrir(tester, Routes.treinador());

      await tester.tap(find.byKey(TreinadorKeys.tabSeuJogo));
      await assentar(tester);
      expect(find.byKey(TreinadorKeys.seuJogo), findsOneWidget);
      expect(find.byKey(SeuJogoKeys.aba), findsOneWidget);
      expect(find.text('Em breve: onde você mais erra.'), findsNothing);
      expect(find.byKey(TreinadorKeys.hoje), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('o parâmetro da rota abre direto na aba pedida', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _comDados(), grants: comPlano());
      await bed.abrir(tester, Routes.treinador(aba: 'seuJogo'));
      expect(find.byKey(TreinadorKeys.seuJogo), findsOneWidget);

      await tester.tap(find.byKey(TreinadorKeys.tabHoje));
      await assentar(tester);
      expect(find.byKey(TreinadorKeys.hoje), findsOneWidget);
    });
  });

  group('A10 G1: atalho Análise da Home', () {
    testWidgets('abre a última partida, com a lista embaixo', (tester) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _comDados(), grants: comPlano());
      await bed.abrir(tester, Routes.treinador(abrirUltima: true));

      final ultima = TreinadorFixtures.lista().first;
      expect(bed.caminho, Routes.treinadorPartida(ultima.id));
      await tester.tap(find.byKey(TreinadorKeys.back));
      await assentar(tester);
      expect(find.byKey(TreinadorKeys.hoje), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a última já feita: fica na aba Hoje', (tester) async {
      aparelho411x914(tester);
      final ultima = TreinadorFixtures.lista().first;
      final repo = _comDados();
      await repo.salvarProgresso(
        ultima.id,
        _progresso(ultima.exercicios.length),
      );
      final bed = TreinadorBed(repo: repo, grants: comPlano());
      await bed.abrir(tester, Routes.treinador(abrirUltima: true));

      expect(find.byKey(TreinadorKeys.hoje), findsOneWidget);
      expect(bed.caminho, isNot(Routes.treinadorPartida(ultima.id)));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
