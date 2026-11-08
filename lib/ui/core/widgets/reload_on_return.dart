import 'package:flutter/widgets.dart';

/// Chama [onReturn] quando esta tela volta a ser a de cima (o jogador saiu
/// das telas abertas a partir dela). Serve para telas que mostram dados que
/// mudam nessas outras telas.
class ReloadOnReturn extends StatefulWidget {
  const ReloadOnReturn({
    required this.onReturn,
    required this.child,
    this.onResume = false,
    super.key,
  });

  final VoidCallback onReturn;
  final Widget child;
  final bool onResume;

  @override
  State<ReloadOnReturn> createState() => _ReloadOnReturnState();
}

class _ReloadOnReturnState extends State<ReloadOnReturn>
    with WidgetsBindingObserver {
  bool _wasCurrent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.onResume &&
        state == AppLifecycleState.resumed &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      widget.onReturn();
    }
  }

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
