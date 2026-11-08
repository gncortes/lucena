import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/widgets/nickname_field.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

/// A5b: a ajuda dos campos vem inteira, sem reticências. O limite de linhas
/// mora no tema (`inputDecorationTheme.helperMaxLines`), um ponto só para o
/// e-mail/senha da conta, o FEN da posição própria, o apelido, a região do
/// tour e o rating manual.
void main() {
  testWidgets('A5b: nenhuma ajuda de campo com reticências em PT a 360', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = context.l10n;
              InputDecoration help(String text, {bool icons = false}) =>
                  InputDecoration(
                    labelText: 'x',
                    helperText: text,
                    prefixIcon: icons ? const Icon(Icons.location_on) : null,
                    suffixIcon: icons
                        ? const Icon(Icons.arrow_drop_down)
                        : null,
                  );
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  TextField(decoration: help(l10n.accountPasswordHelp)),
                  TextField(decoration: help(l10n.customFenHint)),
                  NicknameField(
                    controller: TextEditingController(),
                    label: 'x',
                    hint: 'x',
                    helper: l10n.accountNicknameHelp,
                  ),
                  InputDecorator(
                    decoration: help(l10n.tourRegionCountryHelp, icons: true),
                  ),
                  TextField(decoration: help(l10n.levelManualHelp)),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cortadas = [
      for (final p in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      ))
        if (p.didExceedMaxLines) p.text.toPlainText(),
    ];
    expect(cortadas, isEmpty);
  });
}
