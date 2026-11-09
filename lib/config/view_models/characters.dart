import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/characters/character_repository.dart';
import '../../domain/models/character.dart';

/// O Viktor (personagem `master`) pelo repositório do [context]. Nulo se não há.
Future<Character?> loadViktor(BuildContext context) async {
  final all = await context.read<CharacterRepository>().characters();
  for (final character in all) {
    if (character.id == 'master') return character;
  }
  return null;
}
