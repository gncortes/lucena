import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/treinador/treinador_regras.dart';

import '../../../../testing/treinador_fixtures.dart';

void main() {
  final lista = TreinadorFixtures.lista();

  List<String> ids(FiltroPartidas f) => [
    for (final p in f.aplicar(lista)) p.id,
  ];

  group('FiltroPartidas.aplicar', () {
    test('sem filtro devolve todas, na mesma ordem', () {
      expect(FiltroPartidas.todos.vazio, isTrue);
      expect(FiltroPartidas.todos.aplicar(lista), lista);
    });

    test('por ritmo', () {
      expect(ids(const FiltroPartidas(ritmo: Ritmo.rapida)), [
        'lichess_DeF67890',
        'lichess_MnO11223',
      ]);
      expect(ids(const FiltroPartidas(ritmo: Ritmo.bullet)), [
        'lichess_JkL24680',
      ]);
    });

    test('por resultado', () {
      expect(ids(const FiltroPartidas(resultado: Resultado.empate)), [
        'lichess_GhI13579',
      ]);
      expect(ids(const FiltroPartidas(resultado: Resultado.vitoria)), [
        'lichess_DeF67890',
        'lichess_MnO11223',
      ]);
    });

    test('ritmo e resultado juntos (E, não OU)', () {
      const f = FiltroPartidas(
        ritmo: Ritmo.blitz,
        resultado: Resultado.derrota,
      );
      expect(ids(f), [TreinadorFixtures.idTiago]);
    });

    test('combinação sem partidas dá lista vazia', () {
      const f = FiltroPartidas(
        ritmo: Ritmo.bullet,
        resultado: Resultado.vitoria,
      );
      expect(f.aplicar(lista), isEmpty);
    });
  });

  group('FiltroPartidas.comRitmo / comResultado', () {
    test('mudam só o seu campo e deixam o outro', () {
      const base = FiltroPartidas(resultado: Resultado.vitoria);
      final f = base.comRitmo(Ritmo.blitz);
      expect(f.ritmo, Ritmo.blitz);
      expect(f.resultado, Resultado.vitoria);
      expect(f.comResultado(null).resultado, isNull);
      expect(f.comResultado(null).ritmo, Ritmo.blitz);
    });

    test('limpar os dois volta a vazio', () {
      final f = const FiltroPartidas(
        ritmo: Ritmo.blitz,
        resultado: Resultado.empate,
      ).comRitmo(null).comResultado(null);
      expect(f.vazio, isTrue);
      expect(f, FiltroPartidas.todos);
    });
  });

  group('FiltroPartidas json', () {
    test('ida e volta preserva o filtro', () {
      const f = FiltroPartidas(
        ritmo: Ritmo.rapida,
        resultado: Resultado.derrota,
      );
      expect(FiltroPartidas.fromJson(f.toJson()), f);
    });

    test('toJson usa os nomes de fio e nulo para "todos"', () {
      expect(const FiltroPartidas(ritmo: Ritmo.blitz).toJson(), {
        'ritmo': 'blitz',
        'resultado': null,
      });
    });

    test('fromJson de lixo ou valor desconhecido dá "todos"', () {
      expect(FiltroPartidas.fromJson(null), FiltroPartidas.todos);
      expect(FiltroPartidas.fromJson('x'), FiltroPartidas.todos);
      expect(
        FiltroPartidas.fromJson({'ritmo': 'xadrez960', 'resultado': 7}),
        FiltroPartidas.todos,
      );
    });
  });

  group('FiltroPartidas igualdade', () {
    test('mesmos campos: iguais e mesmo hashCode', () {
      const a = FiltroPartidas(ritmo: Ritmo.blitz);
      const b = FiltroPartidas(ritmo: Ritmo.blitz);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('campos diferentes: diferentes', () {
      expect(
        const FiltroPartidas(ritmo: Ritmo.blitz) ==
            const FiltroPartidas(ritmo: Ritmo.bullet),
        isFalse,
      );
    });
  });
}
