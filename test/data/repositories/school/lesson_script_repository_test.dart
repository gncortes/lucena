import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/tablebase/kpk_repository.dart';
import 'package:lucena/data/services/asset_service.dart';

import '../../../../testing/script_fixture.dart';

class _Assets extends AssetService {
  _Assets(this.files, [this.bytes = const {}]);

  final Map<String, String> files;
  final Map<String, Uint8List> bytes;
  final loaded = <String>[];

  @override
  Future<String> loadString(String path) async {
    loaded.add(path);
    final text = files[path];
    if (text == null) throw StateError('sem $path');
    return text;
  }

  @override
  Future<Uint8List> loadBytes(String path) async => bytes[path]!;
}

void main() {
  const lesson = 'pawns.test';
  String generic(String lang) => AssetLessonScriptRepository.genericPath(lang);
  String own(String lang) =>
      AssetLessonScriptRepository.lessonTextsPath(lesson, lang);

  test('lê o roteiro e guarda em cache', () async {
    final assets = _Assets({'r.json': jsonEncode(scriptJson())});
    final repo = AssetLessonScriptRepository(assets);
    final first = await repo.script('r.json');
    expect(first.partId, 'distant');
    expect(await repo.script('r.json'), same(first));
    expect(assets.loaded, ['r.json']);
  });

  test('as falas: inglês < idioma, e a da aula vence a genérica', () async {
    final repo = AssetLessonScriptRepository(
      _Assets({
        generic('en'): jsonEncode({'g': 'G-en', 'h': 'H-en'}),
        own('en'): jsonEncode({'g': 'G-aula-en', 'x': 'X-en', 'y': 'Y-en'}),
        generic('pt'): jsonEncode({'h': 'H-pt'}),
        own('pt'): jsonEncode({
          'x': 'X-pt',
          'lista': ['Primeiro', 'Segundo'],
        }),
      }),
    );
    final texts = await repo.texts(lesson, 'pt');
    expect(texts.say('g'), 'G-aula-en');
    expect(texts.say('h'), 'H-pt');
    expect(texts.say('x'), 'X-pt');
    expect(texts.say('y'), 'Y-en');
    expect(texts.say('lista'), 'Primeiro');
  });

  test(
    'arquivo que falta não derruba; idioma sem falas cai no inglês',
    () async {
      final repo = AssetLessonScriptRepository(
        _Assets({
          own('en'): jsonEncode({'x': 'X-en'}),
        }),
      );
      expect((await repo.texts(lesson, 'pt')).say('x'), 'X-en');
      expect((await repo.texts(lesson, 'fr')).say('x'), 'X-en');
      expect((await repo.texts('outra', 'en')).say('x'), 'x');
    },
  );

  test('a tabela do rei e peão: carrega uma vez e confere o tamanho', () async {
    final assets = _Assets(const {}, {
      AssetKpkRepository.path: Uint8List(196608),
    });
    final repo = AssetKpkRepository(assets);
    expect(await repo.oracle(), same(await repo.oracle()));
    final bad = AssetKpkRepository(
      _Assets(const {}, {AssetKpkRepository.path: Uint8List(10)}),
    );
    await expectLater(bad.oracle(), throwsA(anything));
  });
}
