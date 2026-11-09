import 'dart:io';

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

  test('o domínio vem da configuração (A4: o domínio não lê o ambiente)', () {
    addTearDown(() => AppLinks.configure(siteHost: AppLinks.devHost));
    AppLinks.configure(siteHost: Ambiente.prod.siteHost);
    expect(AppLinks.host, 'playlucenachess.com');
    expect(AppLinks.uri('/dia').toString(), 'https://playlucenachess.com/dia');
    expect(
      AppLinks.isOwn(Uri.https('dev.playlucenachess.com', '/p/a')),
      isFalse,
    );
  });

  test('o domínio dos links não importa a configuração', () {
    final source = File('lib/domain/models/app_links.dart').readAsStringSync();
    expect(
      source,
      isNot(matches(RegExp(r"^import .*config/", multiLine: true))),
    );
  });

  test('a abertura do app liga os links ao site do ambiente', () {
    final source = File('lib/config/startup_tasks.dart').readAsStringSync();
    expect(
      source,
      contains('AppLinks.configure(siteHost: Ambiente.atual().siteHost)'),
    );
  });
}
