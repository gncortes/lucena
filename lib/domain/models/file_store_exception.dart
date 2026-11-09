/// O Storage não respondeu (sem rede, sem permissão, arquivo grande demais).
class FileStoreException implements Exception {
  const FileStoreException(this.code);

  final String code;

  @override
  String toString() => 'FileStoreException($code)';
}
