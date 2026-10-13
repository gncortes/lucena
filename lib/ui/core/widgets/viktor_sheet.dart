import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    this.closeTooltip,
    this.modalKey,
    this.onExpanded,
    this.onMoving,
    this.onTop,
    this.onMinimumChanged,
    this.collapsedInset,
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

  /// A folha aberta começa [SheetCloseButton.lift] + 8 dp abaixo do topo da
  /// área: o X (48 dp) fica inteiro, com 8 dp acima e 20 dp até a folha
  /// (LICOES-V2 §5).
  static const openGap = 76.0;

  /// Quanto a folha aberta sozinha fica à vista antes de recolher: 2 s mais
  /// 50 ms por caractere do texto, entre 4 e 12 s. Só aqui.
  static Duration readingTime(int length) =>
      Duration(milliseconds: (2000 + 50 * length).clamp(4000, 12000));

  final double top;

  /// Quanto, no fim da folha recolhida, já é da barra de controles: o texto
  /// vai até ela. Sem valor, vale o `padding` de baixo (que inclui a folga
  /// depois do último item e só pesa ao rolar até o fim).
  final double? collapsedInset;
  final List<Widget> children;
  final DraggableScrollableController? controller;
  final Key scrollKey;
  final Key closeKey;

  /// Rótulo do X (dica e leitor de tela); sem ele, o "Fechar" do sistema.
  final String? closeTooltip;

  /// Marca a folha na tela enquanto ela é um modal (a apresentação B): um
  /// quadro transparente sobre a folha, sem remontar o conteúdo.
  final Key? modalKey;
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
  double _maximum = .95;
  double _minimum = .2;
  double? _extent;
  bool _expanded = false;
  bool _moving = false;
  bool _adjustingMinimum = false;
  Size? _area;
  double? _top;
  final _maskKey = GlobalKey();

  /// Fim do cabeçalho do Viktor ([ViktorSheetKeys.header]) nas coordenadas da
  /// máscara: o fade nunca começa acima dele, para não clarear o retrato.
  double _headerBottom() {
    final maskElement = _maskKey.currentContext;
    final mask = maskElement?.findRenderObject();
    if (maskElement == null || mask is! RenderBox || !mask.attached) return 0;
    RenderObject? header;
    void visit(Element element) {
      if (header != null) return;
      if (element.widget.key == ViktorSheetKeys.header) {
        header = element.findRenderObject();
        return;
      }
      element.visitChildElements(visit);
    }

    maskElement.visitChildElements(visit);
    final box = header;
    if (box is! RenderBox || !box.attached) return 0;
    return box.localToGlobal(Offset(0, box.size.height), ancestor: mask).dy;
  }

  /// Onde o recolhido corta, nas coordenadas da máscara: nunca no meio de uma
  /// linha nem de um botão. Uma linha que cruza [y] fica inteira se só a
  /// folga de baixo dela (até [slack] dp, sem letra) passa de [y]; senão o
  /// corte sobe ao topo dela (360×640: a 4ª linha não fica cortada ao meio).
  /// Um botão (forma com até [_atomic] dp) cruzando [y] sai inteiro: não
  /// aparece pela metade acima do rodapé (demo pausada com texto longo).
  /// Nula se nenhuma linha nem botão toca o corte nem os 4 dp do esmaecido.
  double? _lineCut(double y, {double slack = 4}) {
    final maskElement = _maskKey.currentContext;
    final mask = maskElement?.findRenderObject();
    if (maskElement == null || mask is! RenderBox || !mask.attached) {
      return null;
    }
    double? cut;
    void visit(RenderObject node) {
      if (cut != null) return;
      if (node is RenderBox &&
          node.attached &&
          node.hasSize &&
          (node is RenderParagraph ||
              (node is RenderPhysicalShape && node.size.height <= _atomic))) {
        final origin = node.localToGlobal(Offset.zero, ancestor: mask).dy;
        if (origin >= y + _fadeLength || origin + node.size.height <= y) {
          return;
        }
        if (node is! RenderParagraph) {
          cut = origin;
          return;
        }
        final length = node.text.toPlainText().length;
        for (final box in node.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
        )) {
          final top = origin + box.top, bottom = origin + box.bottom;
          // A linha que começa nos 4 dp do esmaecido também conta: o topo
          // das letras apareceria no degradê.
          if (top < y + _fadeLength && bottom > y) {
            cut = bottom - y <= slack ? bottom : top;
            return;
          }
        }
        return;
      }
      node.visitChildren(visit);
    }

    mask.visitChildren(visit);
    return cut;
  }

  /// Maior altura de forma tratada como um botão só no corte do recolhido.
  static const _atomic = 64.0;

  /// Comprimento do degradê do corte do recolhido.
  static const _fadeLength = 4.0;

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
      _maximum = (1 - ViktorSheet.openGap / height).clamp(.02, 1.0);
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
                          key: _maskKey,
                          blendMode: BlendMode.dstIn,
                          // Recolhida: o que fica acima do rodapé (a área
                          // visível, sem o `padding` de baixo) some em 4 dp
                          // entre duas linhas, para nenhuma linha (nem o
                          // rótulo da seção seguinte) aparecer cortada.
                          shaderCallback: (rect) {
                            final visible = math.max(
                              1.0,
                              rect.height -
                                  (widget.collapsedInset ??
                                      widget.padding
                                          .resolve(Directionality.of(context))
                                          .bottom),
                            );
                            // Sem 12 dp livres abaixo do cabeçalho (360×640),
                            // corte seco no fim dele: nem retrato clareado,
                            // nem rótulo cortado.
                            final header = _headerBottom();
                            final tight = header > visible - 12;
                            // O corte cai entre linhas: no topo da linha que
                            // não cabe (ou no fim da que cabe), nunca no meio.
                            final plain = visible - 4;
                            final line = _expanded || tight
                                ? null
                                : _lineCut(plain);
                            final cut = line == null
                                ? plain
                                : math.max(header, line);
                            // Corte numa fronteira de linha: o esmaecido
                            // fica antes dela (na folga da linha de cima) e
                            // abaixo do corte nada da linha seguinte
                            // aparece, nem o topo das letras.
                            final atLine = line != null;
                            final start = math.min(
                              rect.height,
                              tight ? header : (atLine ? cut - 2 : cut),
                            );
                            final end = math.min(
                              rect.height,
                              tight ? header : (atLine ? cut : cut + 4),
                            );
                            return LinearGradient(
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
                                      math.max(0, start / rect.height),
                                      math.max(0, end / rect.height),
                                      1,
                                    ],
                            ).createShader(rect);
                          },
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
                  tooltip: widget.closeTooltip,
                  onPressed: _close,
                ),
              ),
            ),
          ),
          if (widget.modalKey case final key?)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              top: height * (1 - extent),
              child: IgnorePointer(child: SizedBox.expand(key: key)),
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
