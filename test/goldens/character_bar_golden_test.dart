import 'package:lucena/domain/models/character.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/character_bar.dart';

import '../../testing/fakes/fake_character_repository.dart';
import '../../testing/goldens/golden_harness.dart';

void main() {
  const lines = {
    'pt': 'Você achou que eu ia cair nessa? Tente de novo!',
    'ar': 'هل ظننت أنني سأقع في هذا؟ حاول مرة أخرى!',
  };

  Goldens.matrix(
    'character_bar',
    (variant) => CharacterBar(
      talk: TalkState(
        character: FakeCharacterRepository.magician,
        emotion: Emotion.playful,
        line: CharacterLine(
          id: 'golden',
          category: LineCategory.strongMove,
          intensity: 1,
          emotion: Emotion.playful,
          text: lines[variant.locale.languageCode]!,
        ),
      ),
    ),
    height: 160,
  );
}
