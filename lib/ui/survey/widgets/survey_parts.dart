import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/character.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/teacher_speech.dart';

/// As peças dos questionários: o "Sua opinião" (E1.05), o "Você pagaria?" e o
/// "Enviar feedback" (E1.26).

/// O agradecimento do Viktor depois de enviar, com um botão de volta.
class ViktorThanks extends StatelessWidget {
  const ViktorThanks({
    required this.title,
    required this.text,
    required this.backLabel,
    required this.onBack,
    required this.viktor,
    required this.closeKey,
    required this.backKey,
    super.key,
  });

  final String title;
  final String text;
  final String backLabel;
  final VoidCallback onBack;

  /// Nulo enquanto carrega: só o texto.
  final Character? viktor;
  final Key closeKey;
  final Key backKey;

  @override
  Widget build(BuildContext context) {
    final viktor = this.viktor;
    return Scaffold(
      appBar: LucenaAppBar(
        leading: IconButton(
          key: closeKey,
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onBack,
        ),
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xl,
          children: [
            if (viktor != null)
              TeacherSpeech(
                speechContext: SpeechContext.teaching,
                teacher: viktor,
                text: text,
              )
            else
              Text(text),
            FilledButton(
              key: backKey,
              onPressed: onBack,
              child: Text(backLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma pergunta por cartão: o título, a ajuda e o controle dentro dele.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.title,
    required this.children,
    this.hint,
    super.key,
  });

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `Material` e não `DecoratedBox`: as opções com toque pintam nele.
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShape.large),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs / 2,
              children: [
                Text(title, style: context.cardTitle),
                if (hint != null)
                  Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// As opções de uma escolha só, em linhas de rádio ([OptionRow]).
class OptionList<T> extends StatelessWidget {
  const OptionList({
    required this.values,
    required this.selected,
    required this.label,
    required this.optionKey,
    required this.onPick,
    super.key,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) label;
  final Key Function(T value) optionKey;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: selected,
    onChanged: (value) {
      if (value != null) onPick(value);
    },
    child: Column(
      children: [
        for (final value in values)
          OptionRow<T>(
            key: optionKey(value),
            value: value,
            label: label(value),
            selected: selected == value,
          ),
      ],
    ),
  );
}

/// Uma opção: linha de 44 dp com o rádio alinhado à esquerda do cartão e o
/// rótulo escolhido em negrito (canvas `PropV1AulasFeedback2`).
class OptionRow<T> extends StatelessWidget {
  const OptionRow({
    required this.value,
    required this.label,
    required this.selected,
    super.key,
  });

  static const _height = 44.0;

  /// Sem folga em volta: o círculo do rádio alinha com o título do cartão.
  static const _radioDensity = VisualDensity(horizontal: -4, vertical: -4);

  final T value;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final group = RadioGroup.maybeOf<T>(context);
    return InkWell(
      onTap: () => group?.onChanged(value),
      child: SizedBox(
        height: _height,
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Radio<T>(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: _radioDensity,
            ),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontWeight: selected ? FontWeight.w600 : null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chips de escolher (vários ou um, conforme o [onToggle]).
class SurveyChips extends StatelessWidget {
  const SurveyChips({
    required this.ids,
    required this.selected,
    required this.label,
    required this.chipKey,
    required this.onToggle,
    super.key,
  });

  final List<String> ids;
  final Set<String> selected;
  final String Function(String id) label;
  final Key Function(String id) chipKey;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) => ChipSurface(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final id in ids)
          FilterChip(
            materialTapTargetSize: AppChip.tapTarget,
            visualDensity: AppChip.density,
            key: chipKey(id),
            label: Text(label(id)),
            selected: selected.contains(id),
            onSelected: (_) => onToggle(id),
          ),
      ],
    ),
  );
}

/// O texto livre, até [maxLength] caracteres. O rascunho entra uma vez
/// ([initial]); depois o campo é o dono do texto. Com [counterKey], mostra
/// o contador de letras embaixo.
class SurveyTextBox extends StatefulWidget {
  const SurveyTextBox({
    required this.fieldKey,
    required this.hint,
    required this.initial,
    required this.onChanged,
    required this.maxLength,
    this.minLines = 3,
    this.maxLines = 6,
    this.counterKey,
    super.key,
  });

  final Key fieldKey;
  final String hint;
  final String? initial;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final Key? counterKey;

  @override
  State<SurveyTextBox> createState() => _SurveyTextBoxState();
}

class _SurveyTextBoxState extends State<SurveyTextBox> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counterKey = widget.counterKey;
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: _fontSize,
        height: _lineHeight / _fontSize,
      ),
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      maxLength: counterKey == null ? null : widget.maxLength,
      inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
      buildCounter: counterKey == null
          ? null
          : (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => Text(
              '$currentLength/$maxLength',
              key: counterKey,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _paddingH,
          vertical: AppSpacing.md,
        ),
        // `#F0F1F4` no canvas; o tom do tema mais próximo (`#EEEDF2`).
        fillColor: theme.colorScheme.surfaceContainer,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
      onChanged: widget.onChanged,
    );
  }

  /// Recuo lateral do texto (14 no canvas, sem token de espaço).
  static const _paddingH = 14.0;
  static const _fontSize = 15.0;
  static const _lineHeight = 22.0;

  /// Campo preenchido, sem contorno, de raio 12 (canvas `PropV1AulasFeedback1`).
  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppShape.medium)),
    borderSide: BorderSide.none,
  );
}
