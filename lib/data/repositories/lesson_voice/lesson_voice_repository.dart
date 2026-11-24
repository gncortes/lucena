import '../../../domain/models/lesson_video.dart';
import '../../../domain/models/lesson_voice.dart';

export '../../../domain/models/lesson_voice.dart';

/// A voz gravada do Viktor na aula em vídeo: o pacote de áudio de cada
/// capítulo (baixado junto com ele, ou depois por "Baixar a voz") e a
/// preferência de voz ligada/desligada.
abstract interface class LessonVoiceRepository {
  /// O estado da voz do capítulo agora.
  Future<VoicePackState> state(String chapterId);

  /// O estado atual e cada mudança (baixando, pronto, falhou).
  Stream<VoicePackState> watch(String chapterId);

  /// Baixa o que falta ("Baixar a voz" e "Tentar de novo"). Não lança: a
  /// falha volta como [VoicePackFailed], e o que já foi conferido fica.
  Future<VoicePackState> download(String chapterId);

  /// O arquivo no aparelho do áudio [audioPath] de uma fala do capítulo;
  /// nulo sem o pacote completo ou sem o arquivo.
  Future<String?> audioFile(String chapterId, String audioPath);

  /// Os tempos de cada fala do capítulo baixado, pela chave do áudio; vazio
  /// sem o pacote completo.
  Future<Map<String, VoiceClip>> clips(String chapterId);

  /// A voz do Viktor ligada na aula em vídeo (padrão: ligada). Desligada, a
  /// aula toca em modo leitura, sem o aviso "Sem áudio".
  Future<bool> voiceOn();

  Future<void> setVoiceOn({required bool on});
}
