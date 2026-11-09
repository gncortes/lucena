/// Segura o conteúdo instalado enquanto a lição, o exercício ou o teste está
/// aberto. [close] ao sair.
abstract interface class ContentSession {
  Future<void> close();
}
