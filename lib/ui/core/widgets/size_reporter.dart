import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Avisa o tamanho do filho depois de cada medida que o muda (fora do
/// quadro, para quem ouve poder refazer a tela).
class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({required this.onSize, super.child, super.key});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) => (renderObject as _RenderSizeReporter).onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final measured = size;
    SchedulerBinding.instance.addPostFrameCallback((_) => onSize(measured));
  }
}
