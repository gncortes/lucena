import 'dart:convert';

import '../../../domain/models/character.dart';
import '../../services/asset_service.dart';
import 'character_repository.dart';

/// Lidos de `assets/characters/` e `assets/lines/<idioma>/`, uma vez cada.
class AssetCharacterRepository implements CharacterRepository {
  AssetCharacterRepository(this._assets);

  /// Os personagens que o app leva. Personagem novo = arquivo novo e o id
  /// aqui.
  static const ids = [
    'beachgoer',
    'grandpa',
    'snob',
    'magician',
    'prodigy',
    'bodybuilder',
    'foodie',
    'youngster',
    'master',
  ];

  /// Os idiomas com falas; os outros usam o inglês.
  static const languages = {'en', 'pt'};

  final AssetService _assets;
  Future<List<Character>>? _characters;
  final _lines = <String, Future<List<CharacterLine>>>{};

  @override
  Future<List<Character>> characters() => _characters ??= _loadCharacters();

  Future<List<Character>> _loadCharacters() async {
    final characters = <Character>[];
    for (final id in ids) {
      final json = jsonDecode(
        await _assets.loadString('assets/characters/$id.json'),
      );
      final character = Character.fromJson(json as Map<String, dynamic>);
      if (character != null) characters.add(character);
    }
    return characters..sort((a, b) => a.level.compareTo(b.level));
  }

  @override
  Future<List<CharacterLine>> lines(String characterId, String language) {
    final code = languages.contains(language) ? language : 'en';
    return _lines['$code/$characterId'] ??= _loadLines(characterId, code);
  }

  Future<List<CharacterLine>> _loadLines(String id, String language) async {
    final json = jsonDecode(
      await _assets.loadString('assets/lines/$language/$id.json'),
    ) as Map<String, dynamic>;
    return [
      for (final item in (json['lines'] as List).cast<Map<String, dynamic>>())
        // Categoria que esta versão não conhece fica de fora.
        ?CharacterLine.fromJson(item),
    ];
  }
}
