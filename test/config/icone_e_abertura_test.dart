import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// H-ANI-42 (ícone B2) e H-ANI-43 (abertura nativa): os arquivos e a
/// configuração do Android.
void main() {
  const res = 'android/app/src/main/res';

  group('H-ANI-42 · ícone', () {
    test('o monocromático tem 1024 px, só branco ou transparente', () {
      final png = img.decodePng(
        File('assets/branding/launcher_icon_monochrome.png').readAsBytesSync(),
      )!;
      expect(png.width, 1024);
      expect(png.height, 1024);
      expect(png.numChannels, 4);
      var figura = 0;
      for (final p in png) {
        if (p.a == 0) continue;
        figura++;
        expect([p.r, p.g, p.b], [255, 255, 255]);
      }
      expect(figura, greaterThan(1024 * 1024 ~/ 20));
    });

    test('os PNGs do launcher saem da marca B2', () {
      final marca = File('assets/branding/launcher_icon.png').readAsBytesSync();
      final mascote = File('assets/branding/mascote.png').readAsBytesSync();
      expect(mascote, marca);
      final fundo = img.decodePng(marca)!;
      final canto = fundo.getPixel(4, 4);
      expect([canto.r, canto.g, canto.b], [0x14, 0x21, 0x1B]);
      final frente = img.decodePng(
        File('assets/branding/launcher_icon_foreground.png').readAsBytesSync(),
      )!;
      expect(frente.numChannels, 4);
      expect(frente.getPixel(4, 4).a, 0);
    });

    test('o pubspec liga o monocromático e o fundo #14211B', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('adaptive_icon_background: "#14211B"'));
      expect(
        pubspec,
        contains(
          'adaptive_icon_monochrome: assets/branding/launcher_icon_monochrome.png',
        ),
      );
      final adaptativo = File('$res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(adaptativo, contains('<monochrome'));
    });

    test('o mascote antigo saiu de lib e do pubspec', () {
      final achados = <String>[];
      for (final f in [
        ...Directory('lib').listSync(recursive: true).whereType<File>(),
        File('pubspec.yaml'),
      ]) {
        if (!f.path.endsWith('.dart') && !f.path.endsWith('.yaml')) continue;
        if (RegExp('mascot_(light|dark)').hasMatch(f.readAsStringSync())) {
          achados.add(f.path);
        }
      }
      expect(achados, isEmpty, reason: achados.join('\n'));
    });
  });

  group('H-ANI-43 · abertura nativa', () {
    test('Android 12+: fundo, peão animado e 500 ms', () {
      final estilo = File('$res/values-v31/styles.xml').readAsStringSync();
      String item(String nome) =>
          RegExp('<item name="android:$nome">([^<]+)</item>')
              .firstMatch(estilo)!
              .group(1)!
              .trim();
      expect(
        item('windowSplashScreenBackground').toUpperCase(),
        contains('14211B'),
      );
      expect(item('windowSplashScreenAnimatedIcon'), '@drawable/abertura_peao');
      expect(item('windowSplashScreenAnimationDuration'), '500');
    });

    test(
      'o peão é um animated-vector: escala 0,6 → 1,06 → 1, opacidade 0 → 1',
      () {
        final peao = File('$res/drawable/abertura_peao.xml').readAsStringSync();
        expect(peao, contains('<animated-vector'));
        final escalas = RegExp(
          r'android:propertyName="scaleX"[^>]*android:valueFrom="([\d.]+)"[^>]*android:valueTo="([\d.]+)"',
        ).allMatches(peao).map((m) => '${m[1]}>${m[2]}').toList();
        expect(escalas, ['0.6>1.06', '1.06>1']);
        expect(
          RegExp(r'android:propertyName="scaleY"').allMatches(peao).length,
          2,
        );
        expect(
          peao,
          matches(
            RegExp(
              r'android:propertyName="alpha"[^>]*android:valueFrom="0"[^>]*android:valueTo="1"',
            ),
          ),
        );
      },
    );

    test('Android 11 e anteriores: launch_background #14211B', () {
      for (final pasta in ['values', 'values-night']) {
        final cor = File('$res/$pasta/launch_colors.xml').readAsStringSync();
        expect(cor, contains('#14211B'), reason: pasta);
        expect(cor, isNot(contains('F5F7F4')), reason: pasta);
      }
    });
  });
}
