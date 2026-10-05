import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/domain/models/character.dart';

/// Um personagem por nível do Maia, com três falas por categoria
/// (`<id>.<categoria>.<n>`).
class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository({List<Character>? characters})
    : all = characters ?? sampleCharacters;

  static const magician = Character(
    id: 'magician',
    level: 1600,
    name: 'Valdini',
    tagline: {'en': 'The magician', 'pt': 'O mágico'},
    personality: {},
    traits: [],
    avatar: 'assets/characters/magician/avatar.png',
  );

  static const sampleCharacters = [
    Character(
      id: 'beachgoer',
      level: 1000,
      name: 'Coco',
      tagline: {'en': 'The beachgoer', 'pt': 'O praieiro'},
      personality: {},
      traits: [],
      avatar: 'assets/characters/beachgoer/avatar.png',
    ),
    magician,
  ];

  final List<Character> all;

  /// Os pedidos de falas: personagem e idioma.
  final requests = <(String, String)>[];

  static List<CharacterLine> linesOf(String id) => [
    for (final category in LineCategory.values)
      for (var n = 1; n <= 3; n++)
        CharacterLine(
          id: '$id.${category.name}.$n',
          category: category,
          intensity: n,
          emotion: Emotion.values[n],
          text: '$id ${category.name} $n',
        ),
  ];

  @override
  Future<List<Character>> characters() async => all;

  @override
  Future<List<CharacterLine>> lines(String characterId, String language) async {
    requests.add((characterId, language));
    return linesOf(characterId);
  }
}
