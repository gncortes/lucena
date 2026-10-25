/// A contagem de aparelhos por tópico (`inscritos/<topico>` no Firestore),
/// que dá o "Alcance estimado" do painel (E1.19 3.8): o FCM não diz o
/// tamanho de um tópico.
///
/// Pendente: o `firebase/firestore.rules` ainda não tem `inscritos/*` nem a
/// Function que guarda a contagem (P4). Até lá o app usa
/// [NoTopicCountService] e não conta nada.
abstract class TopicCountService {
  /// O aparelho entrou ([delta] 1) ou saiu ([delta] -1) de [topic].
  Future<void> changed(String topic, int delta);
}

class NoTopicCountService implements TopicCountService {
  const NoTopicCountService();

  @override
  Future<void> changed(String topic, int delta) async {}
}
