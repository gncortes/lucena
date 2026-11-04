import 'package:lucena/data/repositories/legal/legal_consent_repository.dart';

/// O aceite dos Termos em memória. [failAccept]: gravar falha (erro padrão).
class FakeLegalConsentRepository implements LegalConsentRepository {
  FakeLegalConsentRepository({Set<String>? accepted, this.pendingUid})
    : acceptedUids = {...?accepted};

  final Set<String> acceptedUids;
  String? pendingUid;
  bool failAccept = false;

  @override
  Future<bool> accepted(String uid) async => acceptedUids.contains(uid);

  @override
  Future<void> markPending(String uid) async => pendingUid = uid;

  @override
  Future<String?> pending() async =>
      pendingUid == null || acceptedUids.contains(pendingUid)
      ? null
      : pendingUid;

  @override
  Future<void> accept(String uid) async {
    if (failAccept) throw StateError('falha ao gravar o aceite');
    acceptedUids.add(uid);
    pendingUid = null;
  }
}
