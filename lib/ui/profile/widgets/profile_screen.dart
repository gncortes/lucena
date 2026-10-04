import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/rating_level.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/profile_cubit.dart';
import 'rating_level_sheet.dart';
import 'rating_level_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nickname = TextEditingController();
  final _nicknameFocus = FocusNode();

  // A faixa confirmada no painel; só é gravada ao salvar.
  RatingLevel? _level;

  @override
  void initState() {
    super.initState();
    _fill(context.read<ProfileCubit>().state);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  // A tela recebe o perfil gravado uma vez só; depois valem as edições.
  void _fill(UserProfile? profile) {
    if (_level != null || profile == null) return;
    _nickname.text = profile.nickname;
    _level = profile.level;
  }

  Future<void> _pickLevel(RatingLevel current) async {
    // Fecha o teclado e não deixa o foco voltar ao apelido quando o painel
    // fechar (o teclado abriria de novo sozinho).
    _nicknameFocus.unfocus();
    _nicknameFocus.canRequestFocus = false;
    final picked = await showRatingLevelSheet(context, selected: current);
    if (!mounted) return;
    if (picked != null) setState(() => _level = picked);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nicknameFocus.canRequestFocus = true;
    });
  }

  Future<void> _save(RatingLevel level) async {
    await context.read<ProfileCubit>().save(
      nickname: _nickname.text,
      level: level,
    );
    if (mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ProfileCubit, UserProfile?>(
      listener: (context, profile) => setState(() => _fill(profile)),
      builder: (context, profile) {
        final level = _level;
        return Scaffold(
          key: ProfileKeys.screen,
          appBar: AppBar(title: Text(l10n.settingsProfile)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  key: ProfileKeys.nicknameField,
                  controller: _nickname,
                  focusNode: _nicknameFocus,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      UserProfile.maxNicknameLength,
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.profileNickname,
                    hintText: l10n.profileNicknameDefault,
                    // O apelido padrão fica à vista enquanto o campo está vazio.
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (level != null)
                  _LevelField(level: level, onTap: () => _pickLevel(level)),
                const SizedBox(height: 32),
                FilledButton(
                  key: ProfileKeys.saveButton,
                  onPressed: level == null ? null : () => _save(level),
                  child: Text(l10n.profileSave),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Parece um campo de formulário, mas abre o painel de escolha da faixa.
class _LevelField extends StatelessWidget {
  const _LevelField({required this.level, required this.onTap});

  final RatingLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Semantics(
      button: true,
      child: InkWell(
        key: ProfileKeys.levelField,
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.profileRating,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
            suffixIcon: const Icon(Icons.expand_more),
            border: const OutlineInputBorder(),
          ),
          child: Row(
            children: [
              LevelBadge(level: level),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name(l10n),
                      key: ProfileKeys.levelName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      level.range(l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
