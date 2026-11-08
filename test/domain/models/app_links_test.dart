import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/ambiente.dart';
import 'package:lucena/domain/models/app_links.dart';

void main() {
  test('os links saem no site do ambiente (dev no teste, sem flavor)', () {
    expect(AppLinks.host, Ambiente.atual().siteHost);
    expect(AppLinks.uri('/p/a').host, 'dev.playlucenachess.com');
  });

  test('o app abre o site do ambiente e os de prod, com ou sem www', () {
    for (final host in [
      'dev.playlucenachess.com',
      'playlucenachess.com',
      'www.playlucenachess.com',
    ]) {
      expect(AppLinks.isOwn(Uri.https(host, '/p/a')), isTrue, reason: host);
    }
    expect(
      AppLinks.isOwn(Uri.http('dev.playlucenachess.com', '/p/a')),
      isFalse,
    );
    expect(AppLinks.isOwn(Uri.https('lucena-2f4de.firebaseapp.com')), isFalse);
    expect(AppLinks.isOwn(Uri.https('example.com', '/p/a')), isFalse);
  });
}
