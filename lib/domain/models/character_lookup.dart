import 'character.dart';

extension CharacterLookup on List<Character> {
  /// O personagem do nível [level] do Maia. Nulo se não há.
  Character? forLevel(int? level) {
    for (final character in this) {
      if (character.level == level) return character;
    }
    return null;
  }
}
