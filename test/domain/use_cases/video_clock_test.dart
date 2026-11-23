import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/video_clock.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  final t0 = DateTime.utc(2026, 11, 23, 10);

  test('parado não anda; tocando anda com a hora', () {
    const stopped = VideoClock(anchor: Duration(seconds: 2));
    expect(stopped.playing, isFalse);
    expect(stopped.position(t0.add(ms(900))), const Duration(seconds: 2));
    final playing = stopped.play(t0);
    expect(playing.playing, isTrue);
    expect(playing.position(t0.add(ms(900))), ms(2900));
  });

  test('pausar guarda a posição; buscar mantém tocando', () {
    final playing = const VideoClock().play(t0);
    final paused = playing.pause(t0.add(ms(1500)));
    expect(paused.playing, isFalse);
    expect(paused.position(t0.add(ms(9000))), ms(1500));
    final sought = playing.seek(ms(6000), t0.add(ms(100)));
    expect(sought.position(t0.add(ms(1100))), ms(7000));
  });

  test('buscar parado continua parado no novo instante', () {
    const paused = VideoClock(anchor: Duration(seconds: 3));
    final sought = paused.seek(ms(500), t0);
    expect(sought.playing, isFalse);
    expect(sought.position(t0.add(ms(4000))), ms(500));
  });

  test('tocar de novo não reinicia a contagem', () {
    final playing = const VideoClock().play(t0);
    final again = playing.play(t0.add(ms(700)));
    expect(again.position(t0.add(ms(1000))), ms(1000));
  });

  test('hora anterior ao começo não anda para trás', () {
    final playing = const VideoClock(anchor: Duration(seconds: 1)).play(t0);
    expect(playing.position(t0.subtract(ms(300))), const Duration(seconds: 1));
  });
}
