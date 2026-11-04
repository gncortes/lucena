import 'package:flutter/material.dart';

import '../keys/core_keys.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import 'lucena_app_bar.dart';
import 'skeleton.dart';

/// Um bloco do esqueleto no desenho da tela (canvas `CompEsqueleto`).
class SkeletonShape {
  /// Bloco com medidas próprias (canvas dos carregamentos do Início).
  const SkeletonShape.block({
    this.width = double.infinity,
    required this.height,
    this.radius = AppShape.large,
  });

  /// Cartão na largura toda, raio 16.
  const SkeletonShape.card(this.height)
    : width = double.infinity,
      radius = AppShape.large;

  /// Linha de texto: 16 de altura, raio 8.
  const SkeletonShape.line(this.width) : height = 16, radius = AppShape.small;

  final double width;
  final double height;
  final double radius;
}

/// O primeiro carregamento de uma tela (T85-D0): a app bar já com o título e
/// o esqueleto com brilho no lugar do conteúdo. Sem [blocks], a lista padrão.
class LoadSkeletonScreen extends StatelessWidget {
  const LoadSkeletonScreen({this.title, this.blocks = const [], super.key});

  final String? title;
  final List<SkeletonShape> blocks;

  @override
  Widget build(BuildContext context) {
    final body = blocks.isEmpty ? const SkeletonList() : SkeletonBody(blocks);
    return Scaffold(
      appBar: title == null ? null : LucenaAppBar(title: Text(title!)),
      body: SafeArea(child: body),
    );
  }
}

/// Os [blocks] com brilho, parados, no corpo de uma tela que carrega. Telas
/// com rodapé próprio (Sua semana) usam isto no lugar de [LoadSkeletonScreen].
class SkeletonBody extends StatelessWidget {
  const SkeletonBody(this.blocks, {super.key});

  final List<SkeletonShape> blocks;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: CoreKeys.skeleton,
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          for (final (i, b) in blocks.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SkeletonBlock(
                key: CoreKeys.skeletonBlock,
                width: b.width,
                height: b.height,
                radius: b.radius,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
