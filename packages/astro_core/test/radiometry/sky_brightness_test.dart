import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('birim donusumu', () {
    test('gidis-donus kapali', () {
      for (final v in [16.0, 18.0, 20.0, 21.6, 22.0]) {
        expect(
          nanoLambertsToMagPerSquareArcsec(magPerSquareArcsecToNanoLamberts(v)),
          closeTo(v, 1e-9),
          reason: '$v',
        );
      }
    });

    test('parlak gokyuzu = kucuk kadir = buyuk nanoLambert', () {
      final dark = magPerSquareArcsecToNanoLamberts(22.0); // Bortle 1
      final city = magPerSquareArcsecToNanoLamberts(18.0); // Bortle 9
      expect(city, greaterThan(dark));
      // 4 kadir fark = 40 kat parlaklik. Yol haritasindaki iddia buydu.
      expect(city / dark, closeTo(40.0, 0.5));
    });
  });

  group('hava kutlesi', () {
    test('basucunda 1', () {
      expect(kriscunasAirmass(0), closeTo(1.0, 1e-9));
    });

    test('yukseklik dustukce artiyor', () {
      var previous = 0.0;
      for (var z = 0.0; z <= 90.0; z += 10) {
        final x = kriscunasAirmass(z);
        expect(x, greaterThan(previous), reason: 'z=$z');
        previous = x;
      }
    });

    test('ufukta sonlu kaliyor — sec(Z) patlardi', () {
      expect(kriscunasAirmass(90).isFinite, isTrue);
      expect(kriscunasAirmass(90), closeTo(5.0, 0.1));
    });
  });

  group('Ay katkisi', () {
    /// Dolunay, hedeften 90 derece uzakta, ikisi de yuksekte.
    double fullMoonBrightness({
      double phaseAngle = 0,
      double moonAltitude = 60,
      double targetAltitude = 60,
      double separation = 90,
    }) => moonSkyBrightnessNanoLamberts(
      moonPhaseAngleDegrees: phaseAngle,
      moonAltitudeDegrees: moonAltitude,
      targetAltitudeDegrees: targetAltitude,
      separationDegrees: separation,
    );

    test('Ay ufkun altindaysa katki sifir', () {
      expect(fullMoonBrightness(moonAltitude: -1), 0.0);
      expect(fullMoonBrightness(moonAltitude: -30), 0.0);
    });

    test('hedef ufkun altindaysa katki sifir', () {
      expect(fullMoonBrightness(targetAltitude: -5), 0.0);
    });

    test('dolunay karanlik gokyuzunu 2-4 kadir parlatiyor', () {
      // Yol haritasindaki iddia: "Ay'li gecede fon 2-3 kadir artabilir,
      // bu da SNR'i 3-4 kat dusurur."
      final penalty = moonBrightnessPenaltyMagnitudes(
        baseSkyMagPerSquareArcsec: 21.8,
        moonContributionNanoLamberts: fullMoonBrightness(),
      );
      expect(penalty, inInclusiveRange(2.0, 4.0));
    });

    test('yeni ay neredeyse hicbir sey eklemiyor', () {
      final newMoon = fullMoonBrightness(phaseAngle: 178);
      final full = fullMoonBrightness(phaseAngle: 0);
      expect(newMoon, lessThan(full * 0.01));

      final penalty = moonBrightnessPenaltyMagnitudes(
        baseSkyMagPerSquareArcsec: 21.8,
        moonContributionNanoLamberts: newMoon,
      );
      expect(penalty, lessThan(0.3));
    });

    test('evre ilerledikce katki monoton azaliyor', () {
      var previous = double.infinity;
      for (var alpha = 0.0; alpha <= 170.0; alpha += 10) {
        final b = fullMoonBrightness(phaseAngle: alpha);
        expect(b, lessThan(previous), reason: 'evre acisi $alpha');
        previous = b;
      }
    });

    test('Ay\'a yakin bakmak daha parlak fon demek', () {
      final near = fullMoonBrightness(separation: 15);
      final far = fullMoonBrightness(separation: 150);
      expect(near, greaterThan(far));
      // 15 derece ile 150 derece arasinda 2.5 kat fark. Yakin cevrede
      // aerosol sacilmasi baskin, uzakta Rayleigh terimi kaliyor.
      expect(near / far, closeTo(2.54, 0.05));
    });

    test('Ay alcaldikca katkisi azaliyor', () {
      final high = fullMoonBrightness(moonAltitude: 70);
      final low = fullMoonBrightness(moonAltitude: 5);
      expect(low, lessThan(high));
    });

    test('sehirde Ay\'in etkisi daha az hissediliyor', () {
      // Fon zaten parlaksa Ay'in ekledigi kadir cezasi kuculur —
      // logaritmik olcegin dogrudan sonucu. Bortle 9'da Ay'li gece ile
      // Ay'siz gece arasindaki fark, Bortle 1'dekinden cok daha kucuk.
      final moon = fullMoonBrightness();
      final darkPenalty = moonBrightnessPenaltyMagnitudes(
        baseSkyMagPerSquareArcsec: 21.8,
        moonContributionNanoLamberts: moon,
      );
      final cityPenalty = moonBrightnessPenaltyMagnitudes(
        baseSkyMagPerSquareArcsec: 18.0,
        moonContributionNanoLamberts: moon,
      );
      expect(cityPenalty, lessThan(darkPenalty));
    });
  });

  group('toplam fon', () {
    test('toplama parlaklikta yapiliyor, kadirde degil', () {
      // Iki esit parlaklik kaynagi toplaninca 0.75 kadir parlar
      // (2.5*log10(2)). Kadirleri toplasaydik sacma bir sonuc cikardi.
      const base = 21.0;
      final equal = magPerSquareArcsecToNanoLamberts(base);
      final total = totalSkyBrightnessMagPerSquareArcsec(
        baseSkyMagPerSquareArcsec: base,
        moonContributionNanoLamberts: equal,
      );
      expect(base - total, closeTo(0.7526, 0.001));
    });

    test('Ay katkisi sifirsa fon degismiyor', () {
      expect(
        totalSkyBrightnessMagPerSquareArcsec(
          baseSkyMagPerSquareArcsec: 21.5,
          moonContributionNanoLamberts: 0,
        ),
        closeTo(21.5, 1e-9),
      );
    });
  });

  group('gercek senaryo — yol haritasindaki cumle', () {
    test('Ay %31 dolu ve alcak: sorun degil', () {
      // "Ay 02:50'de doguyor, %31 dolu — sorun degil."
      // %31 doluluk ~ evre acisi 113 derece.
      final penalty = moonBrightnessPenaltyMagnitudes(
        baseSkyMagPerSquareArcsec: 21.5,
        moonContributionNanoLamberts: moonSkyBrightnessNanoLamberts(
          moonPhaseAngleDegrees: 113,
          moonAltitudeDegrees: 15,
          targetAltitudeDegrees: 24,
          separationDegrees: 80,
        ),
      );
      expect(penalty, lessThan(0.7), reason: 'ceza $penalty kadir');
    });

    test('Ay %78 dolu ve 34 derecede: Samanyolu cekilemez', () {
      // "Ay %78 dolu, 34 derece yukseklikte — Samanyolu cekilemez."
      // %78 doluluk ~ evre acisi 65 derece.
      final penalty = moonBrightnessPenaltyMagnitudes(
        baseSkyMagPerSquareArcsec: 21.5,
        moonContributionNanoLamberts: moonSkyBrightnessNanoLamberts(
          moonPhaseAngleDegrees: 65,
          moonAltitudeDegrees: 34,
          targetAltitudeDegrees: 24,
          separationDegrees: 60,
        ),
      );
      // Model 1.99 kadir veriyor: gokyuzu ~6 kat parliyor. Bu, difuz
      // Samanyolu detayini tamamen bogar — yol haritasindaki uyari
      // sayisal olarak dogrulaniyor.
      expect(penalty, greaterThan(1.9), reason: 'ceza $penalty kadir');
      expect(penalty, lessThan(2.5), reason: 'ceza $penalty kadir');
    });
  });
}
