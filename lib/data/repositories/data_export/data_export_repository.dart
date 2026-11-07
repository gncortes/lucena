/// "Baixar meus dados" (H-CON-21, LGPD art. 18 e 19): uma cópia dos dados
/// da conta num arquivo JSON legível.
abstract class DataExportRepository {
  /// Junta os dados da conta [uid] num arquivo e devolve o caminho dele. O
  /// arquivo só aparece inteiro: nunca fica um parcial. Falha com
  /// [DataExportException] (sem internet, sem espaço).
  Future<String> download(String uid);

  /// Abre o arquivo pronto no aparelho (o menu do sistema: abrir ou salvar).
  Future<bool> open(String path);

  /// Apaga o arquivo (a pessoa cancelou enquanto baixava).
  Future<void> discard(String path);
}

class DataExportException implements Exception {
  const DataExportException(this.cause);

  final Object cause;

  @override
  String toString() => 'DataExportException($cause)';
}

/// Sem Firebase (F-Droid) não há conta nem dados na nuvem.
class NoDataExportRepository implements DataExportRepository {
  const NoDataExportRepository();

  @override
  Future<String> download(String uid) =>
      Future.error(const DataExportException('sem nuvem'));

  @override
  Future<bool> open(String path) async => false;

  @override
  Future<void> discard(String path) async {}
}
