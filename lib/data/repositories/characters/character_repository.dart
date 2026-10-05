import '../../../domain/models/character.dart';

/// Os personagens (um por nível do Maia) e as falas deles.
abstract class CharacterRepository {
  /// Do nível mais fraco ao mais forte.
  Future<List<Character>> characters();

  /// As falas de [characterId] em [language] (`pt`, `en`). Idioma sem falas
  /// cai no inglês.
  Future<List<CharacterLine>> lines(String characterId, String language);
}

extension CharacterLookup on List<Character> {
  /// O personagem do nível [level] do Maia. Nulo se não há.
  Character? forLevel(int? level) {
    for (final character in this) {
      if (character.level == level) return character;
    }
    return null;
  }
}
