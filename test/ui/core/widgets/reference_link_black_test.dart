import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/reference_link.dart';

void main() {
  test('Lichess do lado das pretas: partida e análise', () {
    expect(
      ReferenceLink.forBlack(Uri.parse('https://lichess.org/abcdEFGH#109'))
          .toString(),
      'https://lichess.org/abcdEFGH/black#109',
    );
    expect(
      ReferenceLink.forBlack(Uri.parse('https://lichess.org/abcdEFGH/white#12'))
          .toString(),
      'https://lichess.org/abcdEFGH/black#12',
    );
    expect(
      ReferenceLink.forBlack(
        Uri.parse('https://lichess.org/analysis/8/8/8/8/8/8/8/K6k_w_-_-_0_1'),
      ).queryParameters['color'],
      'black',
    );
    final wiki = Uri.parse('https://pt.wikipedia.org/wiki/Xadrez');
    expect(ReferenceLink.forBlack(wiki), wiki);
  });
}
