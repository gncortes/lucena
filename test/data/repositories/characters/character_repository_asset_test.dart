import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/characters/character_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adversário sem arquivo de falas (o Stockfish): nenhuma fala, sem '
      'erro — a conclusão contra o Stockfish não pode travar', () async {
    final repository = AssetCharacterRepository(const AssetService());
    expect(await repository.lines(Character.stockfish.id, 'en'), isEmpty);
    expect(await repository.lines(Character.stockfish.id, 'pt'), isEmpty);
  });

  test('personagem com falas continua lendo as dele', () async {
    final repository = AssetCharacterRepository(const AssetService());
    final characters = await repository.characters();
    expect(await repository.lines(characters.first.id, 'pt'), isNotEmpty);
  });
}
