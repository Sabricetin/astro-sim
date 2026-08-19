import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  final canon760d = cameras.firstWhere((c) => c.name == 'Canon EOS 760D');

  group('NPF kurali', () {
    test('Canon 760D, 14 mm f/2.8 -> ~15 saniye', () {
      final t = npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: canon760d.pixelPitchMicrometers,
        focalLengthMm: 14,
      );
      expect(t, closeTo(14.96, 0.05));
    });

    test('500 kurali ayni durumda iki katindan fazlasini soyluyor', () {
      // Yol haritasinin iddiasi: "45 MP bir govdede 500 kurali sana yalan
      // soyler". Burada 24 MP'de bile fark iki kat.
      final npf = npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: canon760d.pixelPitchMicrometers,
        focalLengthMm: 14,
      );
      expect(fiveHundredRuleSeconds(14) / npf, greaterThan(2.3));
    });

    test('kucuk piksel adimi daha kisa poz demek', () {
      // 500 kuralinin goremedigi sey tam olarak bu.
      double npf(double pitch) => npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: pitch,
        focalLengthMm: 24,
      );
      expect(npf(3.0), lessThan(npf(6.0)));
    });

    test('genis diyafram daha kisa poz demek', () {
      double npf(double n) => npfMaxExposureSeconds(
        aperture: n,
        pixelPitchMicrometers: 4.0,
        focalLengthMm: 24,
      );
      expect(npf(1.4), lessThan(npf(5.6)));
    });

    test('sifir odak reddedilir', () {
      expect(
        () => npfMaxExposureSeconds(
          aperture: 2.8,
          pixelPitchMicrometers: 4,
          focalLengthMm: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('deklinasyon duzeltmesi', () {
    test('ekvatorda carpan 1', () {
      expect(declinationFactor(0), closeTo(1.0, 1e-12));
    });

    test('galaktik merkez (sapma -29) sinirini %14 uzatiyor', () {
      final atEquator = npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: canon760d.pixelPitchMicrometers,
        focalLengthMm: 14,
      );
      final atGalacticCenter = npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: canon760d.pixelPitchMicrometers,
        focalLengthMm: 14,
        declinationDegrees: -29.0,
      );
      expect(atGalacticCenter / atEquator, closeTo(1.143, 0.005));
    });

    test('kutupta patlamiyor — kirpma devrede', () {
      final t = npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: 4,
        focalLengthMm: 24,
        declinationDegrees: 90,
      );
      expect(t.isFinite, isTrue);
      // Kirpma ust siniri 20 katla sabitliyor.
      final base = npfMaxExposureSeconds(
        aperture: 2.8,
        pixelPitchMicrometers: 4,
        focalLengthMm: 24,
      );
      expect(t / base, closeTo(20.0, 0.01));
    });

    test('isaret onemsiz: +40 ile -40 ayni', () {
      expect(declinationFactor(40), closeTo(declinationFactor(-40), 1e-12));
    });
  });

  group('yildiz izi', () {
    test('NPF sinirinda iz odak uzunlugundan BAGIMSIZ', () {
      // Kuralin tutarli olmasinin sebebi bu: t odakla ters, acisal olcek
      // de odakla ters orantili; ikisi sadelesiyor.
      final trails = <double>[];
      for (final f in [14.0, 24.0, 50.0, 135.0, 400.0]) {
        final t = npfMaxExposureSeconds(
          aperture: 2.8,
          pixelPitchMicrometers: 3.717,
          focalLengthMm: f,
        );
        trails.add(
          starTrailPixels(
            exposureSeconds: t,
            pixelPitchMicrometers: 3.717,
            focalLengthMm: f,
          ),
        );
      }
      for (final t in trails) {
        expect(t, closeTo(trails.first, 1e-9));
      }
      expect(trails.first, closeTo(4.11, 0.02));
    });

    test('500 kuralinda iz iki katindan fazla', () {
      final trail500 = starTrailPixels(
        exposureSeconds: fiveHundredRuleSeconds(14),
        pixelPitchMicrometers: 3.717,
        focalLengthMm: 14,
      );
      expect(trail500, closeTo(9.81, 0.05));
    });

    test('poz iki katina cikinca iz iki katina cikar', () {
      double trail(double seconds) => starTrailPixels(
        exposureSeconds: seconds,
        pixelPitchMicrometers: 4,
        focalLengthMm: 24,
      );
      expect(trail(20) / trail(10), closeTo(2.0, 1e-9));
    });

    test('kutup yildizi neredeyse kimildamiyor', () {
      final equator = starTrailPixels(
        exposureSeconds: 30,
        pixelPitchMicrometers: 4,
        focalLengthMm: 24,
      );
      final polar = starTrailPixels(
        exposureSeconds: 30,
        pixelPitchMicrometers: 4,
        focalLengthMm: 24,
        declinationDegrees: 89.26, // Kutup Yildizi
      );
      expect(polar, lessThan(equator * 0.06));
    });
  });

  group('FAZ 3 CIKIS KRITERI — 14 mm tam karede Orion siginiyor', () {
    test('Orion figuru cerceveye giriyor', () {
      final catalog = StarCatalog.fromBytes(
        File('assets/stars_bsc5.bin').readAsBytesSync(),
      );
      final indexByHr = {
        for (var i = 0; i < catalog.length; i++) catalog.hrNumbers[i]: i,
      };
      final orion = constellations.firstWhere((c) => c.abbreviation == 'Ori');
      final hrs = orion.segments.toSet().toList();

      // Figurun en genis acisal boyutu.
      var widest = 0.0;
      for (final a in hrs) {
        for (final b in hrs) {
          final ia = indexByHr[a]!;
          final ib = indexByHr[b]!;
          final d = angularSeparationDegrees(
            catalog.rightAscensionDegrees(ia),
            catalog.declinationDegrees(ia),
            catalog.rightAscensionDegrees(ib),
            catalog.declinationDegrees(ib),
          );
          if (d > widest) widest = d;
        }
      }

      final fov = FieldOfView.of(format: fullFrame, focalLengthMm: 14);
      // Kosegen boyunca sigmali; Orion dikey uzanir, cercevenin
      // yonlendirmesi kullaniciya kalir.
      expect(
        widest,
        lessThan(fov.diagonalDegrees),
        reason:
            'Orion ${widest.toStringAsFixed(1)} derece, '
            'cerceve kosegeni ${fov.diagonalDegrees.toStringAsFixed(1)}',
      );
      // Bol bol pay olmali — sadece kil payi sigmasin.
      expect(widest, lessThan(fov.verticalDegrees));
    });
  });
}
