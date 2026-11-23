import 'package:flutter/widgets.dart';

/// A aula em vídeo (Teoria e Demonstração da lição). Marcações e som reusam
/// `LessonScriptKeys.marksToggle` e `LessonScriptKeys.soundButton`.
abstract final class LessonVideoKeys {
  static const screen = Key('lessonVideo.screen');
  static const board = Key('lessonVideo.board');
  static const caption = Key('lessonVideo.caption');

  /// O livro do topo: abre o Glossário.
  static const glossaryButton = Key('lessonVideo.glossaryButton');

  /// A barra de progresso (tocar ou arrastar leva ao ponto) e o tempo.
  static const bar = Key('lessonVideo.bar');
  static const time = Key('lessonVideo.time');

  /// Esperando o lance do aluno, e "ver a resposta".
  static const yourMove = Key('lessonVideo.yourMove');
  static const reveal = Key('lessonVideo.reveal');

  // Controles do player.
  static const playPause = Key('lessonVideo.playPause');
  static const back10 = Key('lessonVideo.back10');
  static const forward10 = Key('lessonVideo.forward10');
  static const rate = Key('lessonVideo.rate');
  static const captions = Key('lessonVideo.captions');

  /// Aviso de uma linha (retomada, sem áudio) e a ação dele.
  static const notice = Key('lessonVideo.notice');
  static const noticeAction = Key('lessonVideo.noticeAction');

  /// Rodapé do fim da etapa.
  static const endRestart = Key('lessonVideo.endRestart');
  static const endNext = Key('lessonVideo.endNext');

  static const loading = Key('lessonVideo.loading');
  static const unavailable = Key('lessonVideo.unavailable');

  /// Termo sublinhado do balão ([id] do Glossário).
  static Key term(String id) => Key('lessonVideo.term.$id');

  /// Casa sublinhada do balão.
  static Key square(String sq) => Key('lessonVideo.square.$sq');
}
