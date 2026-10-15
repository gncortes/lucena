import 'package:flutter/material.dart';

import 'sound_sheet.dart';

/// Som e voz da aula: abre a folha única [showSoundSheet] no contexto da aula
/// (som geral, voz do Viktor e velocidade).
Future<void> showLessonSoundDialog(BuildContext context) =>
    showSoundSheet(context, scope: SoundSheetScope.lesson);
