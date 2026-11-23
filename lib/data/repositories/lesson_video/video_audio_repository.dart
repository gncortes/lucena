/// Toca o áudio de uma fala da aula em vídeo. O relógio do vídeo manda:
/// o view model pede para tocar a fala a partir de um ponto e para; quem
/// implementa só obedece. Sem áudio (som desligado, arquivo faltando), não
/// toca nada e o vídeo segue no mesmo relógio.
abstract interface class VideoAudioRepository {
  /// Toca [path] a partir de [from], na velocidade [rate].
  Future<void> play(String path, {required Duration from, double rate = 1});

  /// Para o que estiver tocando.
  Future<void> stop();

  /// A posição do áudio em curso (para corrigir deriva); nula sem áudio.
  Future<Duration?> position();

  /// Solta o tocador (a tela saiu).
  Future<void> dispose();
}

/// Áudio que não toca nada: o vídeo anda só pelo relógio (o mesmo caminho do
/// modo sem som). Usado até o tocador real entrar (L4) e nos testes.
class SilentVideoAudioRepository implements VideoAudioRepository {
  const SilentVideoAudioRepository();

  @override
  Future<void> play(String path, {required Duration from, double rate = 1}) =>
      Future<void>.value();

  @override
  Future<void> stop() => Future<void>.value();

  @override
  Future<Duration?> position() => Future<Duration?>.value();

  @override
  Future<void> dispose() => Future<void>.value();
}
