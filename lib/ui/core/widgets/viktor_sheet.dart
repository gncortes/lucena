import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../keys/viktor_sheet_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import 'sheet_close_button.dart';
import 'speech_text_tap_notification.dart';

/// Folha do Viktor sobre a área de jogo. O topo recolhido é explícito;
/// abrir a folha nunca redimensiona ou desloca o tabuleiro atrás dela.
class ViktorSheet extends StatefulWidget {
  const ViktorSheet({
    required this.top,
    required this.children,
    this.controller,
    this.scrollKey = ViktorSheetKeys.scroll,
    this.closeKey = ViktorSheetKeys.close,
    this.onExpanded,
    this.onMoving,
    this.onTop,
    this.onMinimumChanged,

    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
    super.key,
  });

  /// Apresentação para filhos que oferecem um resumo compacto recolhido.
  static bool expandedOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_ViktorSheetPresentation>()
          ?.expanded ??
      true;

  /// Baixa a folha até a borda do tabuleiro (a posição recolhida), sem mexer
  /// no que está nela. Sem [ViktorSheet] acima de [context], não faz nada.
  static void collapse(BuildContext context) => context
      .getInheritedWidgetOfExactType<_ViktorSheetPresentation>()
      ?.sheet
      ._collapse();

  /// Quanto, no fim da folha, fica coberto por botões flutuantes: a fala
  /// que aparece aos poucos rola para a linha nova parar acima disso.
  /// Altura reservada em todos os estados para texto acima das ações.
  static const peekHeight = 160.0;

  final double top;
  final List<Widget> children;
  final DraggableScrollableController? controller;
  final Key scrollKey;
  final Key closeKey;
  final ValueChanged<bool>? onExpanded;

  /// A folha está entre recolhida e aberta (arrastando ou animando): quem
  /// tem botões por cima dela os esconde só nesse meio-tempo.
  final ValueChanged<bool>? onMoving;

  /// Onde está o topo da folha (na área dela), a cada mudança: quem tem algo
  /// acima dela sabe quando a folha chega lá.
  final ValueChanged<double>? onTop;

  final ValueChanged<double>? onMinimumChanged;
  final EdgeInsetsGeometry padding;

  @override
  State<ViktorSheet> createState() => _ViktorSheetState();
}

class _ViktorSheetState extends State<ViktorSheet> {
  final _owned = DraggableScrollableController();
  DraggableScrollableController get _sheet => widget.controller ?? _owned;

  /// A folha aberta começa [SheetCloseButton.lift] + 8 dp abaixo do topo da
  /// área: o X (48 dp) fica inteiro, com 8 dp acima e 20 dp até a folha
  /// (LICOES-V2 §5). Calculado no layout.
  static const _openGap = 76.0;
  double _maximum = .95;
  double _minimum = .2;
  double? _extent;
  bool _expanded = false;
  bool _moving = false;
  bool _adjustingMinimum = false;
  Size? _area;
  double? _top;
  ScrollController? _scroll;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_changed);
  }

  @override
  void didUpdateWidget(ViktorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _owned).removeListener(_changed);
      _sheet.addListener(_changed);
    }
  }

  void _changed() {
    if (_adjustingMinimum) return;
    void update() {
      if (!mounted || !_sheet.isAttached) return;
      final extent = _sheet.size;
      if (_area case final area?) {
        widget.onTop?.call(area.height * (1 - extent));
      }
      final expanded = extent > _minimum + .03;
      final moving = extent > _minimum + .01 && extent < _maximum - .01;
      if (moving != _moving) {
        _moving = moving;
        widget.onMoving?.call(moving);
      }
      if (_extent != extent || _expanded != expanded) {
        final changed = expanded != _expanded;
        setState(() {
          _extent = extent;
          _expanded = expanded;
        });
        if (changed) widget.onExpanded?.call(expanded);
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => update());
    } else {
      update();
    }
  }

  void _animate(double size) {
    if (!_sheet.isAttached) return;
    if (AppMotion.of(context).disabled) {
      _sheet.jumpTo(size);
      return;
    }
    _sheet.animateTo(
      size,
      duration: AppMotion.of(context).component,
      curve: AppMotion.enter,
    );
  }

  void _collapse() => _animate(_minimum);

  void _close() {
    if (_scroll?.hasClients ?? false) _scroll!.jumpTo(0);
    _animate(_minimum);
  }

  @override
  void dispose() {
    _sheet.removeListener(_changed);
    _owned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final height = box.maxHeight;
      _maximum = (1 - _openGap / height).clamp(.02, 1.0);
      _minimum = ((height - widget.top) / height).clamp(.02, _maximum);
      final area = Size(box.maxWidth, height);
      final geometryChanged =
          _area != null && (_area != area || _top != widget.top);
      _area = area;
      _top = widget.top;
      if (geometryChanged && !_expanded) {
        // A fração recolhida muda com a viewport. Preservar a fração antiga
        // deixava a folha subir sobre a última fileira do tabuleiro.
        _extent = _minimum;
        _adjustingMinimum = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_sheet.isAttached) _sheet.jumpTo(_minimum);
          _adjustingMinimum = false;
          _changed();
        });
      }
      widget.onMinimumChanged?.call(_minimum);
      final extent = (_extent ?? _minimum).clamp(_minimum, _maximum);
      if (widget.onTop case final onTop?) {
        final top = height * (1 - extent);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) onTop(top);
        });
      }
      final colors = Theme.of(context).colorScheme;
      const radius = BorderRadius.vertical(
        top: Radius.circular(AppShape.large),
      );
      return Stack(
        children: [
          DraggableScrollableSheet(
            key: ViktorSheetKeys.sheet,
            controller: _sheet,
            initialChildSize: extent,
            minChildSize: _minimum,
            maxChildSize: _maximum,
            snap: true,
            builder: (context, scroll) {
              _scroll = scroll;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _animate(_maximum),
                    child: NotificationListener<SpeechTextTapNotification>(
                      onNotification: (_) {
                        _animate(_maximum);
                        return true;
                      },
                      child: RawScrollbar(
                        key: ViktorSheetKeys.scrollbar,
                        controller: scroll,
                        thickness: 4,
                        radius: const Radius.circular(AppShape.hairline),
                        thumbColor: colors.outlineVariant,
                        crossAxisMargin: 6,
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          // Recolhida: o fim da folha some em dp (não em
                          // fração), para o rótulo da seção seguinte não
                          // aparecer cortado logo abaixo do cabeçalho.
                          shaderCallback: (rect) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _expanded
                                ? [Colors.white, Colors.white]
                                : [
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                            stops: _expanded
                                ? null
                                : [
                                    0,
                                    math.max(0, 1 - 24 / rect.height),
                                    math.max(0, 1 - 12 / rect.height),
                                    1,
                                  ],
                          ).createShader(rect),
                          child: ListView(
                            key: widget.scrollKey,
                            controller: scroll,
                            padding: widget.padding,
                            children: [
                              Center(
                                child: Padding(
                                  // Alça do canvas: 32×4, 8 dp em cima e
                                  // nada embaixo (o cabeçalho tem a folga).
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    key: ViktorSheetKeys.handle,
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colors.outlineVariant,
                                      borderRadius: BorderRadius.circular(
                                        AppShape.full,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              for (final child in widget.children)
                                _ViktorSheetPresentation(
                                  expanded: _expanded,
                                  sheet: this,
                                  child: child,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          PositionedDirectional(
            end: SheetCloseButton.margin,
            top: math.max(0, height * (1 - extent) - SheetCloseButton.lift),
            child: IgnorePointer(
              ignoring: !_expanded,
              child: AnimatedOpacity(
                duration: AppMotion.of(context).component,
                opacity: _expanded ? 1 : 0,
                child: SheetCloseButton(
                  key: widget.closeKey,
                  onPressed: _close,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ViktorSheetPresentation extends InheritedWidget {
  const _ViktorSheetPresentation({
    required this.expanded,
    required this.sheet,
    required super.child,
  });
  final bool expanded;
  final _ViktorSheetState sheet;
  @override
  bool updateShouldNotify(_ViktorSheetPresentation oldWidget) =>
      expanded != oldWidget.expanded;
}
