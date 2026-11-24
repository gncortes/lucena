import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lesson_video/video_interruptions_repository.dart';
import 'package:lucena/data/repositories/lesson_video/video_interruptions_repository_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void lifecycle(AppLifecycleState state) =>
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(state);

  tearDown(() => lifecycle(AppLifecycleState.resumed));

  test('Vídeo 14: sair para outro app avisa inativo e segundo plano, '
      'e voltar não avisa nada (volta pausado)', () async {
    lifecycle(AppLifecycleState.resumed);
    final events = <VideoInterruption>[];
    final sub = DeviceVideoInterruptionsRepository().interruptions.listen(
      events.add,
    );

    lifecycle(AppLifecycleState.inactive);
    lifecycle(AppLifecycleState.hidden);
    lifecycle(AppLifecycleState.paused);
    lifecycle(AppLifecycleState.hidden);
    lifecycle(AppLifecycleState.inactive);
    lifecycle(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(events, [VideoInterruption.inactive, VideoInterruption.background]);
    await sub.cancel();
  });

  test('Vídeo 39: foco de áudio e fone chegam pelo mesmo fluxo', () async {
    final audio = StreamController<VideoInterruption>();
    final events = <VideoInterruption>[];
    final sub = DeviceVideoInterruptionsRepository(audio.stream).interruptions
        .listen(events.add);

    audio
      ..add(VideoInterruption.audioFocus)
      ..add(VideoInterruption.noisy);
    await pumpEventQueue();

    expect(events, [VideoInterruption.audioFocus, VideoInterruption.noisy]);
    await sub.cancel();
    expect(audio.hasListener, isFalse);
  });

  test('cancelar a assinatura para de ouvir o ciclo de vida', () async {
    lifecycle(AppLifecycleState.resumed);
    final events = <VideoInterruption>[];
    final sub = DeviceVideoInterruptionsRepository().interruptions.listen(
      events.add,
    );
    await sub.cancel();

    lifecycle(AppLifecycleState.inactive);
    await pumpEventQueue();

    expect(events, isEmpty);
  });
}
