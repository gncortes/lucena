import '../models/lesson.dart';

/// O texto que o app mostra para cada lance de um ramo do modo variante
/// (T70, "Texto por lance"). Dart puro.
///
/// - Lance do aluno (ply 1): a fala do erro (`mistakes[uci].say`), depois
///   `alt.<id>.m1`, depois o texto neutro [fallback] (sem citar lance).
/// - Demais plies: a fala do lance da demonstração errada (`<demo>.m<n-1>`:
///   a demo de erro começa na resposta das pretas, então o ply 2 é o m1),
///   depois `alt.<id>.m<n>`, senão nulo (só a faixa). Nunca o `pt` da linha,
///   que cita a variante inteira.
abstract final class BranchComments {
  static String? at({
    required LessonTexts texts,
    required String lessonId,
    required int ply,
    String? mistakeSay,
    String? demoId,
    String? altStepId,
    String? altId,
    String? fallback,
  }) {
    String? alternative() => altStepId == null || altId == null
        ? null
        : texts.alternative(lessonId, altStepId, altId, ply);
    String? demo() =>
        demoId == null ? null : texts.demoMove(lessonId, demoId, ply - 1);
    if (ply <= 1) {
      return mistakeSay ?? alternative() ?? fallback;
    }
    return demo() ?? alternative();
  }
}
