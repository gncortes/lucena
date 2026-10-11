import '../../../domain/models/wiki_links.dart';

/// As páginas da Wikipedia dos nomes marcados nas falas das aulas.
abstract class WikiLinksRepository {
  /// O mapa inteiro. Sem o arquivo (ou com ele quebrado), vazio: os nomes
  /// ficam como texto normal.
  Future<WikiLinks> links();
}
