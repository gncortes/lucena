import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/analytics_rules.dart';

void main() {
  group('nomes', () {
    test('até 40 caracteres, letra no começo, sem prefixo reservado', () {
      expect(AnalyticsRules.validName('final_destaque_ache_lance'), isTrue);
      expect(AnalyticsRules.validName('a' * 40), isTrue);
      expect(AnalyticsRules.validName('a' * 41), isFalse);
      expect(AnalyticsRules.validName('1_evento'), isFalse);
      expect(AnalyticsRules.validName('com-hifen'), isFalse);
      expect(AnalyticsRules.validName('firebase_x'), isFalse);
      expect(AnalyticsRules.validName('ga_x'), isFalse);
    });
  });

  group('sanitize', () {
    test('tira nulos, troca bool e Duration e corta o texto', () {
      final params = AnalyticsRules.sanitize('evento', {
        'nulo': null,
        'ligado': true,
        'tempo': const Duration(minutes: 2, milliseconds: 900),
        'texto': 'x' * 150,
        'numero': 3,
      })!;
      expect(params.containsKey('nulo'), isFalse);
      expect(params['ligado'], 'sim');
      expect(params['tempo'], 120);
      expect(params['texto'], hasLength(100));
      expect(params['numero'], 3);
    });

    test('rejeita nome ruim e parâmetros demais', () {
      expect(AnalyticsRules.sanitize('ruim-nome', const {}), isNull);
      expect(AnalyticsRules.sanitize('evento', const {'ruim-param': 1}), isNull);
      expect(
        AnalyticsRules.sanitize('evento', {for (var i = 0; i < 26; i++) 'p$i': i}),
        isNull,
      );
    });

    test('a propriedade corta o valor em 36', () {
      expect(AnalyticsRules.traitValue('origem_fonte', 'y' * 50), hasLength(36));
      expect(AnalyticsRules.traitValue('a' * 25, 'valor'), isNull);
    });
  });

  group('faixas', () {
    test('rating', () {
      expect(AnalyticsRules.ratingBand(null), 'nenhum');
      expect(AnalyticsRules.ratingBand(799), 'ate_800');
      expect(AnalyticsRules.ratingBand(800), '800_1199');
      expect(AnalyticsRules.ratingBand(1599), '1200_1599');
      expect(AnalyticsRules.ratingBand(1999), '1600_1999');
      expect(AnalyticsRules.ratingBand(2400), '2000_mais');
    });

    test('sequência, aulas e tamanho do texto', () {
      expect(AnalyticsRules.streakBand(0), '0');
      expect(AnalyticsRules.streakBand(2), '1_2');
      expect(AnalyticsRules.streakBand(6), '3_6');
      expect(AnalyticsRules.streakBand(13), '7_13');
      expect(AnalyticsRules.streakBand(30), '14_mais');
      expect(AnalyticsRules.lessonsBand(0), '0');
      expect(AnalyticsRules.lessonsBand(4), '3_5');
      expect(AnalyticsRules.lessonsBand(6), '6');
      expect(AnalyticsRules.lengthBand(50), 'ate_50');
      expect(AnalyticsRules.lengthBand(51), '51_200');
      expect(AnalyticsRules.lengthBand(400), '201_500');
    });
  });

  group('posição e lugar', () {
    test('o FEN vira custom_ com 8 hex, sempre o mesmo', () {
      const fen = '8/8/8/8/8/2k5/8/K1Q5 w - - 0 1';
      final id = AnalyticsRules.positionId(null, fen);
      expect(id, matches(RegExp(r'^custom_[0-9a-f]{8}$')));
      expect(AnalyticsRules.positionId('', fen), id);
      expect(AnalyticsRules.positionId('kq_k', fen), 'kq_k');
    });

    test('UF e país em 2 letras, ou nenhum', () {
      expect(AnalyticsRules.stateOrNone(' sp '), 'SP');
      expect(AnalyticsRules.stateOrNone('São Paulo'), 'nenhum');
      expect(AnalyticsRules.stateOrNone(null), 'nenhum');
      expect(AnalyticsRules.countryOrNone('br'), 'BR');
    });
  });

  group('links', () {
    test('o link criado no app é orgânico e fica fora da campanha', () {
      expect(AnalyticsRules.linkOrigin('app'), 'organico');
      expect(AnalyticsRules.linkOrigin('instagram'), 'nosso');
      expect(AnalyticsRules.linkOrigin(null), 'nosso');
      const app = {'utm_source': 'app', 'utm_campaign': 'x'};
      expect(AnalyticsRules.campaignValue(app, 'utm_campaign'), isNull);
      const ours = {'utm_source': 'Instagram', 'utm_campaign': 'Lucena'};
      expect(AnalyticsRules.campaignValue(ours, 'utm_source'), 'instagram');
      expect(AnalyticsRules.campaignValue(ours, 'utm_campaign'), 'lucena');
    });
  });

  group('modo do build', () {
    test('F-Droid e Patrol nunca medem', () {
      expect(
        AnalyticsRules.mode(release: true, fdroid: true),
        AnalyticsMode.off,
      );
      expect(AnalyticsRules.mode(release: true, e2e: true), AnalyticsMode.off);
    });

    test('debug só com o DebugView, e marcado como da equipe', () {
      expect(AnalyticsRules.mode(release: false), AnalyticsMode.off);
      expect(
        AnalyticsRules.mode(release: false, debugView: true),
        AnalyticsMode.internal,
      );
    });

    test('a QA sai interna; a Play, normal', () {
      expect(
        AnalyticsRules.mode(release: true, channel: 'qa'),
        AnalyticsMode.internal,
      );
      expect(AnalyticsRules.mode(release: true), AnalyticsMode.normal);
    });

    test('coleta só com o build medindo, a chave ligada e fora do Modo equipe', () {
      expect(
        AnalyticsRules.collects(AnalyticsMode.normal, optIn: true, team: false),
        isTrue,
      );
      expect(
        AnalyticsRules.collects(AnalyticsMode.normal, optIn: false, team: false),
        isFalse,
      );
      expect(
        AnalyticsRules.collects(AnalyticsMode.normal, optIn: true, team: true),
        isFalse,
      );
      expect(
        AnalyticsRules.collects(AnalyticsMode.off, optIn: true, team: false),
        isFalse,
      );
    });
  });

  group('dado pessoal', () {
    test('FEN, e-mail, token e texto livre são pegos', () {
      expect(AnalyticsRules.looksPersonal('8/8/8/8/8/2k5/8/K1Q5 w'), isTrue);
      expect(AnalyticsRules.looksPersonal('ana@exemplo.com'), isTrue);
      expect(
        AnalyticsRules.looksPersonal('a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5'),
        isTrue,
      );
      expect(
        AnalyticsRules.looksPersonal('gostei muito da aula de hoje'),
        isTrue,
      );
    });

    test('códigos e números passam', () {
      expect(AnalyticsRules.looksPersonal('final_destaque'), isFalse);
      expect(AnalyticsRules.looksPersonal('k7Qe2'), isFalse);
      expect(AnalyticsRules.looksPersonal(1400), isFalse);
    });
  });
}
