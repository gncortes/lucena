import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/user_profile.dart';
import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nickname = TextEditingController();
  final _rating = TextEditingController();
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProfileCubit>()..clearError();
    _fill(cubit.state.profile);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _rating.dispose();
    super.dispose();
  }

  // Os campos recebem o perfil gravado uma vez só; depois valem as edições.
  void _fill(UserProfile? profile) {
    if (_filled || profile == null) return;
    _filled = true;
    _nickname.text = profile.nickname;
    _rating.text = '${profile.rating}';
  }

  Future<void> _save() async {
    final saved = await context.read<ProfileCubit>().save(
      nickname: _nickname.text,
      rating: _rating.text,
    );
    if (saved && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) => _fill(state.profile),
      builder: (context, state) {
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
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      UserProfile.maxNicknameLength,
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.profileNickname,
                    hintText: l10n.profileNicknameDefault,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: ProfileKeys.ratingField,
                  controller: _rating,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => context.read<ProfileCubit>().clearError(),
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: l10n.profileRating,
                    helperText: l10n.profileRatingHint(
                      UserProfile.minRating,
                      UserProfile.maxRating,
                    ),
                    helperMaxLines: 3,
                    errorText: state.ratingInvalid
                        ? l10n.profileRatingError(
                            UserProfile.minRating,
                            UserProfile.maxRating,
                          )
                        : null,
                    errorMaxLines: 3,
                    prefixIcon: const Icon(Icons.emoji_events_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  key: ProfileKeys.saveButton,
                  onPressed: state.profile == null ? null : _save,
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
