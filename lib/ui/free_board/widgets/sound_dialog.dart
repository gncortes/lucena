import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/sound_sheet.dart';
import '../view_models/talk_cubit.dart';

/// Som e voz da partida: abre a folha única [showSoundSheet] no contexto dos
/// adversários. Preferências persistidas pelos view models existentes; fechar
/// não altera nada.
Future<void> showGameSoundDialog(BuildContext context) {
  TalkCubit? talk;
  try {
    talk = context.read<TalkCubit>();
  } on ProviderNotFoundException {
    // A folha também pode ser exercitada sem uma partida em andamento.
  }
  return showSoundSheet(
    context,
    scope: SoundSheetScope.game,
    onCharacterTalkChanged: (value) => talk?.setEnabled(enabled: value),
  );
}
