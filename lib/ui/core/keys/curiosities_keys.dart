import 'package:flutter/widgets.dart';

/// A folha Curiosidades da lição roteirizada (T70).
abstract final class CuriositiesKeys {
  static const sheet = Key('curiosities.sheet');
  static const close = Key('curiosities.close');
  static const about = Key('curiosities.about');
  static const quote = Key('curiosities.quote');
  static const references = Key('curiosities.references');

  static Key reference(String id) => Key('curiosities.reference.$id');
}
