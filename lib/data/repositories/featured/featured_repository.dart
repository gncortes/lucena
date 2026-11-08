import '../../../domain/models/featured.dart';

/// Os finais em destaque e os torneios de onde saem. A fonte hoje é um arquivo
/// do app; com o Firestore (E1.02) ela passa a ser a nuvem com cache local,
/// sem mudar quem usa isto.
abstract class FeaturedRepository {
  /// Tudo de uma vez. Sem a fonte (ou quebrada), lança: quem usa decide o que
  /// mostrar (a lista mostra o erro padrão; a tela inicial, nada).
  Future<FeaturedCatalog> catalog();
}
