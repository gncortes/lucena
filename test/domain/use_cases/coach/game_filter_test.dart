import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/coach/coach_rules.dart';

import '../../../../testing/coach_fixtures.dart';

void main() {
  final list = CoachFixtures.list();

  List<String> ids(GameFilter f) => [for (final p in f.apply(list)) p.id];

  group('FiltroPartidas.aplicar', () {
    test('sem filtro devolve todas, na mesma ordem', () {
      expect(GameFilter.everyone.empty, isTrue);
      expect(GameFilter.everyone.apply(list), list);
    });

    test('por ritmo', () {
      expect(ids(const GameFilter(timeControl: TimeControl.rapid)), [
        'lichess_DeF67890',
        'lichess_MnO11223',
      ]);
      expect(ids(const GameFilter(timeControl: TimeControl.bullet)), [
        'lichess_JkL24680',
      ]);
    });

    test('por resultado', () {
      expect(ids(const GameFilter(result: GameResult.draw)), [
        'lichess_GhI13579',
      ]);
      expect(ids(const GameFilter(result: GameResult.win)), [
        'lichess_DeF67890',
        'lichess_MnO11223',
      ]);
    });

    test('ritmo e resultado juntos (E, não OU)', () {
      const f = GameFilter(
        timeControl: TimeControl.blitz,
        result: GameResult.loss,
      );
      expect(ids(f), [CoachFixtures.idTiago]);
    });

    test('combinação sem partidas dá lista vazia', () {
      const f = GameFilter(
        timeControl: TimeControl.bullet,
        result: GameResult.win,
      );
      expect(f.apply(list), isEmpty);
    });
  });

  group('FiltroPartidas.comRitmo / comResultado', () {
    test('mudam só o seu campo e deixam o outro', () {
      const base = GameFilter(result: GameResult.win);
      final f = base.withTimeControl(TimeControl.blitz);
      expect(f.timeControl, TimeControl.blitz);
      expect(f.result, GameResult.win);
      expect(f.withResult(null).result, isNull);
      expect(f.withResult(null).timeControl, TimeControl.blitz);
    });

    test('limpar os dois volta a vazio', () {
      final f = const GameFilter(
        timeControl: TimeControl.blitz,
        result: GameResult.draw,
      ).withTimeControl(null).withResult(null);
      expect(f.empty, isTrue);
      expect(f, GameFilter.everyone);
    });
  });

  group('FiltroPartidas json', () {
    test('ida e volta preserva o filtro', () {
      const f = GameFilter(
        timeControl: TimeControl.rapid,
        result: GameResult.loss,
      );
      expect(GameFilter.fromJson(f.toJson()), f);
    });

    test('toJson usa os nomes de fio e nulo para "todos"', () {
      expect(const GameFilter(timeControl: TimeControl.blitz).toJson(), {
        'ritmo': 'blitz',
        'resultado': null,
      });
    });

    test('fromJson de lixo ou valor desconhecido dá "todos"', () {
      expect(GameFilter.fromJson(null), GameFilter.everyone);
      expect(GameFilter.fromJson('x'), GameFilter.everyone);
      expect(
        GameFilter.fromJson({'ritmo': 'xadrez960', 'resultado': 7}),
        GameFilter.everyone,
      );
    });
  });

  group('FiltroPartidas igualdade', () {
    test('mesmos campos: iguais e mesmo hashCode', () {
      const a = GameFilter(timeControl: TimeControl.blitz);
      const b = GameFilter(timeControl: TimeControl.blitz);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('campos diferentes: diferentes', () {
      expect(
        const GameFilter(timeControl: TimeControl.blitz) ==
            const GameFilter(timeControl: TimeControl.bullet),
        isFalse,
      );
    });
  });
}
