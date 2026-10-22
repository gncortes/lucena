import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/data/services/firebase/push_service.dart';

class _Push extends NoPushService {
  PushMessage? initial;
  final topics = <String>[];
  bool failSubscribe = false;
  final controller = StreamController<PushMessage>.broadcast();

  @override
  Future<void> subscribe(String topic) async {
    if (failSubscribe) throw StateError('sem rede');
    topics.add(topic);
  }

  @override
  Future<PushMessage?> initialOpened() async => initial;

  @override
  Stream<PushMessage> get opened => controller.stream;
}

void main() {
  late _Push service;
  late FirebasePushRepository repository;

  setUp(() {
    service = _Push();
    repository = FirebasePushRepository(service);
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
}
