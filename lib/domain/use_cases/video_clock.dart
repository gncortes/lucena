/// O relógio do vídeo: onde está a agulha num instante do relógio do app.
/// Imutável; quem o usa passa a hora (`Now`), então os testes controlam
/// o tempo. Tocando, a posição anda com a [rate] desde [since].
class VideoClock {
  const VideoClock({this.anchor = Duration.zero, this.since});

  /// A posição quando o relógio foi ancorado (play, pause, seek).
  final Duration anchor;

  /// Quando começou a tocar; nulo = parado.
  final DateTime? since;

  bool get playing => since != null;

  Duration position(DateTime now) {
    final start = since;
    if (start == null) return anchor;
    final elapsed = now.difference(start);
    return anchor + (elapsed.isNegative ? Duration.zero : elapsed);
  }

  VideoClock play(DateTime now) =>
      playing ? this : VideoClock(anchor: anchor, since: now);

  VideoClock pause(DateTime now) => VideoClock(anchor: position(now));

  /// Vai para [t], tocando se estava tocando.
  VideoClock seek(Duration t, DateTime now) =>
      VideoClock(anchor: t, since: playing ? now : null);
}
