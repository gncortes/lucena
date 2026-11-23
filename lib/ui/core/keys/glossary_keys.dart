import 'package:flutter/widgets.dart';

/// O Glossário (tela própria, aberta de qualquer lugar) e a folha do termo.
abstract final class GlossaryKeys {
  static const screen = Key('glossary.screen');
  static const back = Key('glossary.back');
  static const search = Key('glossary.search');
  static const searchClear = Key('glossary.searchClear');
  static const count = Key('glossary.count');
  static Key term(String id) => Key('glossary.term.$id');
  static const sheet = Key('glossary.sheet');
  static const sheetClose = Key('glossary.sheetClose');
  static const wiki = Key('glossary.wiki');
  static const offline = Key('glossary.offline');
  static const empty = Key('glossary.empty');
}
