import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';
import 'package:lucena/ui/school/widgets/school_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('o iniciante não vê quantas aulas faltam: sem a barra "1 de 3" '
      'e sem o "1/2" do módulo', (tester) async {
    final cubit = SchoolCubit(
      lessons: FakeLessonRepository(),
      progress: FakeSchoolProgressRepository(
        const SchoolProgress(completed: {'pieces.rook'}),
      ),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(const UserProfile(rating: 800)),
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    await tester.pumpWidget(
      TestApp(
        child: BlocProvider.value(value: cubit, child: const SchoolScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SchoolKeys.module('pieces')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('1 of 3'), findsNothing);
    expect(find.text('1/2'), findsNothing);
    expect(find.textContaining(RegExp(r'\d+ ?(/|of) ?\d+')), findsNothing);
  });
}
