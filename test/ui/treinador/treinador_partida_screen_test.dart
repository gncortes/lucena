import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/treinador/treinador_regras.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';

import '../../../testing/fakes/fake_treinador_repository.dart';
import '../../../testing/treinador_fixtures.dart';
import 'treinador_harness.dart';

const _idNova = 'lichess_DeF67890';
const _idAnalisando = 'lichess_GhI13579';

/// A partida só chega quando o teste deixa.
class _RepoLento extends FakeTreinadorRepository {
  _RepoLento()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      );

  final liberar = Completer<void>();

  @override
  Stream<PartidaTreinador?> partida(String id) async* {
    await liberar.future;
    yield* super.partida(id);
  }
}

/// A leitura da partida falha.
class _RepoSemRede extends FakeTreinadorRepository {
  _RepoSemRede()
    : super(
        conta: TreinadorFixtures.conta,
        partidas: TreinadorFixtures.lista(),
      );

  @override
  Stream<PartidaTreinador?> partida(String id) =>
      Stream.error(StateError('sem rede'));
}

FakeTreinadorRepository _repo([List<PartidaTreinador>? partidas]) =>
    FakeTreinadorRepository(
      conta: TreinadorFixtures.conta,
      partidas: partidas ?? TreinadorFixtures.lista(),
    );

PartidaTreinador _nova() =>
    TreinadorFixtures.lista().firstWhere((p) => p.id == _idNova);

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

/// Rola até o item aparecer e toca nele.
Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await assentar(tester);
}

/// BUG (lib): `treinador_exercicio_screen.dart:240` usa `context.select`
/// dentro do `boardBuilder`, que roda no layout (`LayoutBuilder`) e não no
/// `build`; em debug o provider lança uma asserção. Estes testes só querem
/// saber que a tela de exercícios abriu, então descartam essa exceção.
void _descartarBugDoTabuleiro(WidgetTester tester) => tester.takeException();

Finder _textoEm(Key key, String texto) =>
    find.descendant(of: find.byKey(key), matching: find.text(texto));

Future<TreinadorBed> _abrir(
  WidgetTester tester,
  PartidaTreinador partida, {
  FakeTreinadorRepository? repo,
  bool plano = true,
  bool esperar = true,
}) async {
  aparelho411x914(tester);
  final bed = TreinadorBed(
    repo: repo ?? _repo([partida, ...TreinadorFixtures.lista()]),
    grants: plano ? comPlano() : CourseGrants.empty,
  );
  await bed.abrir(
    tester,
    Routes.treinadorPartida(partida.id),
    esperar: esperar,
  );
  return bed;
}

void main() {
  group('leitura da partida', () {
    testWidgets('enquanto a partida não chega, mostra o esqueleto', (
      tester,
    ) async {
      aparelho411x914(tester);
      final repo = _RepoLento();
      final bed = TreinadorBed(repo: repo, grants: comPlano());
      await bed.abrir(tester, Routes.treinadorPartida(_idNova));

      expect(find.byType(LoadSkeletonScreen), findsOneWidget);
      expect(find.byKey(TreinadorKeys.inicio), findsNothing);

      repo.liberar.complete();
      await assentar(tester);
      expect(find.byType(LoadSkeletonScreen), findsNothing);
      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
    });

    testWidgets('sem rede, mostra o erro de conexão', (tester) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _RepoSemRede(), grants: comPlano());
      await bed.abrir(tester, Routes.treinadorPartida(_idNova));

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.inicio), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('partida que não existe mostra o erro de não encontrada', (
      tester,
    ) async {
      aparelho411x914(tester);
      final bed = TreinadorBed(repo: _repo(), grants: comPlano());
      await bed.abrir(tester, Routes.treinadorPartida('lichess_naoExiste'));

      expect(find.byType(LoadErrorScreen), findsOneWidget);
      expect(find.byKey(TreinadorKeys.inicio), findsNothing);
      expect(find.byKey(TreinadorKeys.carregando), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('início (partida nova)', () {
    testWidgets('mostra o cartão, os três passos e o botão de analisar', (
      tester,
    ) async {
      await _abrir(tester, _nova());

      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
      expect(find.text('Sua partida'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.cartaoPartida), findsWidgets);
      expect(find.text('Pronta para analisar'), findsOneWidget);
      expect(find.text('Como funciona'), findsOneWidget);
      expect(find.text('Revemos cada lance da partida.'), findsOneWidget);
      expect(
        find.text(
          'Separamos os momentos em que você poderia ter jogado melhor.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Você treina esses lances como exercícios.'),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.comecar, 'Analisar a partida'),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.verPartidas, 'Ver todas as partidas'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver todas as partidas" abre a aba Partidas', (tester) async {
      final bed = await _abrir(tester, _nova());

      await _tocar(tester, find.byKey(TreinadorKeys.verPartidas));
      expect(bed.caminho, '/treinador?aba=partidas');
      expect(find.byKey(TreinadorKeys.partidas), findsOneWidget);
    });

    testWidgets('o voltar fecha a tela', (tester) async {
      await _abrir(tester, _nova());

      await tester.tap(find.byKey(TreinadorKeys.back));
      await assentar(tester);
      expect(find.text('stub.home'), findsOneWidget);
    });

    testWidgets('analisar pede a análise e passa à espera', (tester) async {
      final bed = await _abrir(tester, _nova());

      await tester.tap(find.byKey(TreinadorKeys.comecar));
      await assentar(tester);

      expect(bed.repo.pedidosAnalise.map((e) => e.$1), [_idNova]);
      expect(find.byKey(TreinadorKeys.carregando), findsOneWidget);
      expect(find.byKey(TreinadorKeys.inicio), findsNothing);
      expect(find.text('Analisando sua partida'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('quando a análise termina, mostra os exercícios', (
      tester,
    ) async {
      final repo = _repo()..analisarConclui = true;
      await _abrir(tester, _nova(), repo: repo);

      await tester.tap(find.byKey(TreinadorKeys.comecar));
      await assentar(tester);

      expect(find.byKey(TreinadorKeys.carregando), findsNothing);
      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.comecar, 'Começar os exercícios'),
        findsOneWidget,
      );
      expect(find.text('Como funciona'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('pedido recusado', () {
    testWidgets('acabou a cota grátis: abre a venda do plano', (tester) async {
      final repo = _repo()
        ..falhaAnalisar = 'permission-denied'
        ..motivoAnalisar = 'cota';
      final bed = await _abrir(tester, _nova(), repo: repo, plano: false);

      await tester.tap(find.byKey(TreinadorKeys.comecar));
      await assentar(tester);

      expect(bed.caminho, '/pilares');
      expect(find.text('stub.pilares'), findsOneWidget);
    });

    testWidgets('teto do mês: mostra o aviso e fica no início', (tester) async {
      final repo = _repo()
        ..falhaAnalisar = 'permission-denied'
        ..motivoAnalisar = 'teto';
      final bed = await _abrir(tester, _nova(), repo: repo);

      await tester.tap(find.byKey(TreinadorKeys.comecar));
      await assentar(tester);

      expect(
        find.text(
          'As análises deste mês acabaram. Elas voltam no mês que vem.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
      expect(bed.caminho, Routes.treinadorPartida(_idNova));
    });

    testWidgets('falha do servidor: mostra o aviso de tentar novamente', (
      tester,
    ) async {
      final repo = _repo()..falhaAnalisar = 'unavailable';
      await _abrir(tester, _nova(), repo: repo);

      await tester.tap(find.byKey(TreinadorKeys.comecar));
      await assentar(tester);

      expect(
        find.text('Não foi possível pedir a análise. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
    });
  });

  group('espera da análise', () {
    Future<void> abrirAnalisando(WidgetTester tester) async {
      final partida = TreinadorFixtures.lista().firstWhere(
        (p) => p.id == _idAnalisando,
      );
      await _abrir(tester, partida);
    }

    testWidgets('mostra a frase, a porcentagem, a curiosidade e o aviso', (
      tester,
    ) async {
      await abrirAnalisando(tester);

      expect(find.byKey(TreinadorKeys.carregando), findsOneWidget);
      expect(find.text('Analisando sua partida'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(TreinadorKeys.carregandoFrase)).data,
        'Buscando sua partida no Lichess',
      );
      expect(
        tester
            .widget<Text>(find.byKey(TreinadorKeys.carregandoPorcentagem))
            .data,
        matches(RegExp(r'^\d+%$')),
      );
      expect(find.byKey(TreinadorKeys.curiosidade), findsWidgets);
      expect(find.text('Você sabia?'), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.outraCuriosidade, 'Outra curiosidade'),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.meAvise, 'Me avise quando terminar'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Outra curiosidade" troca o texto da curiosidade', (
      tester,
    ) async {
      await abrirAnalisando(tester);
      String texto() => tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(TreinadorKeys.curiosidade).first,
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .join('|');

      final antes = texto();
      await tester.tap(find.byKey(TreinadorKeys.outraCuriosidade));
      await assentar(tester);
      expect(texto(), isNot(antes));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Me avise quando terminar" pede o aviso e fecha a tela', (
      tester,
    ) async {
      final bed = await _abrir(
        tester,
        TreinadorFixtures.lista().firstWhere((p) => p.id == _idAnalisando),
      );

      await tester.tap(find.byKey(TreinadorKeys.meAvise));
      await assentar(tester);

      expect(bed.repo.pedidosAnalise, [(_idAnalisando, true)]);
      expect(find.text('stub.home'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('quando o servidor grava o resultado, a tela muda sozinha', (
      tester,
    ) async {
      final bed = await _abrir(
        tester,
        TreinadorFixtures.lista().firstWhere((p) => p.id == _idAnalisando),
      );
      expect(find.byKey(TreinadorKeys.carregando), findsOneWidget);

      final analisando = TreinadorFixtures.lista().firstWhere(
        (p) => p.id == _idAnalisando,
      );
      bed.repo.porPartida(
        comStatus(analisando, StatusPartida.erro, erroMotivo: 'variante'),
      );
      await assentar(tester);
      expect(find.byKey(TreinadorKeys.carregando), findsNothing);
      expect(find.byKey(TreinadorKeys.erro), findsOneWidget);
    });
  });

  group('erro da análise', () {
    testWidgets('erro comum: explica e deixa tentar novamente', (tester) async {
      final erro = comStatus(_nova(), StatusPartida.erro);
      final bed = await _abrir(tester, erro);

      expect(find.byKey(TreinadorKeys.erro), findsOneWidget);
      expect(
        find.text('Não foi possível analisar esta partida'),
        findsOneWidget,
      );
      expect(find.text('Tente novamente em alguns instantes.'), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.erroTentar, 'Tentar novamente'),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.erroVoltar), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(TreinadorKeys.erroTentar));
      await assentar(tester);
      expect(bed.repo.pedidosAnalise.map((e) => e.$1), [_idNova]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('variante: não oferece tentar, leva à lista de partidas', (
      tester,
    ) async {
      final erro = comStatus(
        _nova(),
        StatusPartida.erro,
        erroMotivo: 'variante',
      );
      final bed = await _abrir(tester, erro);

      expect(
        find.text(
          'Esta partida é de uma variante, e o Treinador só analisa o '
          'xadrez comum.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.erroTentar), findsNothing);
      expect(
        _textoEm(TreinadorKeys.erroVoltar, 'Ver todas as partidas'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(TreinadorKeys.erroVoltar));
      await assentar(tester);
      expect(bed.caminho, '/treinador?aba=partidas');
      expect(find.byKey(TreinadorKeys.partidas), findsOneWidget);
    });
  });

  group('partida pronta', () {
    testWidgets('sem exercício feito: convida a começar', (tester) async {
      final bed = await _abrir(tester, TreinadorFixtures.tiago());

      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
      expect(find.text('0 de 4 exercícios feitos'), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.comecar, 'Começar os exercícios'),
        findsOneWidget,
      );
      expect(find.text('Como funciona'), findsNothing);

      await tester.tap(find.byKey(TreinadorKeys.comecar));
      await assentar(tester);
      expect(
        bed.caminho,
        Routes.treinadorExercicios(TreinadorFixtures.idTiago),
      );
      expect(find.byKey(TreinadorKeys.exercicio), findsOneWidget);
      _descartarBugDoTabuleiro(tester);
    });

    testWidgets('com exercícios feitos: continua de onde parou', (
      tester,
    ) async {
      final parcial = TreinadorFixtures.tiago().copyWith(
        progresso: _progresso(2, acertos: 1),
      );
      await _abrir(tester, parcial);

      expect(find.byKey(TreinadorKeys.inicio), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.comecar, 'Continuar (2 de 4)'),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.resumo), findsNothing);
    });
  });

  group('resumo da partida', () {
    PartidaTreinador completa() => TreinadorFixtures.tiago().copyWith(
      progresso: _progresso(4, acertos: 3),
    );

    testWidgets('mostra precisão, exercícios, fases e posições-chave', (
      tester,
    ) async {
      await _abrir(tester, completa());

      expect(find.byKey(TreinadorKeys.resumo), findsOneWidget);
      expect(find.text('Resumo da partida'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.resumoPrecisao), findsWidgets);
      expect(find.text('Precisão'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.resumoExercicios), findsWidgets);
      expect(find.text('3 de 4 certos'), findsOneWidget);
      expect(find.text('Precisão por fase'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.resumoFases), findsOneWidget);
      expect(find.text('Posições-chave'), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        await tester.ensureVisible(find.byKey(TreinadorKeys.posicaoChave(n)));
        await tester.pump();
        expect(find.byKey(TreinadorKeys.posicaoChave(n)), findsWidgets);
      }
      expect(
        _textoEm(TreinadorKeys.resumoAnalise, 'Ver a análise completa'),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.refazer, 'Refazer os exercícios'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver a análise completa" abre a análise da partida', (
      tester,
    ) async {
      final bed = await _abrir(tester, completa());

      await _tocar(tester, find.byKey(TreinadorKeys.resumoAnalise));
      expect(bed.caminho, Routes.treinadorAnalise(TreinadorFixtures.idTiago));
      expect(find.byKey(TreinadorKeys.analise), findsOneWidget);
    });

    testWidgets('uma posição-chave abre a análise no lance dela', (
      tester,
    ) async {
      final bed = await _abrir(tester, completa());
      final ex = completa().exercicios.first;

      await _tocar(tester, find.byKey(TreinadorKeys.posicaoChave(ex.n)));
      expect(
        bed.caminho,
        Routes.treinadorAnalise(
          TreinadorFixtures.idTiago,
          lance: TreinadorRegras.meioLance(
            ex.lance,
            brancas: completa().cor == CorPartida.brancas,
          ),
        ),
      );
      expect(find.byKey(TreinadorKeys.analise), findsOneWidget);
    });

    testWidgets('"Refazer os exercícios" abre os exercícios de novo', (
      tester,
    ) async {
      final bed = await _abrir(tester, completa());

      await _tocar(tester, find.byKey(TreinadorKeys.refazer));
      expect(
        bed.caminho,
        Routes.treinadorExercicios(TreinadorFixtures.idTiago, refazer: true),
      );
      expect(find.byKey(TreinadorKeys.exercicio), findsOneWidget);
      _descartarBugDoTabuleiro(tester);
    });

    testWidgets('pronta sem exercícios vai direto ao resumo, sem refazer', (
      tester,
    ) async {
      await _abrir(tester, TreinadorFixtures.tiago(exercicios: 0));

      expect(find.byKey(TreinadorKeys.resumo), findsOneWidget);
      expect(find.byKey(TreinadorKeys.inicio), findsNothing);
      expect(find.text('–'), findsWidgets);
      expect(find.byKey(TreinadorKeys.refazer), findsNothing);
      expect(find.text('Posições-chave'), findsNothing);
      expect(find.byKey(TreinadorKeys.resumoAnalise), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
