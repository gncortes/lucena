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
        {'all', 'torneio_BR', 'torneio_BR_PR', 'aulas'},
      );
    });

    test('sem estado, só o do país; Novidades ligada entra', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(news: true, lessons: false),
          country: 'BR',
        ),
        {'all', 'torneio_BR', 'novidades'},
      );
    });

    test('estado digitado (fora do Brasil) não vira tópico', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(),
          country: 'PT',
          state: 'Lisboa',
        ),
        {'all', 'torneio_PT', 'aulas'},
      );
    });

    test('sem país, sem torneio', () {
      expect(AlertsRules.topics(const AlertSettings()), {'all', 'aulas'});
    });

    test('tudo desligado: só o de todos', () {
      expect(
        AlertsRules.topics(
          const AlertSettings(tournaments: false, lessons: false),
          country: 'BR',
        ),
        {'all'},
      );
    });
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
