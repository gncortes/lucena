import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/alerts/view_models/alerts_cubit.dart';

import '../../../testing/fakes/fake_alerts_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_push_repository.dart';

void main() {
  late FakeAlertsRepository alerts;
  late FakePushRepository push;
  late FakeProfileRepository profile;

  AlertsCubit build({String? region}) {
    final cubit = AlertsCubit(
      alerts: alerts,
      push: push,
      profile: profile,
      region: () => region,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    alerts = FakeAlertsRepository();
    push = FakePushRepository(allowed: true);
    profile = FakeProfileRepository(const UserProfile(country: 'BR'));
  });

  test('permitido: lê as chaves e segue os tópicos', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.ready, isTrue);
    expect(cubit.state.permitted, isTrue);
    expect(cubit.state.enabled, 3);
    expect(push.followed, {'all', 'torneio_BR', 'pais_BR', 'dia', 'aulas'});
  });

  test('negado: o estado diz, e nada pede permissão', () async {
    push.allowed = false;
    final cubit = build();
    await cubit.load();

    expect(cubit.state.permitted, isFalse);
    expect(push.permissionRequests, 0);
  });

  test('voltou dos ajustes com a permissão: relê sozinho', () async {
    push.allowed = false;
    final cubit = build();
    await cubit.load();

    push.allowed = true;
    await cubit.refresh();

    expect(cubit.state.permitted, isTrue);
  });

  test('mudar uma chave grava e reinscreve', () async {
    final cubit = build();
    await cubit.load();

    await cubit.change(cubit.state.settings.copyWith(tournaments: false));

    expect(alerts.settings.tournaments, isFalse);
    expect(push.followed, {'all', 'pais_BR', 'dia', 'aulas'});
    expect(cubit.state.enabled, 2);
  });

  test('a hora dos lembretes grava', () async {
    final cubit = build();
    await cubit.load();

    await cubit.setReminder(21 * 60);

    expect(alerts.settings.reminderMinutes, 21 * 60);
  });

  test('sem país no Perfil, vale a região do celular', () async {
    profile = FakeProfileRepository();
    final cubit = build(region: 'pt');
    await cubit.load();

    expect(push.followed, contains('torneio_PT'));
  });

  test('trocar o país reinscreve', () async {
    final cubit = build();
    await cubit.load();

    await profile.save(const UserProfile(country: 'AR'));
    await cubit.regionChanged();

    expect(push.followed, {'all', 'torneio_AR', 'pais_AR', 'dia', 'aulas'});
  });

  test('o idioma do app entra no idioma_*, antes ou depois de abrir', () async {
    final cubit = build();
    await cubit.languageChanged('pt');
    expect(push.followed, isEmpty);

    await cubit.load();
    expect(push.followed, contains('idioma_pt'));

    await cubit.languageChanged('en');
    expect(push.followed, contains('idioma_en'));
    expect(push.followed, isNot(contains('idioma_pt')));
  });

  test('desligar todos os avisos de push sai do país e do idioma', () async {
    final cubit = build();
    await cubit.load();
    await cubit.languageChanged('pt');

    await cubit.change(
      const AlertSettings(
        tournaments: false,
        daily: false,
        news: false,
        lessons: false,
      ),
    );

    expect(push.followed, {'all'});
  });

  test('sem push, só a chave local conta', () async {
    push.available = false;
    alerts.settings = const AlertSettings(daily: false);
    final cubit = build();
    await cubit.load();

    expect(cubit.state.enabled, 0);
    expect(cubit.state.total, 1);
  });
}
