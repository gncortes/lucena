import '../../../domain/models/app_links.dart';
import '../../../domain/models/challenge_link.dart';
import '../../services/deep_link_service.dart';

/// Os desafios que chegam por link.
abstract class DeepLinkRepository {
  /// O desafio que abriu o app, se foi um link de desafio.
  Future<ChallengeLink?> initial();

  /// Os desafios que chegam com o app aberto.
  Stream<ChallengeLink> get opened;

  /// Lê [uri] como desafio (a tela de depuração e os testes usam o mesmo
  /// caminho do sistema). Nulo se não for um link do app ou for inválido.
  ChallengeLink? parse(Uri uri);
}

/// Lê os endereços do [DeepLinkService] e deixa passar só os do app.
class ServiceDeepLinkRepository implements DeepLinkRepository {
  const ServiceDeepLinkRepository(this._service);

  final DeepLinkService _service;

  @override
  ChallengeLink? parse(Uri uri) =>
      AppLinks.isOwn(uri) ? ChallengeLink.tryParse(uri) : null;

  @override
  Future<ChallengeLink?> initial() async {
    final uri = await _service.initialUri();
    return uri == null ? null : parse(uri);
  }

  @override
  Stream<ChallengeLink> get opened =>
      _service.uris.map(parse).where((link) => link != null).cast();
}
