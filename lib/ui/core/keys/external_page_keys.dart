import 'package:flutter/widgets.dart';

/// A folha que abre uma página da web dentro do app (Wikipedia, Lichess).
abstract final class ExternalPageKeys {
  static const sheet = Key('externalPage.sheet');
  static const title = Key('externalPage.title');
  static const close = Key('externalPage.close');
  static const page = Key('externalPage.page');
  static const loading = Key('externalPage.loading');
  static const offline = Key('externalPage.offline');
}
