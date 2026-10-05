import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../routing/routes.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/pace/pace_ui.dart';
import '../../settings/view_models/settings_cubit.dart';

/// O nome de um adversário de desafio ou degrau (`Maia 1000`, `Stockfish`).
String opponentRefLabel(AppLocalizations l10n, OpponentRef opponent) =>
    opponent.kind.label(l10n, level: opponent.level);

/// O personagem de um adversário da Jornada: o do nível do Maia ou o logo do
/// Stockfish. Nulo se o personagem do nível não foi lido.
Character? opponentCharacter(
  List<Character> characters,
  OpponentRef opponent,
) => opponent.kind == OpponentKind.stockfish
    ? Character.stockfish
    : characters.forLevel(opponent.level);

/// O nome do adversário para o jogador: o do personagem (`Coco`) ou, sem ele,
/// o do motor (`Maia 1000`).
String opponentName(
  AppLocalizations l10n,
  List<Character> characters,
  OpponentRef opponent,
) =>
    opponentCharacter(characters, opponent)?.name ??
    opponentRefLabel(l10n, opponent);

/// Joga o desafio: abre o painel do ritmo (com "sem relógio"), grava a
/// escolha e abre a partida nesse ritmo. Falso se o painel foi fechado sem
/// confirmar.
Future<bool> playChallenge(BuildContext context, Challenge challenge) async {
  final settings = context.read<SettingsCubit>();
  final clock = settings.state?.clock ?? const ClockSettings();
  final choice = await showPaceSheet(
    context,
    current: clock.journeyTime,
    allowNoClock: true,
  );
  if (choice == null || !context.mounted) return false;
  await settings.setClock(clock.copyWith(journeyTime: choice.time));
  if (!context.mounted) return false;
  await context.push(
    Routes.challengeGame(challenge.copyWith(time: choice.time)),
  );
  return true;
}

/// A marca do retrato do adversário que voa da trilha para a tela dele.
String opponentHeroTag(String rungId) => 'journey.opponent.$rungId';

/// A marca do tabuleiro de um desafio, que voa da tela do adversário para a
/// do desafio, crescendo até a largura da tela.
String challengeBoardTag(String challengeId) => 'journey.board.$challengeId';
