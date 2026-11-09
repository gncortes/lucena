import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/treinador/seu_jogo_filtro_repository.dart';
import 'package:lucena/data/services/firebase/treinador_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/course_access.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/treinador_seu_jogo/view_models/curso_da_abertura_cubit.dart';
import 'package:lucena/ui/treinador_seu_jogo/view_models/partidas_modelo_cubit.dart';
import 'package:lucena/ui/treinador_seu_jogo/view_models/seu_jogo_cubit.dart';
import 'package:lucena/ui/treinador_seu_jogo/view_models/teoria_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_lesson_ad_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_treinador_repository.dart';
import '../../../../testing/treinador_fixtures.dart';
import '../../../../testing/treinador_seu_jogo_fixtures.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  group('SeuJogoCubit', () {
    SeuJogoCubit cubit(FakeTreinadorRepository repo) => SeuJogoCubit(
      repository: repo,
      filtro: SeuJogoFiltroRepository(PreferencesService()),
      now: FakeNow(SeuJogoFixtures.agora),
    );

    FakeTreinadorRepository repo() => FakeTreinadorRepository(
      conta: TreinadorFixtures.conta,
      partidas: SeuJogoFixtures.partidas(),
      estatisticas: SeuJogoFixtures.estatisticas(),
    );

    test('carrega o resumo das partidas e a plataforma da conta', () async {
      final c = cubit(repo());
      await c.load();
      await pumpEventQueue();
      expect(c.state.status, SeuJogoStatus.pronto);
      expect(c.state.resumo?.partidas, 60);
      expect(c.state.plataforma, Plataforma.lichess);
      await c.close();
    });

    test('o ritmo escolhido refaz o resumo e volta depois de fechar', () async {
      final c = cubit(repo());
      await c.load();
      await pumpEventQueue();
      await c.escolherRitmo(Ritmo.blitz);
      expect(c.state.resumo?.partidas, 20);
      await c.close();

      final reaberto = cubit(repo());
      await reaberto.load();
      await pumpEventQueue();
      expect(reaberto.state.ritmo, Ritmo.blitz);
      expect(reaberto.state.resumo?.partidas, 20);
      await reaberto.escolherRitmo(null);
      expect(reaberto.state.resumo?.partidas, 60);
      await reaberto.close();
    });

    test('servidor fora: erro; tentar de novo carrega uma vez só', () async {
      final r = _ComFalha(
        conta: TreinadorFixtures.conta,
        partidas: SeuJogoFixtures.partidas(),
        estatisticas: SeuJogoFixtures.estatisticas(),
      );
      final c = cubit(r);
      await c.load();
      await pumpEventQueue();
      expect(c.state.status, SeuJogoStatus.erro);

      r.falhar = false;
      final estados = <SeuJogoStatus>[];
      final sub = c.stream.listen((s) => estados.add(s.status));
      await c.load();
      await pumpEventQueue();
      expect(estados.first, SeuJogoStatus.carregando);
      expect(c.state.status, SeuJogoStatus.pronto);
      expect(c.state.resumo?.partidas, 60);
      await sub.cancel();
      await c.close();
    });

    test('partida com status erro fica fora do resumo', () async {
      final c = cubit(
        FakeTreinadorRepository(
          conta: TreinadorFixtures.conta,
          partidas: [
            ...SeuJogoFixtures.partidas(12),
            TreinadorFixtures.tiago(status: 'erro'),
          ],
          estatisticas: SeuJogoFixtures.estatisticas(),
        ),
      );
      await c.load();
      await pumpEventQueue();
      expect(c.state.resumo?.partidas, 12);
      await c.close();
    });

    test('partida nova do servidor entra no resumo', () async {
      final r = repo();
      final c = cubit(r);
      await c.load();
      await pumpEventQueue();
      r.partidasAtuais = SeuJogoFixtures.partidas(9);
      await pumpEventQueue();
      expect(c.state.resumo?.poucas, isTrue);
      await c.close();
    });
  });

  group('TeoriaCubit', () {
    test('tocar escolhe a linha; tocar de novo solta', () async {
      final partida = SeuJogoFixtures.partidas(2)[1];
      final c = TeoriaCubit(
        repository: FakeTreinadorRepository(partidas: [partida]),
        partidaId: partida.id,
      )..load();
      await pumpEventQueue();
      expect(c.state.status, TeoriaStatus.pronta);
      expect(c.state.jogado, 'c5');
      expect(c.state.escolhido, isNull);
      // Sem toque: o tabuleiro depois do c5 dele, com o c5 em destaque e
      // marcado na lista.
      expect(c.state.tabuleiro.fen, partida.lances[9].fen);
      expect(c.state.tabuleiro.lance, Move.parse('c6c5'));
      expect(c.state.marcadoNaPartida, 9);
      expect(c.state.marcadoNaLinha, isNull);

      c.escolher('Nd7');
      expect(c.state.linha, ['Nd7', 'O-O', 'Ne7']);
      expect(c.state.tabuleiro.lance, Move.parse('g8e7'));
      expect(c.state.marcadoNaPartida, isNull);
      expect(c.state.marcadoNaLinha, 2);

      // Passo 0: a posição da saída, com 5.Be2 marcado e em destaque.
      c.irPara(0);
      expect(c.state.tabuleiro.fen, SeuJogoFixtures.fenTeoria);
      expect(c.state.tabuleiro.lance, Move.parse('f1e2'));
      expect(c.state.marcadoNaPartida, 8);
      expect(c.state.marcadoNaLinha, isNull);
      c.proximo();
      expect(c.state.tabuleiro.lance, Move.parse('b8d7'));
      expect(c.state.marcadoNaLinha, 0);

      c.escolher('Nd7');
      expect(c.state.escolhido, isNull);
      await c.close();
    });

    test('lista e tabuleiro só com os lances legais da linha', () async {
      final json = SeuJogoFixtures.partidaJson(1);
      final teoria = {...json['teoria']! as Map<String, Object?>};
      teoria['candidatos'] = [
        {
          'san': 'Nd7',
          'partidas': 1,
          'brancas': 1,
          'empates': 0,
          'pretas': 0,
          'linha': ['Nd7', 'O-O', 'Qxh8'],
        },
      ];
      final partida = PartidaTreinador.fromJson(SeuJogoFixtures.id(1), {
        ...json,
        'teoria': teoria,
      })!;
      final c = TeoriaCubit(
        repository: FakeTreinadorRepository(partidas: [partida]),
        partidaId: partida.id,
      )..load();
      await pumpEventQueue();
      c.escolher('Nd7');
      expect(c.state.linha, ['Nd7', 'O-O']);
      expect(c.state.marcadoNaLinha, 1);
      await c.close();
    });

    test('partida sem teoria', () async {
      final partida = SeuJogoFixtures.partidas(3)[2];
      final c = TeoriaCubit(
        repository: FakeTreinadorRepository(partidas: [partida]),
        partidaId: partida.id,
      )..load();
      await pumpEventQueue();
      expect(c.state.status, TeoriaStatus.semTeoria);
      await c.close();
    });
  });

  group('PartidasModeloCubit', () {
    test('sem internet: erro; tentar de novo lista', () async {
      final repo = _ComFalha(conta: TreinadorFixtures.conta);
      final c = PartidasModeloCubit(repository: repo, eco: 'B12');
      await c.load();
      expect(c.state.status, PartidasModeloStatus.erro);
      repo.falhar = false;
      await c.load();
      expect(c.state.status, PartidasModeloStatus.pronto);
      await c.close();
    });

    test('lista as partidas do ECO e grava o aviso', () async {
      final repo = FakeTreinadorRepository(
        conta: TreinadorFixtures.conta,
        modelosPorEco: {
          'B12': [
            const PartidaModelo(fonte: 'torneio', titulo: 'Carlsen x Caruana'),
          ],
        },
      );
      final c = PartidasModeloCubit(repository: repo, eco: 'B12');
      await c.load();
      await pumpEventQueue();
      expect(c.state.status, PartidasModeloStatus.pronto);
      expect(c.state.modelos.single.titulo, 'Carlsen x Caruana');
      expect(c.state.aviso, isFalse);

      await c.definirAviso(ligado: true);
      await pumpEventQueue();
      expect(repo.avisosModelos, [true]);
      expect(c.state.aviso, isTrue);
      await c.close();
    });
  });

  group('CursoDaAberturaCubit', () {
    final resources = TrainingResources(
      lessons: [
        for (final id in ['pilares.ab1.caroKann1', 'pilares.ab2.caroKann2'])
          TrainingLesson(id: id, kind: TrainingLessonKind.opening, title: id),
      ],
    );

    Future<CursoDaAberturaState> carregar(CourseAccess acesso) async {
      final c = CursoDaAberturaCubit(
        training: FakeTrainingRepository(
          content: {TrainingCourse.pilares: resources},
        ),
        access: FakeCourseAccessRepository(acesso),
        slot: 'caroKann',
        parte: 2,
      );
      await c.load();
      final s = c.state;
      await c.close();
      return s;
    }

    test('sem o curso: as partes e a do servidor em destaque', () async {
      final s = await carregar(CourseAccess.demo);
      expect(s.carregando, isFalse);
      expect(s.temOCurso, isFalse);
      expect(s.abertura?.destaque.numero, 2);
    });

    test('comprar e terminar a parte já mudam a tela, sem reabrir', () async {
      final acesso = FakeCourseAccessRepository();
      final training = FakeTrainingRepository(
        content: {TrainingCourse.pilares: resources},
      );
      final c = CursoDaAberturaCubit(
        training: training,
        access: acesso,
        slot: 'caroKann',
      );
      await c.load();
      expect(c.state.temOCurso, isFalse);

      acesso.access = CourseAccess.owned;
      await pumpEventQueue();
      expect(c.state.temOCurso, isTrue);
      expect(c.state.abertura?.destaque.numero, 1);

      await training.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(
          completedLessons: const {'pilares.ab1.caroKann1': '2026-11-09'},
        ),
      );
      await pumpEventQueue();
      expect(c.state.abertura?.destaque.numero, 2);
      await c.close();
    });

    test('com o curso: temOCurso', () async {
      final s = await carregar(CourseAccess.owned);
      expect(s.temOCurso, isTrue);
      expect(s.abertura?.partes, hasLength(2));
    });
  });
}

/// O servidor fora do ar: a lista e as partidas-modelo falham enquanto
/// [falhar] for verdadeiro.
class _ComFalha extends FakeTreinadorRepository {
  _ComFalha({super.conta, super.partidas, super.estatisticas});

  var falhar = true;

  @override
  Stream<List<PartidaTreinador>> partidas() => falhar
      ? Stream.error(const TreinadorCallException('unavailable'))
      : super.partidas();

  @override
  Future<List<PartidaModelo>> modelos(String eco) async {
    if (falhar) throw const TreinadorCallException('unavailable');
    return super.modelos(eco);
  }
}
