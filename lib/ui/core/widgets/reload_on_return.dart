import 'package:flutter/widgets.dart';

/// Chama [onReturn] quando esta tela volta a ser a de cima (o jogador saiu
/// das telas abertas a partir dela). Serve para telas que mostram dados que
/// mudam nessas outras telas.
class ReloadOnReturn extends StatefulWidget {
  const ReloadOnReturn({
    required this.onReturn,
    required this.child,
    super.key,
  });

  final VoidCallback onReturn;
  final Widget child;

  @override
  State<ReloadOnReturn> createState() => _ReloadOnReturnState();
}

class _ReloadOnReturnState extends State<ReloadOnReturn> {
  bool _wasCurrent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `ModalRoute.isCurrentOf` reconstrói este widget quando a tela deixa de
    // ser ou volta a ser a de cima.
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (current && !_wasCurrent) widget.onReturn();
    _wasCurrent = current;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
