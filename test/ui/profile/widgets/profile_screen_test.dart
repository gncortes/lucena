import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/profile/view_models/rating_cubit.dart';
import 'package:lucena/ui/profile/widgets/profile_screen.dart';

import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeProfileRepository repository;
  late FakeRatingRepository rating;

  Future<void> pumpScreen(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
    Locale locale = const Locale('en'),
  }) async {
    repository = FakeProfileRepository(profile);
    rating = FakeRatingRepository();
    final cubit = ProfileCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        profileCubit: cubit,
        locale: locale,
        child: BlocProvider(
          create: (_) => RatingCubit(rating)..load(),
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  TextField nicknameField(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(ProfileKeys.nicknameField));

  String levelName(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ProfileKeys.levelName)).data!;

  Future<void> pickLevel(WidgetTester tester, RatingLevel level) async {
    await tester.tap(find.byKey(ProfileKeys.levelField));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ProfileKeys.levelOption(level)));
    await tester.tap(find.byKey(ProfileKeys.levelOption(level)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProfileKeys.levelConfirmButton));
    await tester.pumpAndSettle();
  }

  bool isMarked(WidgetTester tester, RatingLevel level) {
    final tile = tester.widget<ListTile>(
      find.descendant(
        of: find.byKey(ProfileKeys.levelOption(level)),
        matching: find.byType(ListTile),
      ),
    );
    return tile.selected;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(ProfileKeys.saveButton));
    await tester.pumpAndSettle();
  }

  testWidgets('a tela abre com o perfil gravado', (tester) async {
    await pumpScreen(
      tester,
      profile: const UserProfile(nickname: 'Ana', rating: 1450),
    );

    expect(nicknameField(tester).controller!.text, 'Ana');
    expect(levelName(tester), 'Intermediate');
    expect(find.text('1300–1599'), findsOneWidget);
  });

  testWidgets('sem apelido, o campo sugere o apelido padrão', (tester) async {
    await pumpScreen(tester);

    expect(nicknameField(tester).controller!.text, isEmpty);
    expect(nicknameField(tester).decoration!.hintText, 'Player');
  });

  testWidgets('o painel lista todas as faixas, com nome e intervalo, e marca '
      'a atual', (tester) async {
    await pumpScreen(tester, locale: const Locale('pt'));

    await tester.tap(find.byKey(ProfileKeys.levelField));
    await tester.pumpAndSettle();

    final sheet = find.byKey(ProfileKeys.levelSheet);
    for (final text in [
      'Iniciante',
      'Estou aprendendo as regras',
      'Intermediário',
      '1300 a 1599',
      'Mestre',
      '2200 ou mais',
    ]) {
      expect(find.descendant(of: sheet, matching: find.text(text)), findsOne);
    }
    for (final level in RatingLevel.values) {
      expect(isMarked(tester, level), level == RatingLevel.casual);
    }
    expect(
      find.descendant(
        of: find.byKey(ProfileKeys.levelConfirmButton),
        matching: find.text('Confirmar'),
      ),
      findsOne,
    );
  });

  testWidgets('tocar numa faixa só marca; a escolha vale ao confirmar', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(ProfileKeys.levelField));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(ProfileKeys.levelOption(RatingLevel.expert)),
    );
    await tester.tap(find.byKey(ProfileKeys.levelOption(RatingLevel.expert)));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileKeys.levelSheet), findsOneWidget);
    expect(isMarked(tester, RatingLevel.expert), isTrue);
    expect(isMarked(tester, RatingLevel.casual), isFalse);
    expect(levelName(tester), 'Casual');

    await tester.tap(find.byKey(ProfileKeys.levelConfirmButton));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileKeys.levelSheet), findsNothing);
    expect(levelName(tester), 'Expert');
  });

  testWidgets('confirmar uma faixa fecha o painel e mostra a escolha, ainda '
      'sem gravar', (tester) async {
    await pumpScreen(tester);

    await pickLevel(tester, RatingLevel.expert);

    expect(find.byKey(ProfileKeys.levelSheet), findsNothing);
    expect(levelName(tester), 'Expert');
    expect(repository.saved, isEmpty);
  });

  testWidgets('fechar o painel sem confirmar mantém a faixa, mesmo com outra '
      'marcada', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(ProfileKeys.levelField));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(ProfileKeys.levelOption(RatingLevel.master)),
    );
    await tester.tap(find.byKey(ProfileKeys.levelOption(RatingLevel.master)));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(ProfileKeys.levelSheet), findsNothing);
    expect(levelName(tester), 'Casual');
  });

  testWidgets('salvar grava o apelido e o rating da faixa escolhida', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(ProfileKeys.nicknameField), 'Bia');
    await pickLevel(tester, RatingLevel.advanced);
    await save(tester);

    expect(repository.saved, [
      UserProfile(nickname: 'Bia', rating: RatingLevel.advanced.rating),
    ]);
  });

  testWidgets('depois de confirmar a faixa, o teclado não volta a abrir no '
      'apelido', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(ProfileKeys.nicknameField));
    await tester.enterText(find.byKey(ProfileKeys.nicknameField), 'Bia');
    await tester.pump();
    expect(nicknameField(tester).focusNode!.hasFocus, isTrue);

    await pickLevel(tester, RatingLevel.advanced);

    expect(nicknameField(tester).focusNode!.hasFocus, isFalse);

    // Mas o campo continua editável: tocar nele traz o foco de volta.
    await tester.tap(find.byKey(ProfileKeys.nicknameField));
    await tester.pump();
    expect(nicknameField(tester).focusNode!.hasFocus, isTrue);
  });

  testWidgets('o apelido não passa do tamanho máximo', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(ProfileKeys.nicknameField),
      'a' * (UserProfile.maxNicknameLength + 10),
    );

    expect(
      nicknameField(tester).controller!.text,
      hasLength(UserProfile.maxNicknameLength),
    );
  });

  testWidgets('o cartão do rating tem a explicação no ⓘ, não fixa', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byKey(ProfileKeys.ratingCard)),
    );

    expect(find.text(l10n.profileRatingHint), findsNothing);
    await tester.ensureVisible(find.byKey(ProfileKeys.ratingHelp));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProfileKeys.ratingHelp));
    await tester.pumpAndSettle();
    expect(find.byKey(RatingKeys.helpText), findsOneWidget);
    expect(find.text(l10n.profileRatingHint), findsOneWidget);
  });
}
