import '../../../domain/use_cases/video_turn.dart';

/// O que a tela mostra na vez do aluno (L2; gaps Vídeo 25–30). Nulo no
/// estado quando o vídeo não está numa pergunta.
class VideoTurnView {
  const VideoTurnView({
    this.movable = const [],
    this.canReveal = false,
    this.wrongSquare,
    this.rightSquare,
    this.last,
    this.inBranch = false,
    this.legacy = false,
  });

  /// As casas das peças que o aluno pode mover; vazio = qualquer peça do
  /// lado que joga (roteiro sem `pecas`).
  final List<String> movable;

  /// A pílula "Ver a resposta" aparece (a partir do 2º erro).
  final bool canReveal;

  /// A casa do ✗ do último lance errado; some no próximo lance.
  final String? wrongSquare;

  /// A casa do ✓ (destino do lance certo ou da alternativa).
  final String? rightSquare;

  /// O resultado do último lance (✓ no acerto, ✗ no erro).
  final TurnResult? last;

  /// Tocando a fala de um ramo (erro, fora, alternativa, resposta): o
  /// tabuleiro não aceita lance.
  final bool inBranch;

  /// Pergunta que o vídeo não julga (juiz ≠ lista, jogo livre, escolhas):
  /// o vídeo pausa e a vez volta ao fluxo atual da lição.
  final bool legacy;

  /// O tabuleiro do vídeo aceita lance agora.
  bool get awaitingMove => !inBranch && !legacy;

  @override
  bool operator ==(Object other) =>
      other is VideoTurnView &&
      other.canReveal == canReveal &&
      other.wrongSquare == wrongSquare &&
      other.rightSquare == rightSquare &&
      other.last == last &&
      other.inBranch == inBranch &&
      other.legacy == legacy &&
      other.movable.length == movable.length &&
      other.movable.every(movable.contains);

  @override
  int get hashCode => Object.hash(
    canReveal,
    wrongSquare,
    rightSquare,
    last,
    inBranch,
    legacy,
    movable.length,
  );
}
