import 'dart:math' as math;

import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('derece <-> radyan', () {
    test('bilinen degerler', () {
      expect(toRadians(180.0), closeTo(math.pi, 1e-15));
      expect(toRadians(90.0), closeTo(math.pi / 2, 1e-15));
      expect(toDegrees(math.pi), closeTo(180.0, 1e-13));
    });

    test('gidis-donus', () {
      for (final d in [0.0, 1.0, 37.4, -74.0, 359.999, -180.0]) {
        expect(toDegrees(toRadians(d)), closeTo(d, 1e-12), reason: '$d');
      }
    });
  });

  group('normalizeDegrees — [0, 360)', () {
    test('temel durumlar', () {
      expect(normalizeDegrees(0.0), 0.0);
      expect(normalizeDegrees(359.9), closeTo(359.9, 1e-12));
      expect(normalizeDegrees(360.0), 0.0);
      expect(normalizeDegrees(370.0), closeTo(10.0, 1e-12));
    });

    test('negatif girdiler dogru sarilir', () {
      expect(normalizeDegrees(-90.0), closeTo(270.0, 1e-12));
      expect(normalizeDegrees(-360.0), 0.0);
      expect(normalizeDegrees(-370.0), closeTo(350.0, 1e-12));
    });

    test('cok tur donen degerler', () {
      expect(normalizeDegrees(360.0 * 1000 + 45.0), closeTo(45.0, 1e-9));
      expect(normalizeDegrees(-360.0 * 1000 - 45.0), closeTo(315.0, 1e-9));
    });
  });

  group('normalizeDegreesSigned — [-180, 180)', () {
    test('isaret anlamli kaliyor', () {
      expect(normalizeDegreesSigned(0.0), 0.0);
      expect(normalizeDegreesSigned(179.0), closeTo(179.0, 1e-12));
      expect(normalizeDegreesSigned(181.0), closeTo(-179.0, 1e-12));
      expect(normalizeDegreesSigned(350.0), closeTo(-10.0, 1e-12));
      expect(normalizeDegreesSigned(-10.0), closeTo(-10.0, 1e-12));
    });

    test('180 sinirinda -180 tarafina duser', () {
      expect(normalizeDegreesSigned(180.0), closeTo(-180.0, 1e-12));
    });
  });

  group('saat <-> derece', () {
    test('1 saat = 15 derece', () {
      expect(hoursToDegrees(1.0), 15.0);
      expect(hoursToDegrees(24.0), 360.0);
      expect(degreesToHours(360.0), 24.0);
    });

    test('normalizeHours', () {
      expect(normalizeHours(25.0), closeTo(1.0, 1e-12));
      expect(normalizeHours(-1.0), closeTo(23.0, 1e-12));
      expect(normalizeHours(24.0), 0.0);
    });
  });

  group('formatHms', () {
    test('Meeus 12.a referans degeri', () {
      // 197.69319506 derece = 13h10m46.3668s
      expect(
        formatHms(degreesToHours(197.69319506), decimals: 4),
        '13h10m46.3668s',
      );
    });

    test('tek haneli saat sifirla doldurulmaz (astronomi yazimi)', () {
      expect(formatHms(8.582524889, decimals: 4), '8h34m57.0896s');
    });

    test('yuvarlama tasmasi dogru tasiniyor', () {
      // 23h59m59.9999s -> 2 basamakta 60.00 saniye -> basa donmeli.
      // Carry olmadan "23h60m00.00s" yazilirdi.
      expect(formatHms(23.99999999, decimals: 2), '0h00m00.00s');
    });

    test('negatif ve 24 ustu girdiler once normalize edilir', () {
      expect(formatHms(-1.0, decimals: 0), formatHms(23.0, decimals: 0));
      expect(formatHms(25.5, decimals: 0), formatHms(1.5, decimals: 0));
    });
  });

  group('formatDms', () {
    test('isaret her zaman yazilir', () {
      expect(formatDms(41.0233, decimals: 1), '+41°01′23.9″');
      expect(formatDms(-41.0233, decimals: 1), '-41°01′23.9″');
    });

    test('kucuk negatif deger isaretini kaybetmiyor', () {
      // -00°30′ ile +00°30′ arasindaki fark gozden kacmamali.
      expect(formatDms(-0.5, decimals: 1), '-00°30′00.0″');
      expect(formatDms(0.5, decimals: 1), '+00°30′00.0″');
    });

    test('sifir', () {
      expect(formatDms(0.0, decimals: 1), '+00°00′00.0″');
    });
  });

  group('regresyon: kayan nokta sinir durumlari', () {
    test('cok kucuk negatif girdi 360.0 dondurmemeli', () {
      // 360 civarinda bir ULP ~5.7e-14. -2.9e-15'e 360 eklenince sonuc
      // tam 360.0'a yuvarlanir ve [0, 360) sozlesmesi bozulurdu.
      // Kutup azimutu hesabinda trigonometrik artik tam bu buyuklukte cikiyor.
      for (final tiny in [-1e-16, -2.9e-15, -1e-14, -0.0]) {
        final r = normalizeDegrees(tiny);
        expect(r, greaterThanOrEqualTo(0.0), reason: '$tiny');
        expect(r, lessThan(360.0), reason: '$tiny');
      }
    });

    test('normalizeHours ayni tasmaya karsi korunmali', () {
      for (final tiny in [-1e-17, -1e-16, -0.0]) {
        final r = normalizeHours(tiny);
        expect(r, greaterThanOrEqualTo(0.0), reason: '$tiny');
        expect(r, lessThan(24.0), reason: '$tiny');
      }
    });
  });

  group('angularDifferenceDegrees', () {
    test('tur sinirinda dogru calisir', () {
      // Ciplak cikarma 359.9999 verirdi; dogru cevap ~0.
      expect(
        angularDifferenceDegrees(359.9999, 0.0).abs(),
        closeTo(0.0001, 1e-9),
      );
      expect(
        angularDifferenceDegrees(0.0, 359.9999).abs(),
        closeTo(0.0001, 1e-9),
      );
    });

    test('isaret yonu koruyor', () {
      expect(angularDifferenceDegrees(10.0, 0.0), closeTo(10.0, 1e-12));
      expect(angularDifferenceDegrees(0.0, 10.0), closeTo(-10.0, 1e-12));
    });

    test('en kisa yolu secer', () {
      // 350 ile 10 arasi 20 derece, 340 degil.
      expect(angularDifferenceDegrees(10.0, 350.0).abs(), closeTo(20.0, 1e-12));
    });
  });
}
