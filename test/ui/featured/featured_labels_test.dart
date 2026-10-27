import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/featured/widgets/featured_labels.dart';

import '../../../testing/fakes/fake_featured_repositories.dart';

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final endgame = sampleFeaturedCatalog().finals.first;

  test('o ano entra depois do nome do evento', () {
    final tournament = FeaturedTournament(
      id: 't',
      name: 'Torneio Antigo',
      year: 1959,
    );
    expect(
      FeaturedLabels.eventYear(pt, 'pt', endgame, tournament),
      'Torneio Antigo 1959',
    );
  });

  test('o ano não se repete quando o nome já o traz', () {
    final tournament = FeaturedTournament(
      id: 't',
      name: 'Norway Chess 2017',
      year: 2017,
    );
    expect(
      FeaturedLabels.eventYear(pt, 'pt', endgame, tournament),
      'Norway Chess 2017',
    );
  });
}
