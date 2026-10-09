import 'package:flutter/material.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../keys/pace_keys.dart';
import '../l10n/l10n.dart';
import '../theme/app_shape.dart';

/// O nome de cada categoria de ritmo.
extension PaceCategoryUi on PaceCategory {
  String label(AppLocalizations l10n) => switch (this) {
    PaceCategory.ultraBullet => l10n.paceUltraBullet,
    PaceCategory.bullet => l10n.paceBullet,
    PaceCategory.blitz => l10n.paceBlitz,
    PaceCategory.rapid => l10n.paceRapid,
    PaceCategory.classical => l10n.paceClassical,
  };
}

/// O ritmo curto, em minutos e incremento (`3+2`); abaixo de um minuto, em
/// segundos (`30 s`).
String paceShort(AppLocalizations l10n, TimeControl time) =>
    time.initial < const Duration(minutes: 1)
    ? l10n.paceSeconds(time.initial.inSeconds)
    : l10n.paceShort(time.initial.inMinutes, time.increment.inSeconds);

/// O ritmo com a categoria (`3+2 · Blitz`).
String paceLabel(AppLocalizations l10n, TimeControl time) =>
    l10n.paceChip(paceShort(l10n, time), PaceCategory.of(time).label(l10n));

/// A escolha feita no painel de ritmo: um tempo, ou nenhum (sem relógio).
class PaceChoice {
  const PaceChoice(this.time);

  /// Nulo: sem relógio.
  final TimeControl? time;
}

/// Abre o painel com os ritmos em grade, agrupados como no chess.com (ultra
/// bullet, bullet, blitz, rápido) e, com [allowNoClock], a opção sem relógio. Tocar só marca;
/// a escolha vale ao confirmar. Nulo se o painel for fechado sem confirmar.
Future<PaceChoice?> showPaceSheet(
  BuildContext context, {
  required TimeControl? current,
  bool allowNoClock = false,
}) {
  return showModalBottomSheet<PaceChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _PaceSheet(current: current, allowNoClock: allowNoClock),
  );
}

class _PaceSheet extends StatefulWidget {
  const _PaceSheet({required this.current, required this.allowNoClock});

  final TimeControl? current;
  final bool allowNoClock;

  @override
  State<_PaceSheet> createState() => _PaceSheetState();
}

class _PaceSheetState extends State<_PaceSheet> {
  late TimeControl? _selected = widget.allowNoClock
      ? widget.current
      : widget.current ?? SpeedrunPaces.standard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: PaceKeys.sheet,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.paceTitle, style: theme.textTheme.titleLarge),
            for (final MapEntry(key: category, value: times)
                in SpeedrunPaces.groups.entries) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _icon(category),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.label(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Grid(
                children: [
                  for (final time in times)
                    _Option(
                      key: PaceKeys.option(time.code),
                      label: paceShort(l10n, time),
                      selected: _selected == time,
                      onTap: () => setState(() => _selected = time),
                    ),
                ],
              ),
            ],
            if (widget.allowNoClock) ...[
              const SizedBox(height: 16),
              _Option(
                key: PaceKeys.noClock,
                label: l10n.challengeNoClock,
                icon: Icons.timer_off_outlined,
                selected: _selected == null,
                onTap: () => setState(() => _selected = null),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: PaceKeys.confirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.of(context).pop(PaceChoice(_selected)),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _icon(PaceCategory category) => paceIcon(category);
}

/// O ícone de cada categoria de ritmo.
IconData paceIcon(PaceCategory category) => switch (category) {
  PaceCategory.ultraBullet => Icons.rocket_launch_outlined,
  PaceCategory.bullet => Icons.bolt,
  PaceCategory.blitz => Icons.local_fire_department_outlined,
  _ => Icons.av_timer_outlined,
};

/// Três opções por linha.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.medium),
        side: BorderSide(
          color: selected ? colors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShape.medium),
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon case final icon?) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? colors.onPrimaryContainer : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
