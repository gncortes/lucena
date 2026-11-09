import '../../../domain/models/character.dart';

export '../../../domain/models/character_lookup.dart';

/// Os personagens (um por nível do Maia) e as falas deles.
abstract class CharacterRepository {
  /// Do nível mais fraco ao mais forte.
  Future<List<Character>> characters();

  /// As falas de [characterId] em [language] (`pt`, `en`). Idioma sem falas
  /// cai no inglês.
  Future<List<CharacterLine>> lines(String characterId, String language);
}
