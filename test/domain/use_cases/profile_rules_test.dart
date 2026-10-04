import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/profile_rules.dart';

void main() {
  group('rating', () {
    test('aceita número inteiro dentro da faixa, com as pontas', () {
      expect(ProfileRules.parseRating('1500'), 1500);
      expect(
        ProfileRules.parseRating('${UserProfile.minRating}'),
        UserProfile.minRating,
      );
      expect(
        ProfileRules.parseRating('${UserProfile.maxRating}'),
        UserProfile.maxRating,
      );
    });

    test('ignora espaços nas pontas', () {
      expect(ProfileRules.parseRating(' 1800 '), 1800);
    });

    test('recusa fora da faixa', () {
      expect(ProfileRules.parseRating('5000'), isNull);
      expect(ProfileRules.parseRating('99'), isNull);
      expect(ProfileRules.parseRating('-1500'), isNull);
    });

    test('recusa vazio e o que não é número inteiro', () {
      expect(ProfileRules.parseRating(''), isNull);
      expect(ProfileRules.parseRating('abc'), isNull);
      expect(ProfileRules.parseRating('1500.5'), isNull);
    });

    test('aceita algarismos árabes e persas', () {
      expect(ProfileRules.parseRating('١٥٠٠'), 1500);
      expect(ProfileRules.parseRating('۱۵۰۰'), 1500);
    });
  });

  group('apelido', () {
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
  });
}
