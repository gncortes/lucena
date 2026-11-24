import '../models/lesson_video_progress.dart';
import 'video_timeline.dart';

/// Onde a aula em vídeo reabre e se mostra o aviso "Você parou aqui".
class VideoResumePoint {
  const VideoResumePoint({
    this.at = Duration.zero,
    this.resolved = const {},
    this.notice = false,
  });

  /// O instante em que a agulha fica, **pausada** (o aluno toca play).
  final Duration at;

  /// As perguntas já respondidas: não voltam a perguntar.
  final Set<String> resolved;

  /// Mostra "Você parou aqui. Recomeçar do início" até o aluno tocar play.
  final bool notice;

  @override
  bool operator ==(Object other) =>
      other is VideoResumePoint &&
      other.at == at &&
      other.notice == notice &&
      other.resolved.length == resolved.length &&
      other.resolved.containsAll(resolved);

  @override
  int get hashCode => Object.hash(at, notice, resolved.length);
}

/// Regras da retomada da aula em vídeo (L3; gaps Vídeo 14–16, 31).
///
/// Puro: o view model lê e grava o [VideoProgress] pelo
/// `LessonVideoRepository` e usa estas funções para converter entre o
/// instante da [VideoTimeline] e o que se guarda.
abstract final class VideoResume {
  /// Onde reabrir a partir do que foi salvo.
  ///
  /// - Nada salvo, ou a fala salva não existe mais (o roteiro mudou):
  ///   começa em 0:00, sem aviso.
  /// - Salvo: começo da fala salva (não a fração: quem volta depois de um
  ///   tempo precisa ouvir a frase inteira), limitado pela pergunta ainda
  ///   sem resposta (`reachable`), com aviso se não for 0:00.
  /// - Respostas de perguntas que não existem mais são descartadas.
  static VideoResumePoint pointFrom(
    VideoTimeline timeline,
    VideoProgress? saved,
  ) {
    if (saved == null) return const VideoResumePoint();
    final start = timeline.timeOf(saved.line, 0);
    if (start == null) return const VideoResumePoint();
    final gates = {
      for (final g in timeline.gates) timeline.lines[g.line].line.id,
    };
    final resolved = {
      for (final id in saved.resolved)
        if (gates.contains(id)) id,
    };
    final at = timeline.reachable(start, resolved);
    return VideoResumePoint(
      at: at,
      resolved: resolved,
      notice: at > Duration.zero,
    );
  }

  /// O que salvar quando a agulha está em [t] (pausa, pergunta, saída,
  /// segundo plano). Nulo = nada a guardar: ainda em 0:00 ou já no fim
  /// (no fim o view model chama `clearProgress`, decisão 2a: a etapa
  /// concluída reabre em 0:00).
  static VideoProgress? progressAt(
    VideoTimeline timeline,
    Duration t,
    Set<String> resolved,
  ) {
    if (t <= Duration.zero && resolved.isEmpty) return null;
    if (t >= timeline.total) return null;
    final anchor = timeline.anchorAt(t);
    if (anchor == null) return null;
    return VideoProgress(
      line: anchor.id,
      fraction: anchor.fraction,
      resolved: {...resolved},
    );
  }
}
