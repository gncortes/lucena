import 'package:flutter/widgets.dart';

/// "Seu progresso" (PropV2UxProgresso, H-CON-03).
abstract final class MyProgressKeys {
  static const screen = Key('progress.screen');
  static const loading = Key('progress.loading');
  static const rating = Key('progress.rating');
  static const ratingValue = Key('progress.rating.value');
  static const games = Key('progress.games');
  static const history = Key('progress.history');
  static const accountCard = Key('progress.accountCard');
  static const accountClose = Key('progress.accountClose');
  static const achievementsAll = Key('progress.achievementsAll');

  /// A medalha da conquista [id] na grade.
  static Key medal(String id) => Key('progress.medal.$id');
}
