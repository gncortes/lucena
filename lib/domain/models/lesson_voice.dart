/// A voz gravada de um capítulo (aula em vídeo): o pacote de áudio baixado
/// junto com o capítulo. Sem ele, a aula toca em modo leitura e mostra
/// "Sem áudio. Baixar a voz".
sealed class VoicePackState {
  const VoicePackState();
}

/// O áudio do capítulo está no aparelho, conferido pela chave e pelo hash.
final class VoicePackReady extends VoicePackState {
  const VoicePackReady();

  @override
  bool operator ==(Object other) => other is VoicePackReady;

  @override
  int get hashCode => (VoicePackReady).hashCode;
}

/// O áudio não foi baixado ("Sem áudio").
final class VoicePackMissing extends VoicePackState {
  const VoicePackMissing();

  @override
  bool operator ==(Object other) => other is VoicePackMissing;

  @override
  int get hashCode => (VoicePackMissing).hashCode;
}

/// Baixando: [done] de [total] arquivos.
final class VoicePackDownloading extends VoicePackState {
  const VoicePackDownloading(this.done, this.total);

  final int done;
  final int total;

  @override
  bool operator ==(Object other) =>
      other is VoicePackDownloading &&
      other.done == done &&
      other.total == total;

  @override
  int get hashCode => Object.hash(done, total);
}

/// O download falhou; o que já foi conferido fica, e "Tentar de novo"
/// retoma do arquivo que faltou.
final class VoicePackFailed extends VoicePackState {
  const VoicePackFailed(this.reason);

  final VoicePackFailure reason;

  @override
  bool operator ==(Object other) =>
      other is VoicePackFailed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

enum VoicePackFailure {
  /// Sem internet ou servidor fora do ar.
  network,

  /// Chegou um arquivo diferente do publicado (tamanho, hash ou chave).
  corrupt,

  /// Sem espaço no aparelho.
  storage,

  /// O capítulo não tem voz publicada, ou a fonte não está configurada.
  unavailable,
}
