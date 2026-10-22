import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/data/services/firebase/push_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Push extends NoPushService {
  PushMessage? initial;
  final topics = <String>[];
  final left = <String>[];
  bool failSubscribe = false;
  bool allowed = false;
  final controller = StreamController<PushMessage>.broadcast();

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
}

void main() {
  late _Push service;
  late FirebasePushRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = _Push();
    repository = FirebasePushRepository(service, PreferencesService());
  });

  test('ligar entra no tópico de todos', () async {
    await repository.start();

    expect(service.topics, [PushRepository.everyone]);
  });

  test('sem rede, ligar não quebra a abertura do app', () async {
    service.failSubscribe = true;

    await expectLater(repository.start(), completes);
  });

  test('o aviso que abriu o app entrega o link', () async {
    service.initial = const PushMessage(
      data: {'link': 'https://lucena-2f4de.web.app/p/k7Qe2'},
    );

    expect(
      await repository.initialLink(),
      Uri.parse('https://lucena-2f4de.web.app/p/k7Qe2'),
    );
  });

  test('aviso sem link não abre nada', () async {
    service.initial = const PushMessage(data: {'title': 'oi'});

    expect(await repository.initialLink(), isNull);
  });

  test('avisos tocados depois só passam quando têm link', () async {
    final links = <Uri>[];
    final subscription = repository.openedLinks.listen(links.add);

    service.controller
      ..add(const PushMessage())
      ..add(const PushMessage(data: {'link': 'https://playlucena.com/p/a'}));
    await pumpEventQueue();

    expect(links, [Uri.parse('https://playlucena.com/p/a')]);
    await subscription.cancel();
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
