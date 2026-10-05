import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';

void main() {
  Map<String, dynamic> read(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final ids = [
    for (final f in Directory('assets/characters').listSync())
      if (f is File && f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''),
  ]..sort();

  test('os 9 personagens dos assets são lidos', () {
    expect(ids, hasLength(9));
    final levels = <int>{};
    for (final id in ids) {
      final c = Character.fromJson(read('assets/characters/$id.json'));
      expect(c, isNotNull, reason: id);
      expect(c!.id, id);
      expect(c.taglineIn('pt'), isNotEmpty);
      expect(c.taglineIn('fr'), c.tagline['en']);
      expect(c.imageFor(Emotion.happy), c.avatar);
      levels.add(c.level);
    }
    expect(levels, hasLength(9));
  });

  for (final id in ids) {
    test('falas de $id em en e pt: todas válidas e com os mesmos ids', () {
      final byLanguage = <String, List<String>>{};
      for (final language in ['en', 'pt']) {
        final raw = read('assets/lines/$language/$id.json')['lines'] as List;
        final lines = [
          for (final l in raw)
            CharacterLine.fromJson(l as Map<String, dynamic>),
        ];
        expect(lines.where((l) => l == null), isEmpty, reason: language);
        byLanguage[language] = [for (final l in lines) l!.id]..sort();
      }
      expect(byLanguage['pt'], byLanguage['en']);
    });
  }

  test('categoria ou emoção desconhecida vira null', () {
    expect(LineCategory.fromCode('nova'), isNull);
    expect(Emotion.fromCode(null), isNull);
    expect(
      CharacterLine.fromJson({
        'id': 'x.1',
        'category': 'categoriaNova',
        'intensity': 1,
        'emotion': 'calm',
        'text': 'Oi',
      }),
      isNull,
    );
    expect(
      CharacterLine.fromJson({'id': 'x.1', 'category': 'win', 'text': 'Oi'}),
      isNull,
    );
  });

  test('imagem por emoção, com o avatar no lugar das que faltam', () {
    final c = Character.fromJson({
      'id': 'x',
      'level': 1000,
      'name': 'X',
      'tagline': {'pt': 'Olá'},
      'avatar': 'a.png',
      'images': {'happy': 'h.png', 'desconhecida': 'z.png'},
    })!;
    expect(c.imageFor(Emotion.happy), 'h.png');
    expect(c.imageFor(Emotion.sad), 'a.png');
    expect(c.imageFor(null), 'a.png');
    expect(c.images, hasLength(1));
    expect(c.taglineIn('en'), 'Olá');
  });
}
