import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/pace.dart';

TimeControl _time(int minutes, int increment) => TimeControl(
  initial: Duration(minutes: minutes),
  increment: Duration(seconds: increment),
);

void main() {
  test('o ritmo segue a regra do Lichess', () {
    expect(PaceCategory.of(_time(1, 0)), PaceCategory.bullet);
    expect(PaceCategory.of(_time(3, 0)), PaceCategory.blitz);
    expect(PaceCategory.of(_time(3, 2)), PaceCategory.blitz);
    expect(PaceCategory.of(_time(5, 3)), PaceCategory.blitz);
    expect(PaceCategory.of(_time(10, 0)), PaceCategory.rapid);
    expect(PaceCategory.of(_time(15, 10)), PaceCategory.rapid);
    expect(PaceCategory.of(_time(30, 0)), PaceCategory.classical);
  });

  test('o código do ritmo vai e volta', () {
    for (final pace in PaceCategory.values) {
      expect(PaceCategory.fromCode(pace.code), pace);
    }
    expect(PaceCategory.fromCode('hyper'), isNull);
    expect(PaceCategory.fromCode(null), isNull);
  });

  group('tabela do asset', () {
    late PaceTable table;

    setUpAll(() {
      final text = File('assets/progression/time_controls.json')
          .readAsStringSync();
      table = PaceTable.fromJson(jsonDecode(text) as Map<String, dynamic>);
    });

    test('lê os tempos com nome', () {
      expect(table.named.map((n) => n.id), [
        '1+0',
        '3+0',
        '3+2',
        '5+3',
        '10+0',
      ]);
      expect(table.named[2].time, _time(3, 2));
      expect(table.named.map((n) => n.category), [
        PaceCategory.bullet,
        PaceCategory.blitz,
        PaceCategory.blitz,
        PaceCategory.blitz,
        PaceCategory.rapid,
      ]);
    });

    test('o perfil sai do ritmo', () {
      expect(
        table.profileFor(_time(1, 0)),
        const PaceProfile(temperature: 0.3, thinkScale: 0.45),
      );
      expect(
        table.profileFor(_time(3, 2)),
        const PaceProfile(temperature: 0.4, thinkScale: 0.75),
      );
      expect(table.profileFor(_time(10, 0)), PaceProfile.standard);
      expect(table.profileFor(null), PaceProfile.standard);
    });
  });

  test('sem relógio vale o clássico', () {
    const classical = PaceProfile(temperature: 0.45, thinkScale: 1.2);
    const table = PaceTable(
      named: [],
      profiles: {PaceCategory.classical: classical},
    );
    expect(table.profileFor(null), classical);
    expect(table.profileFor(_time(1, 0)), PaceProfile.standard);
  });

  test('entradas inválidas são ignoradas', () {
    final table = PaceTable.fromJson({
      'named': [
        {'id': '1+0', 'time': '60+0'},
        {'id': '0+0', 'time': '0+0'},
        {'time': '60+0'},
        'lixo',
      ],
      'profiles': {
        'bullet': {'temperature': 0.3, 'thinkScale': 0.5},
        'blitz': {'temperature': 'x', 'thinkScale': 1},
        'hyper': {'temperature': 0.1, 'thinkScale': 0.1},
        'rapid': 3,
      },
    });
    expect(table.named.map((n) => n.id), ['1+0']);
    expect(table.profiles.keys, [PaceCategory.bullet]);
    expect(PaceTable.fromJson({}).named, isEmpty);
    expect(PaceTable.fromJson({'named': 1, 'profiles': []}).profiles, isEmpty);
  });
}
