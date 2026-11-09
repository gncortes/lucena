import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/treinador/curiosidades_repository.dart';
import 'package:lucena/domain/models/treinador/curiosidade.dart';
import 'package:lucena/ui/treinador/view_models/curiosidades_cubit.dart';

import '../../../testing/fakes/fake_curiosidades_repository.dart';
import '../../../testing/fakes/fake_now.dart';

/// Um repositório sem curiosidades.
class _Vazio implements CuriosidadesRepository {
  @override
  Future<List<Curiosidade>> todas() async => const [];
}

/// Um repositório que falha ao ler.
class _Quebra implements CuriosidadesRepository {
  @override
  Future<List<Curiosidade>> todas() => Future.error(StateError('sem asset'));
}

void main() {
  final agora = DateTime.utc(2026, 11, 9, 12);

  CuriosidadesCubit criar({CuriosidadesRepository? repo, DateTime? quando}) {
    final c = CuriosidadesCubit(
      repository: repo ?? FakeCuriosidadesRepository(),
      now: FakeNow(quando ?? agora),
    );
    addTearDown(c.close);
    return c;
  }

  test('começa sem curiosidade', () {
    final c = criar();
    expect(c.state.atual, isNull);
    expect(c.state.todas, isEmpty);
  });

  group('load', () {
    test('carrega todas e mostra uma delas', () async {
      final c = criar();
      await c.load();
      expect(c.state.todas, hasLength(3));
      expect(c.state.atual, isNotNull);
      expect(c.state.indice, inInclusiveRange(0, 2));
    });

    test('o mesmo instante dá sempre a mesma curiosidade', () async {
      final a = criar();
      final b = criar();
      await a.load();
      await b.load();
      expect(a.state.atual?.id, b.state.atual?.id);
    });

    test('repositório vazio: segue sem curiosidade', () async {
      final c = criar(repo: _Vazio());
      await c.load();
      expect(c.state.atual, isNull);
    });

    test('falha ao ler: não quebra, segue sem curiosidade', () async {
      final c = criar(repo: _Quebra());
      await expectLater(c.load(), completes);
      expect(c.state.atual, isNull);
    });

    test('fechar durante a carga não emite depois', () async {
      final c = criar();
      final carga = c.load();
      await c.close();
      await carga;
      expect(c.isClosed, isTrue);
    });

    // BUG (curiosidades_cubit.dart, load): a doc diz "diferente a cada dia",
    // mas a conta usa minutos desde a época; a curiosidade inicial muda a
    // cada minuto.
    test('dentro do mesmo dia a curiosidade inicial é a mesma', () async {
      final cedo = criar(quando: DateTime.utc(2026, 11, 9, 12, 0));
      final tarde = criar(quando: DateTime.utc(2026, 11, 9, 12, 1));
      await cedo.load();
      await tarde.load();
      expect(cedo.state.indice, tarde.state.indice);
    });
  });

  group('outra curiosidade', () {
    test('passa para a seguinte e dá a volta no fim', () async {
      final c = criar();
      await c.load();
      final inicio = c.state.indice;
      final vistas = <String>[c.state.atual!.id];
      for (var i = 0; i < 3; i++) {
        c.outra();
        vistas.add(c.state.atual!.id);
      }
      expect(vistas.toSet(), hasLength(3));
      expect(vistas.first, vistas.last);
      expect(c.state.indice, inicio + 3);
    });

    test('com uma só curiosidade não muda nada', () async {
      final c = criar(
        repo: FakeCuriosidadesRepository(const [
          Curiosidade(id: 'a', tema: 't', texto: 'um'),
        ]),
      );
      await c.load();
      final antes = c.state;
      c.outra();
      expect(c.state.indice, antes.indice);
      expect(c.state.atual?.id, 'a');
    });

    test('sem curiosidades não faz nada', () {
      final c = criar();
      c.outra();
      expect(c.state.atual, isNull);
    });
  });
}
