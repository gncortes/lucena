import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/profile_rules.dart';

void main() {
  test('tira espaços das pontas e une espaços repetidos', () {
    expect(ProfileRules.cleanNickname('  Ana   Maria '), 'Ana Maria');
  });

  test('só espaços vira vazio (usa o apelido padrão)', () {
    expect(ProfileRules.cleanNickname('   '), '');
  });

  test('corta no tamanho máximo', () {
    final long = 'a' * (UserProfile.maxNicknameLength + 5);

    expect(
      ProfileRules.cleanNickname(long),
      hasLength(UserProfile.maxNicknameLength),
    );
  });
}
