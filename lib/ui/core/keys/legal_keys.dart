import 'package:flutter/widgets.dart';

/// A folha dos Termos de uso e da Política de privacidade (H-AJU-14,
/// H-CON-22).
abstract final class LegalKeys {
  static const sheet = Key('legal.sheet');
  static const close = Key('legal.close');
  static const title = Key('legal.title');
  static const body = Key('legal.body');

  /// Marca o conteúdo: qual dos dois documentos está aberto.
  static const terms = Key('legal.terms');
  static const privacy = Key('legal.privacy');

  /// O título de cada seção, pelo índice (0 = "1. ...").
  static Key section(int index) => Key('legal.section.$index');
}
