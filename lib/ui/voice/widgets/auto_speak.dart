import 'package:flutter/widgets.dart';

import '../view_models/speech_cubit.dart';

/// Fala sozinho, com a voz ligada, cada [text] novo (se [auto]); para quando
/// a fala troca ou sai da tela. Com um leitor de tela ativo, não fala (ele já lê o balão).
class AutoSpeak extends StatefulWidget {
  const AutoSpeak({
    super.key,
    required this.speech,
    required this.text,
    required this.auto,
    required this.speakerId,
    required this.child,
  });

  final SpeechCubit speech;

  /// A fala do balão. Nula: nada a dizer.
  final String? text;

  /// Diz sozinho cada fala nova (com a voz ligada); sem isso, só pelo
  /// botão.
  final bool auto;
  final String speakerId;
  final Widget child;

  @override
  State<AutoSpeak> createState() => AutoSpeakState();
}

class AutoSpeakState extends State<AutoSpeak> {
  // A última fala mostrada: o balão que sai da tela para só a dele.
  String? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  @override
  void didUpdateWidget(AutoSpeak oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.text == widget.text) return;
    final previous = _shown;
    _shown = widget.text;
    if (widget.text == null) {
      widget.speech.stopIf(previous);
    } else {
      // A fala nova interrompe a anterior.
      widget.speech.stopIf(previous);
      WidgetsBinding.instance.addPostFrameCallback((_) => _say());
    }
  }

  void _say() {
    final text = widget.text;
    if (!mounted || !widget.auto || text == null || text != _shown) return;
    if (MediaQuery.accessibleNavigationOf(context)) return;
    widget.speech.sayIfEnabled(
      text,
      speakerId: widget.speakerId,
      language: Localizations.localeOf(context).toLanguageTag(),
    );
  }

  @override
  void dispose() {
    widget.speech.stopIf(_shown);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
