import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_links.dart';

void main() {
  test('os links saem no domínio provisório', () {
    expect(AppLinks.uri('/p/a').host, 'lucena-2f4de.web.app');
  });

  test('o app abre o provisório e o definitivo, com ou sem www', () {
    for (final host in [
      'lucena-2f4de.web.app',
      'playlucena.com',
      'www.playlucena.com',
    ]) {
      expect(AppLinks.isOwn(Uri.https(host, '/p/a')), isTrue, reason: host);
    }
    expect(AppLinks.isOwn(Uri.https('lucena-2f4de.firebaseapp.com')), isFalse);
    expect(AppLinks.isOwn(Uri.https('example.com', '/p/a')), isFalse);
  });
}
