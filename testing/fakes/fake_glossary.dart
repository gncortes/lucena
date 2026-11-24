import 'package:lucena/data/repositories/glossary/glossary_repository.dart';
import 'package:lucena/domain/models/glossary_term.dart';

/// Termos de exemplo, no formato do asset.
const fakeGlossaryTerms = [
  GlossaryTerm(
    id: 'oposicao',
    name: 'Oposição',
    definition: 'Reis na mesma coluna com casas vazias entre eles.',
    wikiKey: 'pt:Oposição_(xadrez)',
  ),
  GlossaryTerm(
    id: 'ponte',
    name: 'Ponte',
    definition: 'A torre se põe entre o rei e a torre adversária.',
  ),
  GlossaryTerm(
    id: 'zugzwang',
    name: 'Zugzwang',
    definition: 'Qualquer lance piora a situação de quem joga.',
    wikiKey: 'pt:Zugzwang',
  ),
];

/// Um Glossário em memória.
class FakeGlossaryRepository implements GlossaryRepository {
  FakeGlossaryRepository([this.list = fakeGlossaryTerms]);

  final List<GlossaryTerm> list;

  @override
  Future<List<GlossaryTerm>> terms() async => list;
}

/// A conexão que o teste manda.
class FakeConnectivityRepository implements ConnectivityRepository {
  FakeConnectivityRepository({this.online = true});

  bool online;
  var checks = 0;

  @override
  Future<bool> isOnline() async {
    checks++;
    return online;
  }
}
