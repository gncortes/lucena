import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/treinador/treinador_regras.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/treinador_keys.dart';
import 'package:lucena/ui/core/widgets/animated_progress.dart';
import 'package:lucena/ui/core/widgets/busy_button.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/core/widgets/load_skeleton.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../testing/fakes/fake_curiosidades_repository.dart';
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

/// O pedido de análise só responde quando o teste deixa.
class _RepoAnalisarLento extends FakeTreinadorRepository {
  _RepoAnalisarLento(List<PartidaTreinador> partidas)
    : super(conta: TreinadorFixtures.conta, partidas: partidas);

  final liberar = Completer<void>();

  @override
  Future<void> analisar(String id, {bool avisar = true}) async {
    await liberar.future;
    await super.analisar(id, avisar: avisar);
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

/// O cartão "Como funciona" do canvas: os três itens, com [n] exercícios.
void _confereComoFunciona(int n) {
  expect(find.byKey(TreinadorKeys.comoFunciona), findsWidgets);
  expect(find.text('Como funciona'), findsOneWidget);
  expect(find.text('$n exercícios'), findsOneWidget);
  expect(find.text('Posições-chave que decidiram a partida.'), findsOneWidget);
  expect(find.text('Pense antes de jogar'), findsOneWidget);
  expect(find.text('Depois, a partida inteira'), findsOneWidget);
  expect(find.byIcon(Icons.extension_outlined), findsOneWidget);
  expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
}

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
      expect(find.text('Análise da partida'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.cartaoPartida), findsWidgets);
      expect(find.text('Pronta para analisar'), findsOneWidget);
      _confereComoFunciona(4);
      expect(
        _textoEm(TreinadorKeys.comecar, 'Começar a análise'),
        findsOneWidget,
      );
      expect(
        _textoEm(TreinadorKeys.verPartidas, 'Ver minhas partidas'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Ver minhas partidas" abre a aba Partidas', (tester) async {
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
      expect(find.text('Análise da partida'), findsOneWidget);
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
      expect(find.byKey(TreinadorKeys.comoFunciona), findsWidgets);
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
      expect(find.text('Análise da partida'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(TreinadorKeys.carregandoFrase)).data,
        'Preparando seus exercícios',
      );
      expect(
        tester
            .widget<Text>(find.byKey(TreinadorKeys.carregandoPorcentagem))
            .data,
        matches(RegExp(r'^\d+%$')),
      );
      expect(find.byKey(TreinadorKeys.curiosidade), findsOneWidget);
      expect(find.text('Você sabia?'), findsOneWidget);
      expect(
        find.text(
          'Estamos olhando sua partida lance a lance. Pode levar alguns '
          'minutos.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Pode sair do app: avisamos quando os exercícios estiverem prontos.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(TreinadorKeys.carregandoBarra), findsOneWidget);
      expect(find.byType(AnimatedProgress), findsOneWidget);
      expect(
        _textoEm(TreinadorKeys.outraCuriosidade, 'Outra curiosidade'),
        findsOneWidget,
      );
      expect(
        tester.widget(find.byKey(TreinadorKeys.outraCuriosidade)),
        isA<OutlinedButton>(),
      );
      expect(
        tester.widget(find.byKey(TreinadorKeys.meAvise)),
        isA<OutlinedButton>(),
      );
      expect(
        _textoEm(TreinadorKeys.meAvise, 'Me avise quando terminar'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('as frases se revezam e "Quase lá" só vem perto do fim', (
      tester,
    ) async {
      final partida = TreinadorFixtures.lista().firstWhere(
        (p) => p.id == _idAnalisando,
      );
      final bed = await _abrir(tester, partida);
      String frase() =>
          tester.widget<Text>(find.byKey(TreinadorKeys.carregandoFrase)).data!;
      final vistas = <String>{frase()};
      for (var i = 0; i < 3; i++) {
        bed.now.advance(const Duration(seconds: 4));
        for (var s = 0; s < 4; s++) {
          await tester.pump(const Duration(seconds: 1));
        }
        vistas.add(frase());
      }
      expect(vistas, {
        'Preparando seus exercícios',
        'Separando os lances que mais ensinam',
        'Montando seu treino',
      });

      // Perto do fim (80% ou mais), "Quase lá" entra no revezamento.
      bed.now.advance(const Duration(seconds: 160));
      for (var i = 0; i < 4; i++) {
        bed.now.advance(const Duration(seconds: 4));
        for (var s = 0; s < 4; s++) {
          await tester.pump(const Duration(seconds: 1));
        }
        vistas.add(frase());
      }
      expect(vistas, contains('Quase lá'));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Outra curiosidade" troca o texto da curiosidade', (
      tester,
    ) async {
      await abrirAnalisando(tester);
      String texto() =>
          tester.widget<TeacherSpeech>(find.byType(TeacherSpeech)).text!;

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
          'Esta partida é de uma variante, e a análise só vale para o '
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
      // O cartão traz a frase do resumo (DInicio), sem seta.
      expect(find.text('0 de 4 exercícios feitos'), findsNothing);
      expect(
        _textoEm(
          TreinadorKeys.cartaoPartida,
          'Você perdeu no lance 51, num final de torres que empatava.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(TreinadorKeys.cartaoPartida),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );
      expect(
        _textoEm(TreinadorKeys.comecar, 'Começar os exercícios'),
        findsOneWidget,
      );
      _confereComoFunciona(4);

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
      expect(find.text('Contra Tiago_Rook'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.resumoCartaoPartida), findsWidgets);
      expect(find.byKey(TreinadorKeys.resumoPrecisao), findsWidgets);
      expect(find.text('Sua precisão'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.resumoExercicios), findsWidgets);
      expect(find.text('3 de 4'), findsOneWidget);
      expect(find.text('certos na análise'), findsOneWidget);
      expect(find.text('Precisão por fase'), findsOneWidget);
      expect(find.byKey(TreinadorKeys.resumoFases), findsWidgets);
      expect(find.text('Posições-chave'), findsOneWidget);
      await tester.ensureVisible(find.byKey(TreinadorKeys.posicaoChave(4)));
      await tester.pump();
      expect(find.text('Lance 8 · Sacrificio h7'), findsOneWidget);
      expect(find.text('Lance 8 · Profilaxia'), findsOneWidget);
      expect(find.text('Recurso do adversário'), findsOneWidget);
      expect(find.text('Impedir a ameaça'), findsOneWidget);
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

  group('espera: o Viktor e o pé fixo', () {
    PartidaTreinador analisando() =>
        TreinadorFixtures.lista().firstWhere((p) => p.id == _idAnalisando);

    testWidgets('a curiosidade é dita pelo Viktor, com os pontos', (
      tester,
    ) async {
      await _abrir(tester, analisando());

      final fala = tester.widget<TeacherSpeech>(find.byType(TeacherSpeech));
      expect(fala.speechContext, SpeechContext.teaching);
      expect(fala.teacher.id, 'master');
      expect(fala.text, contains('primeiro campeão do mundo'));
      expect(find.byKey(TreinadorKeys.curiosidadePontos), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TreinadorKeys.curiosidadePontos),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(FakeCuriosidadesRepository.padrao.length),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('frase à esquerda e % à direita, barra animada embaixo', (
      tester,
    ) async {
      await _abrir(tester, analisando());

      final frase = tester.getRect(find.byKey(TreinadorKeys.carregandoFrase));
      final pct = tester.getRect(
        find.byKey(TreinadorKeys.carregandoPorcentagem),
      );
      final barra = tester.getRect(find.byKey(TreinadorKeys.carregandoBarra));
      expect(frase.left, lessThan(pct.left));
      expect((frase.center.dy - pct.center.dy).abs(), lessThan(8));
      expect(barra.top, greaterThan(frase.bottom));
      expect(barra.height, AnimatedProgress.height);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Me avise" e a nota ficam presos no pé, 48 dp ou mais', (
      tester,
    ) async {
      await _abrir(tester, analisando());

      final tela = tester.getRect(find.byKey(TreinadorKeys.screen));
      final botao = tester.getRect(find.byKey(TreinadorKeys.meAvise));
      final nota = tester.getRect(find.byKey(TreinadorKeys.carregandoNota));
      expect(botao.bottom, closeTo(tela.bottom - 16, 1));
      expect(botao.height, greaterThanOrEqualTo(48));
      expect(botao.width, closeTo(tela.width - 32, 1));
      expect(nota.bottom, lessThan(botao.top));
      expect(
        tester.getSize(find.byKey(TreinadorKeys.outraCuriosidade)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('na fila do grátis', () {
    PartidaTreinador naFila() => comStatus(_nova(), StatusPartida.naFila);

    testWidgets('frase da fila, barra sem número e "Me avise"', (tester) async {
      await _abrir(tester, naFila());

      expect(find.byKey(TreinadorKeys.carregando), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(TreinadorKeys.carregandoFrase)).data,
        'Sua partida está na fila',
      );
      expect(find.byKey(TreinadorKeys.carregandoPorcentagem), findsNothing);
      expect(find.text('Preparando seus exercícios'), findsNothing);
      expect(find.byKey(TreinadorKeys.carregandoFila), findsOneWidget);
      expect(find.byKey(TreinadorKeys.carregandoSubtitulo), findsNothing);
      expect(
        tester
            .widget<AnimatedProgress>(find.byKey(TreinadorKeys.carregandoBarra))
            .value,
        isNull,
      );
      expect(
        _textoEm(TreinadorKeys.meAvise, 'Me avise quando terminar'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a fila não marca o início; ao virar analisando, marca', (
      tester,
    ) async {
      final bed = await _abrir(tester, naFila());
      expect(await bed.preferencias.inicioDaAnalise(_idNova), isNull);

      bed.repo.porPartida(comStatus(_nova(), StatusPartida.analisando));
      await assentar(tester);
      expect(
        tester
            .widget<AnimatedProgress>(find.byKey(TreinadorKeys.carregandoBarra))
            .value,
        isNotNull,
      );
      expect(find.byKey(TreinadorKeys.carregandoPorcentagem), findsOneWidget);
      expect(find.byKey(TreinadorKeys.carregandoFila), findsNothing);
      expect(await bed.preferencias.inicioDaAnalise(_idNova), isNotNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('início: pé fixo e cartão', () {
    testWidgets('os botões ficam presos no pé, nos dois estados', (
      tester,
    ) async {
      for (final partida in [_nova(), TreinadorFixtures.tiago()]) {
        await _abrir(tester, partida);
        final tela = tester.getRect(find.byKey(TreinadorKeys.screen));
        final primario = tester.getRect(find.byKey(TreinadorKeys.comecar));
        final texto = tester.getRect(find.byKey(TreinadorKeys.verPartidas));
        final cartao = tester.getRect(
          find.byKey(TreinadorKeys.comoFunciona).first,
        );
        expect(texto.bottom, closeTo(tela.bottom - 16, 1));
        expect(primario.bottom, lessThan(texto.top));
        expect(texto.top - primario.bottom, closeTo(12, 1));
        expect(cartao.bottom, lessThan(primario.top));
        expect(primario.height, greaterThanOrEqualTo(48));
        expect(texto.height, greaterThanOrEqualTo(48));
        expect(
          tester.widget(find.byKey(TreinadorKeys.verPartidas)),
          isA<OutlinedButton>(),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('o número de exercícios vem da config', (tester) async {
      final repo = _repo()
        ..configAtual = const TreinadorConfig(exerciciosPorPartida: 6);
      await _abrir(tester, _nova(), repo: repo);
      expect(find.text('6 exercícios'), findsOneWidget);
    });
  });

  group('erro: tentar de novo', () {
    testWidgets('o botão mostra o envio enquanto o pedido não responde', (
      tester,
    ) async {
      final erro = comStatus(_nova(), StatusPartida.erro);
      final repo = _RepoAnalisarLento([erro]);
      await _abrir(tester, erro, repo: repo);

      await tester.tap(find.byKey(TreinadorKeys.erroTentar));
      await tester.pump();
      expect(find.byType(BusyButton), findsOneWidget);
      expect(tester.widget<BusyButton>(find.byType(BusyButton)).busy, isTrue);
      repo.liberar.complete();
      await assentar(tester);
      expect(repo.pedidosAnalise, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('resumo: cartões e estados', () {
    PartidaTreinador completa({String? adversario}) {
      final base = TreinadorFixtures.tiagoJson();
      final json = adversario == null
          ? base
          : {
              ...base,
              'adversario': {'nome': adversario, 'rating': 1500},
            };
      return PartidaTreinador.fromJson(
        TreinadorFixtures.idTiago,
        json,
      )!.copyWith(progresso: _progresso(4, acertos: 3));
    }

    testWidgets('título com nome longo quebra a linha, sem reticências', (
      tester,
    ) async {
      const nome = 'Fulano_De_Tal_Com_Nome_Bem_Longo_2026';
      await _abrir(tester, completa(adversario: nome));

      final titulo = find.text('Contra $nome');
      expect(titulo, findsOneWidget);
      final text = tester.widget<Text>(titulo);
      expect(text.overflow, TextOverflow.visible);
      expect(text.maxLines, 2);
      expect(tester.getRect(titulo).height, greaterThan(24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('cartão da partida no topo, depois os números e as fases', (
      tester,
    ) async {
      await _abrir(tester, completa());

      final topo = tester.getRect(
        find.byKey(TreinadorKeys.resumoCartaoPartida).first,
      );
      final precisao = tester.getRect(
        find.byKey(TreinadorKeys.resumoPrecisao).first,
      );
      final fases = tester.getRect(find.byKey(TreinadorKeys.resumoFases).first);
      expect(topo.bottom, lessThan(precisao.top));
      expect(precisao.bottom, lessThan(fases.top));
      expect(
        find.descendant(
          of: find.byKey(TreinadorKeys.resumoFases),
          matching: find.byType(AnimatedProgress),
        ),
        findsNWidgets(3),
      );
      expect(find.text('62%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '"Refazer" é o primário e "Ver a análise" o contornado, no pé',
      (tester) async {
        await _abrir(tester, completa());

        final tela = tester.getRect(find.byKey(TreinadorKeys.screen));
        final refazer = tester.getRect(find.byKey(TreinadorKeys.refazer));
        final analise = tester.getRect(find.byKey(TreinadorKeys.resumoAnalise));
        expect(refazer.bottom, lessThan(analise.top));
        expect(analise.bottom, closeTo(tela.bottom - 16, 1));
        expect(
          tester.widget(find.byKey(TreinadorKeys.refazer)),
          isA<FilledButton>(),
        );
        expect(
          tester.widget(find.byKey(TreinadorKeys.resumoAnalise)),
          isA<OutlinedButton>(),
        );
      },
    );

    testWidgets('✓ e ✗ vêm dos resultados do aparelho', (tester) async {
      await _abrir(tester, completa());
      await tester.ensureVisible(find.byKey(TreinadorKeys.posicaoChave(4)));
      await tester.pump();

      Finder icone(int n, IconData i) => find.descendant(
        of: find.byKey(TreinadorKeys.posicaoChave(n)),
        matching: find.byIcon(i),
      );
      expect(icone(1, Icons.check_circle_outline), findsOneWidget);
      expect(icone(3, Icons.check_circle_outline), findsOneWidget);
      expect(icone(4, Icons.highlight_off), findsOneWidget);
    });

    testWidgets('sem resultados no aparelho, a posição fica neutra', (
      tester,
    ) async {
      final remoto = TreinadorFixtures.tiago().copyWith(
        progresso: const ProgressoPartida(feitosRemoto: 4, acertosRemoto: 3),
      );
      await _abrir(tester, remoto);

      expect(find.byKey(TreinadorKeys.resumo), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.highlight_off), findsNothing);
      await tester.ensureVisible(find.byKey(TreinadorKeys.posicaoChave(4)));
      await tester.pump();
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
      expect(find.text('3 de 4'), findsOneWidget);
    });
  });
}
