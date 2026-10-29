import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/app_links_deep_link_service.dart';

class _Links implements AppLinks {
  _Links(this.initial);
  final Uri initial;
  final events = StreamController<Uri>();

  @override
  Future<Uri?> getInitialLink() async => initial;

  @override
  Stream<Uri> get uriLinkStream => events.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'suprime só a repetição inicial; o mesmo link pode abrir de novo',
    () async {
      final initial = Uri.parse('https://playlucena.com/dia');
      final links = _Links(initial);
      final service = AppLinksDeepLinkService(links);
      expect(await service.initialUri(), initial);
      final received = <Uri>[];
      final sub = service.uris.listen(received.add);
      links.events.add(initial);
      links.events.add(Uri.parse('https://playlucena.com/daily'));
      links.events.add(initial);
      await Future<void>.delayed(Duration.zero);
      expect(received, [Uri.parse('https://playlucena.com/daily'), initial]);
      await sub.cancel();
      await links.events.close();
    },
  );

  test(
    'primeiro evento diferente não consome uma abertura futura do link frio',
    () async {
      final initial = Uri.parse('https://playlucena.com/dia');
      final links = _Links(initial);
      final service = AppLinksDeepLinkService(links);
      await service.initialUri();
      final received = <Uri>[];
      final sub = service.uris.listen(received.add);
      final other = Uri.parse('https://playlucena.com/p/invalido');
      links.events.add(other);
      links.events.add(initial);
      await Future<void>.delayed(Duration.zero);
      expect(received, [other, initial]);
      await sub.cancel();
      await links.events.close();
    },
  );
}
