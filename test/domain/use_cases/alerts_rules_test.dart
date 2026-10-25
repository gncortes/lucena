import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/use_cases/alerts_rules.dart';

void main() {
  group('contagem', () {
    test('de fábrica: 3 de 4 (Novidades desligada)', () {
      const settings = AlertSettings();

      expect(settings.enabled(push: true), 3);
      expect(AlertSettings.total(push: true), 4);
    });

    test('sem push só a chave local conta', () {
      const settings = AlertSettings(daily: false);

      expect(settings.enabled(push: false), 0);
      expect(AlertSettings.total(push: false), 1);
    });

    test('19h de fábrica', () {
      expect(const AlertSettings().reminderMinutes, 19 * 60);
    });
  });

  group('tópicos', () {
    test('torneio do país e do estado, aulas, e o de todos', () {
      expect(
        AlertsRules.topics(const AlertSettings(), country: 'br', state: 'pr'),
        {
          'all',
          'torneio_BR',
          'torneio_BR_PR',
          'pais_BR',
          'pais_BR_PR',
          'dia',
          'aulas',
        },
      );
    });

    test('sem estado, só o do país; Novidades ligada entra', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(news: true, lessons: false),
          country: 'BR',
        ),
        {'all', 'torneio_BR', 'pais_BR', 'dia', 'novidades'},
      );
    });

    test('estado digitado (fora do Brasil) não vira tópico', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(),
          country: 'PT',
          state: 'Lisboa',
        ),
        {'all', 'torneio_PT', 'pais_PT', 'dia', 'aulas'},
      );
    });

    test('sem país, sem torneio', () {
      expect(AlertsRules.topics(const AlertSettings()), {
        'all',
        'dia',
        'aulas',
      });
    });

    test('tudo desligado: só o de todos', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(tournaments: false, daily: false, lessons: false),
          country: 'BR',
          language: 'pt',
        ),
        {'all'},
      );
    });

    test('o público do painel: país, estado e idioma do app', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(tournaments: false, daily: false),
          country: 'BR',
          state: 'PR',
          language: 'pt',
        ),
        {'all', 'pais_BR', 'pais_BR_PR', 'idioma_pt', 'aulas'},
      );
    });

    test('só o final do dia ligado: dia, país e idioma', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(tournaments: false, lessons: false),
          country: 'AR',
          language: 'es',
        ),
        {'all', 'pais_AR', 'idioma_es', 'dia'},
      );
    });

    test('país ou idioma que não são código não viram tópico', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(lessons: false, daily: false),
          country: 'Brasil',
          language: 'pt_BR',
        ),
        {'all'},
      );
    });
  });

  test('trocar de estado troca também o pais_<PAIS>_<UF>', () {
    final changes = AlertsRules.changes(
      AlertsRules.topics(const AlertSettings(), country: 'BR', state: 'PR'),
      AlertsRules.topics(const AlertSettings(), country: 'BR', state: 'SP'),
    );

    expect(changes.subscribe, {'torneio_BR_SP', 'pais_BR_SP'});
    expect(changes.unsubscribe, {'torneio_BR_PR', 'pais_BR_PR'});
  });

  test('reinscrição ao trocar de estado', () {
    final changes = AlertsRules.changes(
      {'all', 'torneio_BR', 'torneio_BR_PR'},
      {'all', 'torneio_BR', 'torneio_BR_SP'},
    );

    expect(changes.subscribe, {'torneio_BR_SP'});
    expect(changes.unsubscribe, {'torneio_BR_PR'});
  });
}
