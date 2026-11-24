import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/glossary/glossary_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('sem $key');
    return ByteData.sublistView(utf8.encode(text));
  }
}

void main() {
  test('lê os termos válidos, em ordem alfabética sem acento', () async {
    final repo = AssetGlossaryRepository(
      AssetService(
        _Bundle({
          AssetGlossaryRepository.path: jsonEncode({
            'termos': [
              {
                'id': 'z',
                'nome': 'Zugzwang',
                'definicao': 'd',
                'chaveWiki': null,
              },
              {'id': 'o', 'nome': 'Oposição', 'definicao': 'd'},
              {'id': 'x', 'nome': '', 'definicao': 'sem nome'},
              'lixo',
            ],
          }),
        }),
      ),
    );
    final terms = await repo.terms();
    expect(terms.map((t) => t.id), ['o', 'z']);
  });

  test('sem o arquivo, lista vazia', () async {
    final repo = AssetGlossaryRepository(AssetService(_Bundle({})));
    expect(await repo.terms(), isEmpty);
  });

  test('o asset do app é válido e todo termo tem definição', () {
    final json = jsonDecode(
      File(AssetGlossaryRepository.path).readAsStringSync(),
    );
    final terms = AssetGlossaryRepository.parse(json);
    expect(terms, isNotEmpty);
    expect(terms.length, (json['termos'] as List).length);
    for (final term in terms) {
      if (term.wikiKey != null) expect(term.wikiUrl, isNotNull);
    }
  });
}
