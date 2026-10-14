import '../models/lesson_script.dart';

/// Diz se os balões em [texts] cabem juntos na área da fala. Quem sabe é a
/// tela (ela mede); o Cubit só pergunta.
typedef SpeechFits = bool Function(List<String> texts);

/// Junta passos curtos que aparecem no mesmo balão (T70).
abstract final class GroupSpeech {
  /// Onde termina (exclusivo) o trecho que começa em [start]: junta os passos
  /// seguintes que não jogam lance (`lance`/`seq`/`salto`), têm a mesma
  /// posição e cujos textos ainda cabem. Sem [fits], cada passo é um trecho.
  /// O trecho mostra as marcas e setas do último passo.
  static int end(
    List<ScriptStep> steps,
    int start,
    String Function(String key) say,
    SpeechFits? fits,
  ) {
    var end = start + 1;
    if (fits == null) return end;
    final head = steps[start];
    final texts = [say(head.t)];
    while (end < steps.length) {
      final next = steps[end];
      if (next.hasMove || next.jump || next.fen != head.fen) break;
      final candidate = [...texts, say(next.t)];
      if (!fits(candidate)) break;
      texts.add(say(next.t));
      end++;
    }
    return end;
  }

  /// Os trechos de [steps] desde o começo, como pares (início, fim).
  static List<(int, int)> groups(
    List<ScriptStep> steps,
    String Function(String key) say,
    SpeechFits? fits,
  ) {
    final out = <(int, int)>[];
    var start = 0;
    while (start < steps.length) {
      final stop = end(steps, start, say, fits);
      out.add((start, stop));
      start = stop;
    }
    return out;
  }
}
