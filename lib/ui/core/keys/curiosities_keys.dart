import 'package:flutter/widgets.dart';

/// A folha Curiosidades da lição roteirizada (T70).
abstract final class CuriositiesKeys {
  static const sheet = Key('curiosities.sheet');
  static const title = Key('curiosities.title');
  static const close = Key('curiosities.close');
  static const about = Key('curiosities.about');
  static const quote = Key('curiosities.quote');
  static const references = Key('curiosities.references');

  static Key reference(String id) => Key('curiosities.reference.$id');
  static Key playerAvatar(String id) => Key('curiosities.player.$id');
  static Key source(String id) => Key('curiosities.source.$id');
}
