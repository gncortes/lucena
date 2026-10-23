import 'package:flutter/widgets.dart';

/// "Seu país" e a folha de estado e cidade (E1.21).
abstract final class RegionKeys {
  static const sheet = Key('region.sheet');
  static const state = Key('region.state');
  static const city = Key('region.city');
  static const save = Key('region.save');
  static const notNow = Key('region.notNow');
  static const countryScreen = Key('region.countryScreen');
  static const countrySearch = Key('region.countrySearch');
  static const countryNotFound = Key('region.countryNotFound');
  static Key countryOption(String code) => Key('region.country.$code');
}
