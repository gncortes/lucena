import 'package:flutter/widgets.dart';

/// A tela "Aula concluída" (E1.05).
abstract final class LessonFinishedKeys {
  static const screen = Key('lessonFinished.screen');

  /// "Próxima: {aula}" e "Voltar às aulas" / "Voltar à escola".
  static const next = Key('lessonFinished.next');
  static const back = Key('lessonFinished.back');
}
