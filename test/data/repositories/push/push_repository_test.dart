import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/data/services/firebase/push_service.dart';
import 'package:lucena/data/services/firebase/topic_count_service.dart';
import 'package:lucena/data/services/notification_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/push_alert.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_notification_service.dart';

class _Push extends NoPushService {
  PushMessage? initial;
  final topics = <String>[];
  final left = <String>[];
  bool failSubscribe = false;
  bool allowed = false;
  final controller = StreamController<PushMessage>.broadcast();
  final incoming = StreamController<PushMessage>.broadcast();

  @override
  Future<void> subscribe(String topic) async {
    if (failSubscribe) throw StateError('sem rede');
    topics.add(topic);
  }

  @override
  Future<void> unsubscribe(String topic) async => left.add(topic);

  @override
  bool get available => true;

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<PushMessage?> initialOpened() async => initial;

  @override
  Stream<PushMessage> get opened => controller.stream;

  @override
  Stream<PushMessage> get received => incoming.stream;
}

class _Counts implements TopicCountService {
  final changes = <String>[];

  @override
  Future<void> changed(String topic, int delta) async =>
      changes.add('$topic $delta');
}

const _texts = PushTexts(
  tournaments: 'Finais de torneio',
  daily: 'Final do dia',
  lessons: 'Aulas novas',
  news: 'Novidades',
);

void main() {
  test('sem Firebase, permissão local é pedida e relida pelo mesmo serviço de notificações', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final local = FakeNotificationService(
      allowed: false,
      permissionResult: true,
    );
    final none = FirebasePushRepository(
      const NoPushService(),
      PreferencesService(),
      notifications: local,
    );
    expect(none.available, isFalse);
    expect(await none.permitted(), isFalse);
    expect(await none.requestPermission(), isTrue);
    expect(local.permissionRequests, 1);
    expect(await none.permitted(), isTrue);
  });

  late _Push service;
  late FakeNotificationService notifications;
  late _Counts counts;
  late FirebasePushRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = _Push();
    notifications = FakeNotificationService();
    counts = _Counts();
    repository = FirebasePushRepository(
      service,
      PreferencesService(),
      notifications: notifications,
      counts: counts,
      texts: () async => _texts,
    );
  });

  test('ligar entra no tópico de todos', () async {
    await repository.start();

    expect(service.topics, [PushRepository.everyone]);
  });

  test('sem rede, ligar não quebra a abertura do app', () async {
    service.failSubscribe = true;

    await expectLater(repository.start(), completes);
  });

  test('o aviso que abriu o app entrega o link, o envio e o país', () async {
    service.initial = const PushMessage(
      data: {
        'link': 'https://lucena-2f4de.web.app/p/k7Qe2',
        'pushId': 'p1',
        'pais': 'BR',
      },
    );

    expect(
      await repository.initialOpening(),
      PushOpening(
        link: Uri.parse('https://lucena-2f4de.web.app/p/k7Qe2'),
        pushId: 'p1',
        country: 'BR',
      ),
    );
  });

  test('aviso sem link abre só o app', () async {
    service.initial = const PushMessage(data: {'title': 'oi'});

    expect((await repository.initialOpening())!.link, isNull);
  });

  test('app fechado: a notificação do app tocada abre', () async {
    const alert = PushAlert(
      title: 't',
      body: 'b',
      id: 'p9',
      kind: PushKind.featured,
      link: '/featured/curitiba-r5',
      country: 'BR',
    );
    notifications.launch = NotificationTap(alert.payload);

    expect(
      await repository.initialOpening(),
      PushOpening(
        link: Uri.parse('/featured/curitiba-r5'),
        pushId: 'p9',
        country: 'BR',
      ),
    );
  });

  test('o lembrete que abriu o app não é do push', () async {
    notifications.launch = const NotificationTap('/daily');

    expect(await repository.initialOpening(), isNull);
  });

  test('tocados depois: do Android e da notificação do app', () async {
    final openings = <PushOpening>[];
    final subscription = repository.opened.listen(openings.add);
    const alert = PushAlert(
      title: 't',
      body: 'b',
      id: 'p2',
      kind: PushKind.featured,
      link: '/featured/a',
    );

    service.controller.add(
      const PushMessage(data: {'link': 'https://playlucena.com/p/a'}),
    );
    notifications
      ..tap(alert.payload)
      ..tap('/daily');
    await pumpEventQueue();

    expect(openings, [
      PushOpening(link: Uri.parse('https://playlucena.com/p/a')),
      PushOpening(link: Uri.parse('/featured/a'), pushId: 'p2'),
    ]);
    await subscription.cancel();
  });

  test('mostra só o texto, no canal do tipo, sem botões', () async {
    await repository.show(
      const PushAlert(
        title: 'Final do Open de Curitiba',
        body: 'Duarte × Lemos. Jogam as brancas.',
        id: 'p3',
        kind: PushKind.featured,
        link: '/featured/curitiba-r5',
      ),
    );

    final shown = notifications.shown.single;
    expect(shown.channel.id, 'push_torneios_quieto');
    expect(shown.channel.name, 'Finais de torneio');
    expect(shown.subText, 'Finais de torneio');
    expect(shown.actions, isEmpty);
    expect(shown.id, greaterThanOrEqualTo(PushAlert.firstNotificationId));
    expect(PushOpening.isPush(shown.payload), isTrue);
  });

  test('com o app aberto, o aviso que chega aparece', () async {
    await repository.start();

    service.incoming
      ..add(
        const PushMessage(
          data: {'tipo': 'dia', 'link': '/daily'},
          title: 'Final do dia',
          body: 'Brancas jogam e ganham.',
          notified: true,
        ),
      )
      ..add(const PushMessage(data: {'link': '/daily'}));
    await pumpEventQueue();

    final shown = notifications.shown.single;
    expect(shown.title, 'Final do dia');
    expect(shown.channel.id, 'push_dia_quieto');
    expect(shown.actions, isEmpty);
  });

  test('sem os textos não mostra nada', () async {
    await FirebasePushRepository(
      service,
      PreferencesService(),
      notifications: notifications,
    ).show(const PushAlert(title: 't', body: 'b'));

    expect(notifications.shown, isEmpty);
  });

  test('a contagem acompanha os tópicos', () async {
    await repository.follow({'all', 'pais_BR'});
    await repository.follow({'all', 'pais_PT'});

    expect(counts.changes, ['all 1', 'pais_BR 1', 'pais_BR -1', 'pais_PT 1']);
  });

  test('seguir entra nos novos e sai só dos que ficaram de fora', () async {
    await repository.follow({'all', 'torneio_BR', 'aulas'});
    expect(service.topics, unorderedEquals(['all', 'torneio_BR', 'aulas']));

    service.topics.clear();
    // Outro aparelho (nova instância) lê a lista gravada.
    await FirebasePushRepository(
      service,
      PreferencesService(),
    ).follow({'all', 'torneio_PT', 'aulas'});

    expect(service.topics, ['torneio_PT']);
    expect(service.left, ['torneio_BR']);
  });

  test('tópico que falhou é tentado de novo na próxima vez', () async {
    service.failSubscribe = true;
    await repository.follow({'all'});
    service.failSubscribe = false;

    await repository.follow({'all'});

    expect(service.topics, ['all']);
  });

  test('sem Firebase, seguir não faz nada', () async {
    final none = FirebasePushRepository(
      const NoPushService(),
      PreferencesService(),
    );

    await expectLater(none.follow({'all'}), completes);
    expect(none.available, isFalse);
    expect(await none.permitted(), isFalse);
  });

  test('a permissão vem do serviço', () async {
    service.allowed = true;

    expect(await repository.permitted(), isTrue);
  });
}
