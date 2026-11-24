/// O que tira a aula em vídeo do ar (gaps Vídeo 14 e 39). Para qualquer um
/// deles o view model pausa e salva o progresso; **nunca volta a tocar
/// sozinho** (o aluno toca play).
enum VideoInterruption {
  /// O app saiu da tela (outro app, tela bloqueada, ir para a home).
  background,

  /// O app perdeu o foco por um instante (ligação, painel de notificações).
  inactive,

  /// Outro app pegou o áudio (ligação, música, vídeo).
  audioFocus,

  /// O fone foi desconectado.
  noisy,
}

/// Junta num só fluxo tudo o que pausa a aula em vídeo.
///
/// O view model assina [interruptions] ao abrir e cancela no `close`.
abstract interface class VideoInterruptionsRepository {
  Stream<VideoInterruption> get interruptions;
}
