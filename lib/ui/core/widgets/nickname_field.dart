import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/user_profile.dart';
import '../keys/core_keys.dart';

/// O campo do apelido (canvas `CompCampoTexto`): rótulo sempre no alto, para
/// o apelido padrão aparecer enquanto o campo está vazio. A tela passa a key
/// dela em [fieldKey].
class NicknameField extends StatelessWidget {
  const NicknameField({
    required this.controller,
    required this.label,
    required this.hint,
    this.fieldKey,
    this.onChanged,
    this.autocorrect = true,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final bool autocorrect;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey ?? CoreKeys.nicknameField,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      autocorrect: autocorrect,
      inputFormatters: [
        LengthLimitingTextInputFormatter(UserProfile.maxNicknameLength),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.person_outline),
      ),
    );
  }
}
