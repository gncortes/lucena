import 'dart:async';

import 'package:flutter/widgets.dart';

import 'video_interruptions_repository.dart';

/// Interrupções do aparelho: ciclo de vida do app ([AppLifecycleListener]) e,
/// quando o L4 (voz) entrar, o foco de áudio e o fone ([audio]).
///
/// [audio] é o fluxo de interrupções de áudio do `audio_session` (L4):
/// `interruptionEventStream` com `begin == true` → [VideoInterruption.audioFocus];
/// `becomingNoisyEventStream` → [VideoInterruption.noisy]. Sem ele (antes do
/// L4, ou sem voz), só o ciclo de vida conta.
class DeviceVideoInterruptionsRepository
    implements VideoInterruptionsRepository {
  DeviceVideoInterruptionsRepository([this._audio]);

  final Stream<VideoInterruption>? _audio;

  @override
  Stream<VideoInterruption> get interruptions {
    late final StreamController<VideoInterruption> controller;
    AppLifecycleListener? listener;
    StreamSubscription<VideoInterruption>? audio;
    controller = StreamController<VideoInterruption>(
      onListen: () {
        listener = AppLifecycleListener(
          onInactive: () => controller.add(VideoInterruption.inactive),
          onHide: () => controller.add(VideoInterruption.background),
        );
        audio = _audio?.listen(controller.add);
      },
      onCancel: () async {
        listener?.dispose();
        await audio?.cancel();
      },
    );
    return controller.stream;
  }
}
