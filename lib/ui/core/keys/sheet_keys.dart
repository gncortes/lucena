import 'package:flutter/widgets.dart';

/// Chaves da folha de baixo padrão (`showLucenaSheet`).
abstract final class SheetKeys {
  static const close = Key('sheet.close');
  static const handle = Key('sheet.handle');
  static const surface = Key('sheet.surface');
  static const header = Key('sheet.header');
  static const title = Key('sheet.title');
  static const hint = Key('sheet.hint');
}
