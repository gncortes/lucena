import 'dart:async';

import 'package:lucena/data/repositories/lesson_video/video_interruptions_repository.dart';

/// Interrupções da aula em vídeo disparadas pelo teste com [emit].
class FakeVideoInterruptionsRepository implements VideoInterruptionsRepository {
  final _controller = StreamController<VideoInterruption>.broadcast();

  @override
  Stream<VideoInterruption> get interruptions => _controller.stream;

  /// Quantos ouvintes estão assinando (o view model cancela no `close`).
  bool get hasListener => _controller.hasListener;

  void emit(VideoInterruption interruption) => _controller.add(interruption);
}
