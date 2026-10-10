import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';

/// A conta do tabuleiro centralizado na vertical (T64): o centro dele fica
/// no centro do espaço útil, entre o fim da barra do app (o topo da área) e
/// o rodapé ([footer], a barra de botões de baixo; sem rodapé, o fim da área
/// segura). O que vem em cima e embaixo fica com o espaço que sobra de cada
/// lado: o tabuleiro não sai do centro por causa deles.
///
/// O tamanho do tabuleiro é o maior que cabe na largura (menos [gutter] de
/// cada lado) e na altura, deixando de cada lado pelo menos [reserveTop] e
/// [reserveBottom] (mais [gap]). Como o centro é fixo, o lado que pede mais
/// espaço manda nos dois. Uma reserva grande demais não encolhe o tabuleiro
/// abaixo de [minFraction] do maior tamanho: o que está em cima ou embaixo é
/// que encolhe (rola ou diminui) para caber.
class BoardCentering {
  BoardCentering(
    this.area, {
    this.footer = 0,
    double? centerY,
    this.gap = AppSpacing.sm,
    this.gutter = 0,
    this.reserveTop = 0,
    this.reserveBottom = 0,
    this.minFraction = 0.6,
    this.maxBoard = double.infinity,
  }) : centerY = centerY ?? max(0.0, area.height - footer) / 2;

  /// A área toda, do fim da barra do app ao fim da área segura.
  final Size area;

  /// A altura do rodapé, colado embaixo da área.
  final double footer;

  /// Onde fica o centro do tabuleiro, nas coordenadas da área.
  final double centerY;

  /// Entre o tabuleiro e o que vem em cima ou embaixo.
  final double gap;

  /// A margem mínima do tabuleiro até as bordas da área.
  final double gutter;

  /// O espaço que se quer garantir em cima e embaixo do tabuleiro.
  final double reserveTop;
  final double reserveBottom;

  /// O menor tabuleiro, em fração do maior que cabe.
  final double minFraction;

  /// O maior tabuleiro, se houver limite.
  final double maxBoard;

  /// A altura útil: a área sem o rodapé.
  double get useful => max(0.0, area.height - footer);

  double get _above => centerY.clamp(0.0, useful).toDouble();
  double get _below => max(0.0, useful - centerY);

  /// O maior tabuleiro que cabe com o centro em [centerY].
  double get maxSide => max(
    0.0,
    min(
      min(area.width - 2 * gutter, maxBoard),
      2 * min(_above, _below) - 2 * gutter,
    ),
  );

  /// O menor tabuleiro: abaixo disso, quem encolhe é o resto.
  double get minSide => maxSide * minFraction;

  /// O máximo que o que vem em cima pode ocupar, com o menor tabuleiro.
  double get maxRoomAbove => max(0.0, _above - minSide / 2 - gap);

  /// O máximo que o que vem embaixo pode ocupar, com o menor tabuleiro.
  double get maxRoomBelow => max(0.0, _below - minSide / 2 - gap);

  /// O lado do tabuleiro.
  double get side {
    final top = min(reserveTop, maxRoomAbove);
    final bottom = min(reserveBottom, maxRoomBelow);
    final fromTop = 2 * (_above - (top > 0 ? top + gap : gutter));
    final fromBottom = 2 * (_below - (bottom > 0 ? bottom + gap : gutter));
    return min(fromTop, fromBottom).clamp(minSide, maxSide).toDouble();
  }

  /// Onde fica o tabuleiro.
  Rect get board {
    final s = side;
    return Rect.fromLTWH((area.width - s) / 2, centerY - s / 2, s, s);
  }

  /// O espaço que sobra em cima do tabuleiro (até ele, menos [gap]).
  double get roomAbove => max(0.0, board.top - gap);

  /// O espaço que sobra embaixo dele (até o rodapé, menos [gap]).
  double get roomBelow => max(0.0, useful - board.bottom - gap);
}

enum _Slot { top, board, bottom, footer }

/// O tabuleiro com o centro no centro do espaço útil (ver [BoardCentering]),
/// [top] em cima dele, [bottom] embaixo e [footer] colado no fim da área.
/// [top] e [bottom] ficam com o espaço que sobra de cada lado: se não
/// couberem, diminuem ([ShrinkToFit]) em vez de empurrar o tabuleiro. Com
/// [shrinkSides] desligado, eles recebem a altura máxima e se viram (rolam).
///
/// [board] recebe o tamanho exato: um `LayoutBuilder` lê o lado.
class CenteredBoardLayout extends StatelessWidget {
  const CenteredBoardLayout({
    required this.board,
    this.top,
    this.bottom,
    this.footer,
    this.gap = AppSpacing.sm,
    this.gutter = 0,
    this.reserveTop = 0,
    this.reserveBottom = 0,
    this.minFraction = 0.6,
    this.maxBoard = double.infinity,
    this.topAlignment = Alignment.bottomCenter,
    this.bottomAlignment = Alignment.topCenter,
    this.shrinkSides = true,
    super.key,
  });

  final Widget board;
  final Widget? top;
  final Widget? bottom;
  final Widget? footer;
  final double gap;
  final double gutter;
  final double reserveTop;
  final double reserveBottom;
  final double minFraction;
  final double maxBoard;

  /// Onde [top] fica no espaço dele: colado no tabuleiro, por padrão.
  final Alignment topAlignment;

  /// Onde [bottom] fica no espaço dele: colado no tabuleiro, por padrão.
  final Alignment bottomAlignment;

  /// Se [top] e [bottom] diminuem para caber.
  final bool shrinkSides;

  @override
  Widget build(BuildContext context) {
    Widget? side(Widget? child, Alignment alignment) => child == null
        ? null
        : shrinkSides
        ? ShrinkToFit(alignment: alignment, child: child)
        : child;
    return _CenteredBoard(
      top: side(top, topAlignment),
      board: board,
      bottom: side(bottom, bottomAlignment),
      footer: footer,
      gap: gap,
      gutter: gutter,
      reserveTop: reserveTop,
      reserveBottom: reserveBottom,
      minFraction: minFraction,
      maxBoard: maxBoard,
      topAlignment: topAlignment,
      bottomAlignment: bottomAlignment,
    );
  }
}

class _CenteredBoard
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _CenteredBoard({
    required this.top,
    required this.board,
    required this.bottom,
    required this.footer,
    required this.gap,
    required this.gutter,
    required this.reserveTop,
    required this.reserveBottom,
    required this.minFraction,
    required this.maxBoard,
    required this.topAlignment,
    required this.bottomAlignment,
  });

  final Widget? top;
  final Widget board;
  final Widget? bottom;
  final Widget? footer;
  final double gap;
  final double gutter;
  final double reserveTop;
  final double reserveBottom;
  final double minFraction;
  final double maxBoard;
  final Alignment topAlignment;
  final Alignment bottomAlignment;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.top => top,
    _Slot.board => board,
    _Slot.bottom => bottom,
    _Slot.footer => footer,
  };

  @override
  _RenderCenteredBoard createRenderObject(BuildContext context) =>
      _RenderCenteredBoard().._configure(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCenteredBoard renderObject,
  ) => renderObject._configure(this);
}

class _RenderCenteredBoard extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _CenteredBoard? _config;

  void _configure(_CenteredBoard widget) {
    final old = _config;
    _config = widget;
    if (old == null ||
        old.gap != widget.gap ||
        old.gutter != widget.gutter ||
        old.reserveTop != widget.reserveTop ||
        old.reserveBottom != widget.reserveBottom ||
        old.minFraction != widget.minFraction ||
        old.maxBoard != widget.maxBoard ||
        old.topAlignment != widget.topAlignment ||
        old.bottomAlignment != widget.bottomAlignment) {
      markNeedsLayout();
    }
  }

  static Offset _offsetOf(RenderBox child) =>
      (child.parentData! as BoxParentData).offset;

  static void _place(RenderBox child, Offset offset) =>
      (child.parentData! as BoxParentData).offset = offset;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    final config = _config!;
    size = constraints.biggest;
    final width = size.width;
    final footer = childForSlot(_Slot.footer);
    var footerHeight = 0.0;
    if (footer != null) {
      footer.layout(
        BoxConstraints.tightFor(width: width).copyWith(maxHeight: size.height),
        parentUsesSize: true,
      );
      footerHeight = footer.size.height;
      _place(footer, Offset(0, size.height - footerHeight));
    }
    final geometry = BoardCentering(
      size,
      footer: footerHeight,
      gap: config.gap,
      gutter: config.gutter,
      reserveTop: config.reserveTop,
      reserveBottom: config.reserveBottom,
      minFraction: config.minFraction,
      maxBoard: config.maxBoard,
    );
    final rect = geometry.board;
    final board = childForSlot(_Slot.board)!;
    board.layout(BoxConstraints.tight(rect.size));
    _place(board, rect.topLeft);
    final top = childForSlot(_Slot.top);
    if (top != null) {
      final room = geometry.roomAbove;
      top.layout(
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: room),
        parentUsesSize: true,
      );
      final free = room - top.size.height;
      _place(top, Offset(0, free * (config.topAlignment.y + 1) / 2));
    }
    final bottom = childForSlot(_Slot.bottom);
    if (bottom != null) {
      final room = geometry.roomBelow;
      bottom.layout(
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: room),
        parentUsesSize: true,
      );
      final free = room - bottom.size.height;
      _place(
        bottom,
        Offset(
          0,
          rect.bottom + config.gap + free * (config.bottomAlignment.y + 1) / 2,
        ),
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(child, offset + _offsetOf(child));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final hit = result.addWithPaintOffset(
        offset: _offsetOf(child),
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// Mostra [child] na altura natural dele e, se ela passar da altura máxima
/// dada, diminui o desenho todo na proporção (como um `FittedBox` que só
/// encolhe), mantendo a largura dada para o filho se arrumar.
class ShrinkToFit extends SingleChildRenderObjectWidget {
  const ShrinkToFit({
    required Widget super.child,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  /// De onde ele encolhe.
  final Alignment alignment;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShrinkToFit(alignment);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) => (renderObject as _RenderShrinkToFit).alignment = alignment;
}

class _RenderShrinkToFit extends RenderProxyBox {
  _RenderShrinkToFit(this._alignment);

  Alignment _alignment;
  set alignment(Alignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  double _scale = 1;

  Matrix4 get _transform {
    final child = this.child!;
    final dx =
        (size.width - child.size.width * _scale) * (_alignment.x + 1) / 2;
    final dy =
        (size.height - child.size.height * _scale) * (_alignment.y + 1) / 2;
    return Matrix4.translationValues(dx, dy, 0)
      ..scaleByDouble(_scale, _scale, 1, 1);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(Size.zero);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );
    final natural = child.size;
    final maxHeight = constraints.maxHeight;
    _scale = natural.height > maxHeight && natural.height > 0
        ? maxHeight / natural.height
        : 1;
    size = constraints.constrain(Size(natural.width, natural.height * _scale));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (_scale == 1) return child.hitTest(result, position: position);
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_scale != 1) transform.multiply(_transform);
  }
}

/// O painel das opções embaixo do tabuleiro centralizado (T64), nas telas
/// que antes eram uma lista com o tabuleiro no alto: cantos de cima
/// arredondados, a cor de superfície baixa, o conteúdo ([child], uma lista
/// que rola) e, fixo no pé, o botão de confirmar ([footer]). Fica embaixo da
/// área do tabuleiro, que tem a altura [boardAreaFor].
class BoardOptionsPanel extends StatelessWidget {
  const BoardOptionsPanel({required this.child, this.footer, super.key});

  final Widget child;
  final Widget? footer;

  /// A altura da área do tabuleiro: o que ele pede ([boardRoom]), sem
  /// passar de `1 - minPanel` da altura [available] (o painel fica com pelo
  /// menos [minPanel] dela; em tela baixa ou com fonte grande, o tabuleiro
  /// é que diminui).
  static double boardAreaFor(
    double available, {
    required double boardRoom,
    double minPanel = 0.4,
  }) => max(0.0, min(boardRoom, available * (1 - minPanel)));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppShape.large),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: child),
          ?footer,
        ],
      ),
    );
  }
}
