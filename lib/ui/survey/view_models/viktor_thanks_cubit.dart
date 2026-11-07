import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/character.dart';

/// O Viktor do agradecimento (pesquisa e feedback). Nulo enquanto carrega ou
/// se a leitura falha: a tela mostra só o texto, sem erro.
class ViktorThanksCubit extends Cubit<Character?> {
  ViktorThanksCubit({required this.characters}) : super(null);

  final CharacterRepository characters;

  Future<void> load() async {
    try {
      for (final character in await characters.characters()) {
        if (character.id == 'master') {
          if (!isClosed) emit(character);
          return;
        }
      }
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
  }
}
