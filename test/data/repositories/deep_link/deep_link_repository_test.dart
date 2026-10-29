import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/deep_link/deep_link_repository.dart';
import 'package:lucena/data/services/deep_link_service.dart';

import '../../../../testing/fakes/fake_deep_link_service.dart';

const _own =
    'https://playlucena.com/p/abcde?fen=8%2F8%2F8%2F4k3%2F8%2F8%2F4K3%2F4Q3+w+-+-+0+1';

void main() {
  test(
    'URI original mantém final do dia e erro próprio para a interface',
    () async {
      final daily = Uri.parse('https://playlucena.com/dia');
      final invalid = Uri.parse(
        'https://playlucena.com/p/invalido?fen=invalida',
      );
      final service = FakeDeepLinkService(initial: daily);
      final DeepLinkRepository repository = ServiceDeepLinkRepository(service);
      expect(await repository.initialUri(), daily);
      final received = <Uri>[];
      final sub = repository.openedUris.listen(received.add);
      service.open(invalid);
      service.open(Uri.parse('https://example.com/dia'));
      service.open(Uri.parse('https://playlucena.com/daily'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(received, [invalid, Uri.parse('https://playlucena.com/daily')]);
    },
  );

  test('sem App Links nada chega', () async {
    const repository = ServiceDeepLinkRepository(NoDeepLinkService());
    expect(await repository.initial(), isNull);
  });

  test('o link que abriu o app vira desafio', () async {
    final repository = ServiceDeepLinkRepository(
      FakeDeepLinkService(initial: Uri.parse(_own)),
    );
    expect((await repository.initial())!.fen, startsWith('8/8/8/4k3'));
  });

  test('link de outro domínio ou inválido é ignorado', () async {
    final service = FakeDeepLinkService(
      initial: Uri.parse('https://outro.com/p/abcde?fen=x'),
    );
    final repository = ServiceDeepLinkRepository(service);
    expect(await repository.initial(), isNull);
    final received = <String>[];
    final sub = repository.opened.listen((link) => received.add(link.fen));
    service.open(Uri.parse('https://playlucena.com/p/abcde?fen=lixo'));
    service.open(Uri.parse(_own));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(received, hasLength(1));
  });
}
