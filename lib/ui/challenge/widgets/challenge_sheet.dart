import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/share/share_repository.dart';
import '../../../domain/models/challenge_link.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/challenge_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import '../view_models/challenge_sheet_cubit.dart';

/// Abre a folha "Mandar como desafio" (canvas `PropV1LinkCriar`) para [link].
Future<void> showChallengeSheet(
  BuildContext context, {
  required ChallengeLink link,
  List<Character> characters = const [],
}) {
  final share = context.read<ShareRepository>();
  final analytics = context.analytics;
  return showLucenaSheet<void>(
    context,
    sheetKey: ChallengeKeys.sheet,
    builder: (context) => BlocProvider(
      create: (_) =>
          ChallengeSheetCubit(share, link: link, analytics: analytics)..load(),
      child: ChallengeSheet(characters: characters),
    ),
  );
}

/// O resumo do desafio, a trava e o link, com Compartilhar e Copiar link.
class ChallengeSheet extends StatelessWidget {
  const ChallengeSheet({this.characters = const [], super.key});

  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ChallengeSheetCubit>().state;
    final cubit = context.read<ChallengeSheetCubit>();
    final link = state.link;
    final text = l10n.challengeShareText(link.uri.toString());
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: l10n.challengeSendTitle,
            hint: l10n.challengeSendHint,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ChallengeSummary(link: link, characters: characters),
          ),
          SwitchListTile(
            key: ChallengeKeys.lockSwitch,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
            ),
            secondary: const Icon(Icons.lock_outline),
            title: Text(l10n.challengeLockTitle),
            subtitle: Text(l10n.challengeLockHint),
            value: link.locked,
            onChanged: (value) => cubit.setLocked(locked: value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _LinkField(link: link),
          ),
          const SizedBox(height: AppSpacing.lg),
          ActionsFooter(
            margin: AppSpacing.xl,
            stacked: true,
            children: [
              FilledButton.icon(
                key: ChallengeKeys.share,
                onPressed: state.sharing ? null : () => cubit.share(text),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.challengeShare),
              ),
              OutlinedButton.icon(
                key: ChallengeKeys.copy,
                onPressed: () => _copy(context, link),
                icon: const Icon(Icons.content_copy),
                label: Text(l10n.challengeCopyLink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Copiar de dentro da folha também conta o `link_copiado`.
void _copy(BuildContext context, ChallengeLink link) {
  unawaited(context.read<ChallengeSheetCubit>().copied());
  unawaited(copyChallengeLink(context, link));
}

/// Copia o endereço de [link] e avisa. O aviso usa a camada de cima do app: o
/// `SnackBar` cairia no `Scaffold` que fica debaixo da folha modal.
Future<void> copyChallengeLink(BuildContext context, ChallengeLink link) async {
  final l10n = context.l10n;
  await Clipboard.setData(ClipboardData(text: link.uri.toString()));
  if (!context.mounted) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  final colors = Theme.of(context).colorScheme;
  final textStyle = Theme.of(context).textTheme.bodyMedium
      ?.copyWith(color: colors.onInverseSurface);
  final bottom = MediaQuery.paddingOf(context).bottom;
  final text = l10n.challengeLinkCopied;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.lg + bottom,
      child: Material(
        key: CoreKeys.snackBar,
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(AppShape.small),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              Icon(
                Icons.check,
                size: AppIconSize.button,
                color: colors.onInverseSurface,
              ),
              Expanded(child: Text(text, style: textStyle)),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  unawaited(
    Future<void>.delayed(AppMotion.snackBar, () {
      if (entry.mounted) entry.remove();
    }),
  );
}

/// O nome do desafio: o objetivo com as peças de quem joga ("Ganhar com rei e
/// dama"), tiradas da posição.
String challengeTitle(AppLocalizations l10n, ChallengeLink link) {
  final board = GameRules.fromFen(link.fen)?.board;
  final goal = goalLabel(l10n, link.goal);
  if (board == null) return goal;
  final side = board.bySide(link.userSide);
  final names = <String>[
    for (final (role, name) in [
      (Role.king, l10n.pieceKing),
      (Role.queen, l10n.pieceQueen),
      (Role.rook, l10n.pieceRook),
      (Role.bishop, l10n.pieceBishop),
      (Role.knight, l10n.pieceKnight),
      (Role.pawn, l10n.piecePawn),
    ])
      if (board.byRole(role).intersect(side).isNotEmpty) name.toLowerCase(),
  ];
  if (names.length < 2) return goal;
  final pieces = names.length == 2
      ? l10n.challengeAnd(names.first, names.last)
      : l10n.challengeAnd(
          names.sublist(0, names.length - 1).join(', '),
          names.last,
        );
  return l10n.challengeSummaryTitle(goal, pieces);
}

/// O cartão do desafio: a miniatura, o objetivo, o adversário com o relógio e
/// o lado com o modo.
class ChallengeSummary extends StatelessWidget {
  const ChallengeSummary({
    required this.link,
    this.characters = const [],
    super.key,
  });

  final ChallengeLink link;
  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final level = link.level;
    final character = level == null ? null : characters.forLevel(level);
    final opponent = link.opponent == OpponentKind.stockfish
        ? l10n.setupOpponentStockfish
        : character != null && level != null
        ? l10n.characterNameLevel(character.name, level)
        : l10n.opponentMaiaLevel(level ?? 0);
    final clock = link.clock;
    final side = link.userSide == Side.white
        ? l10n.challengeSideWhite
        : l10n.challengeSideBlack;
    final mode = l10n.setupModeNormal;
    return DecoratedBox(
      key: ChallengeKeys.summary,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.lg,
          children: [
            PositionBoard(fen: link.fen, size: 88, orientation: link.userSide),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    challengeTitle(l10n, link),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.challengeSummaryOpponent(
                      opponent,
                      clock == null
                          ? l10n.challengeNoClock
                          : paceShort(l10n, clock),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.challengeSummarySide(side, mode),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O endereço curto do desafio (`playlucena.com/p/k7Qe2`); tocar copia.
class _LinkField extends StatelessWidget {
  const _LinkField({required this.link});

  final ChallengeLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: ChallengeKeys.linkField,
      borderRadius: BorderRadius.circular(AppShape.large),
      onTap: () => _copy(context, link),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Icon(
              Icons.link,
              size: AppIconSize.button,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Expanded(
              child: Text(
                link.shortAddress,
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.content_copy,
              size: AppIconSize.button,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
