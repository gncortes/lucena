import '../../../domain/models/glossary_term.dart';
import '../../services/connectivity_service.dart';

/// Os termos do Glossário, em ordem alfabética.
abstract class GlossaryRepository {
  /// Sem o arquivo (ou com ele quebrado), lista vazia.
  Future<List<GlossaryTerm>> terms();
}

/// Sem Glossário (composição que não o usa).
class EmptyGlossaryRepository implements GlossaryRepository {
  const EmptyGlossaryRepository();

  @override
  Future<List<GlossaryTerm>> terms() async => const [];
}

/// Se dá para abrir uma página da web agora (a Wikipédia do termo).
abstract class ConnectivityRepository {
  Future<bool> isOnline();
}

/// A conexão do aparelho ([ConnectivityService]).
class DeviceConnectivityRepository implements ConnectivityRepository {
  const DeviceConnectivityRepository([
    this._service = const ConnectivityService(),
  ]);

  final ConnectivityService _service;

  @override
  Future<bool> isOnline() => _service.isOnline();
}
