import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/routing/routes.dart';
import 'package:patrol/patrol.dart';

import 'robots/recorded_journey_robot.dart';

/// Um link de post por origem, cada um com a sua marcação (`utm_*`).
const _origins = [
  ('Post no X', {'utm_source': 'x', 'utm_medium': 'post'}),
  (
    'Stories do Instagram',
    {'utm_source': 'instagram', 'utm_medium': 'stories'},
  ),
  ('Bio do Instagram', {'utm_source': 'instagram', 'utm_medium': 'bio'}),
  ('Bio do YouTube', {'utm_source': 'youtube', 'utm_medium': 'bio'}),
  (
    'Partida do dia',
    {
      'utm_source': 'instagram',
      'utm_medium': 'post',
      'utm_content': 'partida-do-dia',
    },
  ),
  (
    'Posição do dia',
    {
      'utm_source': 'instagram',
      'utm_medium': 'post',
      'utm_content': 'posicao-do-dia',
    },
  ),
];

// Jornada gravada 6 da R5 (`docs/tasks/E1.19-qa-r5.md`): um link de aula por
// origem, aberto de fora por `adb shell am start -a VIEW -d <link>` (o
// gravador faz isso na marca `link`), com o app instalado e a conta criada.
// Cada link abre a aula e grava a campanha com a marcação dele. Não dá para
// simular aqui: os números de /redes/medicao (o Analytics fica desligado no
// E2E e o painel lê do GA4) e o Install Referrer do link aberto sem o app.
void main() {
  patrolTest('Jornada 6: redes por link', ($) async {
    final journey = RecordedJourneyRobot($);
    final app = journey.app;
    final marks = journey.marks;
    await journey.signUp('jornada-redes');
    final campaigns = app.dependencies.campaignRepository;

    for (final (name, utm) in _origins) {
      final link = Uri.https(AppLinks.finalHost, '/aula/rook.lucena', {
        ...utm,
        'utm_campaign': 'lucena-r5',
      }).toString();
      await marks.step('Link de $name');
      await app.go(Routes.home);
      await journey.toBackground();
      marks.openLink(link);
      final watch = Stopwatch()..start();
      bool same(Map<String, String>? saved) => [
        'utm_source',
        'utm_medium',
        'utm_content',
      ].every((key) => saved?[key] == utm[key]);
      while (!same((await campaigns.active())?.utm)) {
        if (watch.elapsed > const Duration(seconds: 30)) {
          fail('o link de $name não gravou a campanha: ${app.routes}');
        }
        await marks.hold(300);
      }
      await marks.step(
        '$name: a aula abre com a marcação ${utm.values.join(' / ')}',
      );
      await marks.hold(3000);
    }
    await marks.panel('Painel: /redes/medicao (sem dados do emulador)');
  });
}
