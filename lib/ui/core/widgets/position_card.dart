import 'package:flutter/material.dart';

import '../motion/tabuleiro_hero.dart';
import 'goal_style.dart';
import 'position_board.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_spacing.dart';

/// Um cartão de posição numa grade (a Jornada, o catálogo): o tabuleiro na
/// largura do cartão, o selo de feito sobre ele e, embaixo, o que identifica
/// a posição ([children]).
class PositionCard extends StatelessWidget {
  const PositionCard({
    required this.fen,
    required this.onTap,
    required this.children,
    this.heroId,
    this.doneKey,
    this.doneLabel,
    super.key,
  });

  final String fen;
  final VoidCallback onTap;

  /// O que vai embaixo do tabuleiro, esticado na largura do cartão.
  final List<Widget> children;

  /// Com o id (a FEN que a tela seguinte abre), o tabuleiro voa até o
  /// [TabuleiroHero] de mesmo id (H-ANI-02).
  final String? heroId;

  /// Com a chave e o texto, o cartão ganha o selo de feito (a chave é a do
  /// ícone, para os testes; o texto é o que o leitor de tela fala).
  final Key? doneKey;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    _ComHero(
                      id: heroId,
                      child: PositionBoard(
                        fen: fen,
                        size: constraints.maxWidth,
                      ),
                    ),
                    if (doneLabel case final label?)
                      PositionedDirectional(
                        top: 4,
                        end: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            key: doneKey,
                            size: AppIconSize.large,
                            color: ChangeColors.of(context, up: true),
                            semanticLabel: label,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// O tabuleiro do cartão; com o [id], ele voa até a tela seguinte.
class _ComHero extends StatelessWidget {
  const _ComHero({required this.id, required this.child});

  final String? id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    return id == null ? child : TabuleiroHero(id: id, child: child);
  }
}
