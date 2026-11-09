import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/coach/trivia_repository.dart';
import 'package:lucena/domain/models/coach/trivia.dart';
import 'package:lucena/ui/coach/view_models/trivia_cubit.dart';

import '../../../testing/fakes/fake_trivia_repository.dart';
import '../../../testing/fakes/fake_now.dart';

/// Um repositório sem curiosidades.
class _Empty implements TriviaRepository {
  @override
  Future<List<Trivia>> all() async => const [];
}

/// Um repositório que falha ao ler.
class _Break implements TriviaRepository {
  @override
  Future<List<Trivia>> all() => Future.error(StateError('sem asset'));
}

void main() {
  final currentTime = DateTime.utc(2026, 11, 9, 12);

  TriviaCubit create({TriviaRepository? repo, DateTime? when_}) {
    final c = TriviaCubit(
      repository: repo ?? FakeTriviaRepository(),
      now: FakeNow(when_ ?? currentTime),
    );
    addTearDown(c.close);
    return c;
  }

  test('começa sem curiosidade', () {
    final c = create();
    expect(c.state.current, isNull);
    expect(c.state.all, isEmpty);
  });

  group('load', () {
    test('carrega todas e mostra uma delas', () async {
      final c = create();
      await c.load();
      expect(c.state.all, hasLength(3));
      expect(c.state.current, isNotNull);
      expect(c.state.index, inInclusiveRange(0, 2));
    });

    test('o mesmo instante dá sempre a mesma curiosidade', () async {
      final a = create();
      final b = create();
      await a.load();
      await b.load();
      expect(a.state.current?.id, b.state.current?.id);
    });

    test('repositório vazio: segue sem curiosidade', () async {
      final c = create(repo: _Empty());
      await c.load();
      expect(c.state.current, isNull);
    });

    test('falha ao ler: não quebra, segue sem curiosidade', () async {
      final c = create(repo: _Break());
      await expectLater(c.load(), completes);
      expect(c.state.current, isNull);
    });

    test('fechar durante a carga não emite depois', () async {
      final c = create();
      final payload = c.load();
      await c.close();
      await payload;
      expect(c.isClosed, isTrue);
    });

    // BUG (curiosidades_cubit.dart, load): a doc diz "diferente a cada dia",
    // mas a conta usa minutos desde a época; a curiosidade inicial muda a
    // cada minuto.
    test('dentro do mesmo dia a curiosidade inicial é a mesma', () async {
      final early = create(when_: DateTime.utc(2026, 11, 9, 12, 0));
      final late = create(when_: DateTime.utc(2026, 11, 9, 12, 1));
      await early.load();
      await late.load();
      expect(early.state.index, late.state.index);
    });
  });

  group('outra curiosidade', () {
    test('passa para a seguinte e dá a volta no fim', () async {
      final c = create();
      await c.load();
      final start = c.state.index;
      final vistas = <String>[c.state.current!.id];
      for (var i = 0; i < 3; i++) {
        c.another();
        vistas.add(c.state.current!.id);
      }
      expect(vistas.toSet(), hasLength(3));
      expect(vistas.first, vistas.last);
      expect(c.state.index, start + 3);
    });

    test('com uma só curiosidade não muda nada', () async {
      final c = create(
        repo: FakeTriviaRepository(const [
          Trivia(id: 'a', motif: 't', text: 'um'),
        ]),
      );
      await c.load();
      final before = c.state;
      c.another();
      expect(c.state.index, before.index);
      expect(c.state.current?.id, 'a');
    });

    test('sem curiosidades não faz nada', () {
      final c = create();
      c.another();
      expect(c.state.current, isNull);
    });
  });
}
