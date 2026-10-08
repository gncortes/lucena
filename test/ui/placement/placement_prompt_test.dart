import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/placement/widgets/placement_prompt.dart';

/// Todas as perguntas do banco real têm enunciado e opções em todos os
/// idiomas, e todo nó do mapa tem nome: nada de texto vazio nem de chave crua
/// na tela.
void main() {
  final bank = PlacementBank.fromJson(
    jsonDecode(File('assets/placement/items.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final skills = SkillMap.fromJson(
    jsonDecode(File('assets/placement/skills.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  for (final locale in AppLocalizations.supportedLocales) {
    test('perguntas, opções e nós em $locale', () async {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final item in bank.items) {
        final prompt = placementPrompt(l10n, item);
        expect(prompt, isNotEmpty, reason: item.id);
        expect(prompt, isNot(contains('{')), reason: item.id);
        for (final option in item.options) {
          expect(
            placementOption(l10n, option),
            isNot(option),
            reason: '${item.id}: $option',
          );
        }
      }
      for (final node in skills.nodes) {
        expect(skillName(l10n, node.id), isNot(node.id), reason: node.id);
      }
    });
  }

  test('o lance do enunciado sai com as letras do idioma', () async {
    final pt = await AppLocalizations.delegate.load(const Locale('pt'));
    final item = PlacementItem.fromJson(const {
      'id': 'x',
      'node': 'notation.moves',
      'type': 'move',
      'difficulty': 500,
      'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'prompt': 'placementPlayMove',
      'params': {'side': 'white', 'move': 'Nf3'},
    });
    expect(placementPrompt(pt, item), contains('Cf3'));
  });

  test('a resposta de toda pergunta de escolha está entre as opções', () {
    for (final item in bank.items) {
      if (item.type != PlacementItemType.choice) continue;
      expect(item.options, contains(item.answer), reason: item.id);
    }
  });

  // O banco cobre o que a tela mostra: os três tipos.
  test('há perguntas de lance, de casas e de escolha', () {
    expect({
      for (final item in bank.items) item.type,
    }, PlacementItemType.values.toSet());
  });
}
