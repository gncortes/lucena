import 'package:flutter/widgets.dart';

/// A página da Wikipedia de um nome sublinhado numa fala.
abstract final class WikiKeys {
  static const sheet = Key('wiki.sheet');
  static const close = Key('wiki.close');
  static const page = Key('wiki.page');
  static const loading = Key('wiki.loading');
  static const offline = Key('wiki.offline');

  /// O texto com os nomes sublinhados fora do balão (a história da aula).
  static Key text(String id) => Key('wiki.text.$id');
}
