import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lucena/data/repositories/photo/photo_repository.dart';

void main() {
  test('recorta o quadrado do meio e reduz para o lado da foto', () {
    final wide = img.Image(width: 1200, height: 800);
    final out = squareJpeg(Uint8List.fromList(img.encodePng(wide)))!;
    final image = img.decodeJpg(out)!;
    expect(
      (image.width, image.height),
      (PhotoRepository.side, PhotoRepository.side),
    );
  });

  test('foto menor que o lado não aumenta', () {
    final small = img.Image(width: 300, height: 200);
    final image = img.decodeJpg(
      squareJpeg(Uint8List.fromList(img.encodePng(small)))!,
    )!;
    expect((image.width, image.height), (200, 200));
  });

  test('bytes que não são imagem dão nulo', () {
    expect(squareJpeg(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
