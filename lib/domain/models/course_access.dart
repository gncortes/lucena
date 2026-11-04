/// O que a pessoa tem do curso Pilares (T85-D1, H-LIC-14). Só o comprador
/// abre o curso inteiro sem anúncio; a assinatura vencida volta a valer como
/// demonstração (H-VEN-16 grava o estado de verdade).
enum CourseAccess {
  demo,
  owned,
  subscriptionEnded;

  /// Comprou e ainda tem o curso: todos os capítulos abertos, sem anúncio.
  bool get hasFullCourse => this == owned;

  /// Demonstração e assinatura vencida veem o anúncio ao entrar na lição.
  bool get seesAds => !hasFullCourse;
}
