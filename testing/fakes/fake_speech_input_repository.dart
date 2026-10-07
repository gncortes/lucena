import 'dart:async';

import 'package:lucena/data/repositories/blind/speech_input_repository.dart';

/// O reconhecedor sem microfone: o teste diz o que "ouviu" com [hear].
class FakeSpeechInputRepository implements SpeechInputRepository {
  FakeSpeechInputRepository({this.permitted = true, this.grants = true});

  /// O microfone já liberado.
  bool permitted;

  /// O que o jogador responde ao pedido do microfone.
  bool grants;
  final _events = StreamController<SpeechInputEvent>.broadcast();

  /// As escutas pedidas: o idioma e se foi só no aparelho.
  final listens = <(String, bool)>[];
  var stops = 0;
  var cancels = 0;
  var requests = 0;

  bool get listening => _listening;
  bool _listening = false;

  /// O reconhecedor "ouviu" [alternatives] (resultado final da frase).
  void hear(List<String> alternatives) {
    _events.add(SpeechHeard(alternatives, isFinal: true));
  }

  void emit(SpeechInputEvent event) => _events.add(event);

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return permitted = permitted || grants;
  }

  @override
  Future<void> listen(String languageTag, {required bool onDevice}) async {
    listens.add((languageTag, onDevice));
    _listening = true;
  }

  /// Parar avisa o fim na hora. Falso: como no aparelho, o resultado final
  /// chega depois de parar, e o teste manda o [hear] e o [emit] do fim.
  bool stopEndsAtOnce = true;

  @override
  Future<void> stop() async {
    stops++;
    _listening = false;
    if (stopEndsAtOnce) _events.add(const SpeechStopped());
  }

  @override
  Future<void> cancel() async {
    cancels++;
    _listening = false;
  }

  @override
  Stream<SpeechInputEvent> get events => _events.stream;
}
