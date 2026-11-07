import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/ui/featured/view_models/featured_alert_cubit.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_push_repository.dart';

void main() {
  late FakeFeaturedAlertsRepository prompts;
  late FakeAlertsRepository alerts;
  late FakePushRepository push;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    prompts = FakeFeaturedAlertsRepository();
    alerts = FakeAlertsRepository();
    push = FakePushRepository(granted: true);
    analytics = FakeAnalyticsRepository();
  });

  Future<FeaturedAlertCubit> open({String id = 'a'}) async {
    final cubit = FeaturedAlertCubit(
      id: id,
      prompts: prompts,
      alerts: alerts,
      push: push,
      analytics: analytics,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('final novo, aviso de torneios desligado: o cartão aparece', () async {
    alerts.settings = const AlertSettings(tournaments: false);
    push.allowed = true;
    expect((await open()).state.visible, isTrue);
  });

  test('chave ligada mas sem permissão do sistema: o cartão aparece', () async {
    alerts.settings = const AlertSettings(tournaments: true);
    push.allowed = false;
    expect((await open()).state.visible, isTrue);
  });

  test('aviso ligado e permitido: o cartão não aparece', () async {
    alerts.settings = const AlertSettings(tournaments: true);
    push.allowed = true;
    expect((await open()).state.visible, isFalse);
  });

  test('sem push (build sem Firebase): o cartão não aparece', () async {
    push.available = false;
    expect((await open()).state.visible, isFalse);
  });

  test('"Agora não": some, grava e não volta neste final', () async {
    alerts.settings = const AlertSettings(tournaments: false);
    final cubit = await open();
    await cubit.decline();
    expect(cubit.state.visible, isFalse);
    expect((await open()).state.visible, isFalse);
    expect((await open(id: 'b')).state.visible, isTrue);
    expect(alerts.settings.tournaments, isFalse);
    final event = analytics.eventsNamed('aviso_pedido').single;
    expect(event.params, {
      'resposta': 'agora_nao',
      'gatilho': 'final_destaque',
    });
  });

  test('"Quero receber": pede a permissão e devolve que foi dada', () async {
    final cubit = await open();
    expect(await cubit.accept(), isTrue);
    expect(push.permissionRequests, 1);
    expect(cubit.state.visible, isFalse);
    expect((await open()).state.visible, isFalse);
    expect(
      analytics.eventsNamed('aviso_pedido').single.params['resposta'],
      'permitiu',
    );
  });

  test('permissão já dada: não pergunta de novo', () async {
    push.allowed = true;
    final cubit = await open();
    expect(await cubit.accept(), isTrue);
    expect(push.permissionRequests, 0);
  });

  test('permissão negada: não liga e o cartão não insiste', () async {
    push.granted = false;
    final cubit = await open();
    expect(await cubit.accept(), isFalse);
    expect(cubit.state.visible, isFalse);
    expect((await open()).state.visible, isFalse);
    expect(
      analytics.eventsNamed('aviso_pedido').single.params['resposta'],
      'negou_sistema',
    );
  });
}
