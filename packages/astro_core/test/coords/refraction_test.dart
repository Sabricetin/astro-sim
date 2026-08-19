import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  /// Yay dakikasi cinsinden kirilma — okumasi kolay olsun diye.
  double arcminutes(double degrees) => degrees * 60.0;

  group('buyukluk tablosu — dokumandaki degerlerle ayni', () {
    test('gercek yukseklikten', () {
      final expected = <double, double>{
        45.0: 1.01,
        24.0: 2.25,
        10.0: 5.41,
        5.0: 9.67,
        0.0: 28.98,
      };
      expected.forEach((altitude, arcmin) {
        expect(
          arcminutes(refractionFromTrueAltitude(altitude)),
          closeTo(arcmin, 0.01),
          reason: '$altitude derece',
        );
      });
    });

    test('gorunur ufukta 34.5 yay dakikasi (klasik deger)', () {
      // Gunes ufkun altindayken bile gorunmesinin sebebi: kendi capi
      // ~32 yay dakikasi, kirilma ~34.
      expect(
        arcminutes(refractionFromApparentAltitude(0.0)),
        closeTo(34.5, 0.1),
      );
    });
  });

  group('projenin tolerans esigi', () {
    // Tolerans 0.1 derece = 6 yay dakikasi.
    const toleranceArcminutes = 6.0;

    test('45 derecede ihmal edilebilir', () {
      expect(
        arcminutes(refractionFromTrueAltitude(45)),
        lessThan(toleranceArcminutes / 4),
      );
    });

    test('24 derecede (galaktik merkez zirvesi) hala tolerans icinde', () {
      expect(
        arcminutes(refractionFromTrueAltitude(24)),
        lessThan(toleranceArcminutes / 2),
      );
    });

    test('10 derecenin altinda toleransi tek basina yer', () {
      // Bu, kirilmanin neden Faz 1'e eklendiginin sayisal gerekcesi.
      expect(
        arcminutes(refractionFromTrueAltitude(9)),
        greaterThan(toleranceArcminutes * 0.9),
      );
      expect(
        arcminutes(refractionFromTrueAltitude(5)),
        greaterThan(toleranceArcminutes),
      );
    });
  });

  group('temel ozellikler', () {
    test('kirilma hicbir yukseklikte negatif olmaz', () {
      // Saemundsson formulu basucuna cok yakinda kucuk negatif deger
      // uretir (isaret donmesi); kirpma bunu engelliyor.
      for (var h = -1.0; h <= 90.0; h += 0.5) {
        expect(
          refractionFromTrueAltitude(h),
          greaterThanOrEqualTo(0.0),
          reason: '$h derece',
        );
      }
    });

    test('ufuk ile 89 derece arasinda kesinlikle pozitif', () {
      for (var h = -1.0; h <= 89.0; h += 0.5) {
        expect(
          refractionFromTrueAltitude(h),
          greaterThan(0.0),
          reason: '$h derece',
        );
      }
    });

    test('yukseklik arttikca kirilma azalir', () {
      var previous = double.infinity;
      for (var h = 0.0; h <= 89.0; h += 1.0) {
        final r = refractionFromTrueAltitude(h);
        expect(r, lessThan(previous), reason: '$h derece');
        previous = r;
      }
    });

    test('basucunda neredeyse sifir', () {
      expect(arcminutes(refractionFromTrueAltitude(90)), lessThan(0.02));
    });

    test('gorunur yukseklik her zaman gercekten buyuk', () {
      for (final h in [0.0, 5.0, 24.0, 45.0, 80.0]) {
        expect(apparentAltitudeDegrees(h), greaterThan(h), reason: '$h');
      }
    });
  });

  group('gidis-donus: gercek <-> gorunur', () {
    test('iki formul birbirinin tersi (kucuk artik ile)', () {
      // Saemundsson ve Bennett bagimsiz uydurmalardir; tam tersi degiller.
      // Artik, projenin toleransinin cok altinda kalmali.
      for (final trueAlt in [0.0, 2.0, 5.0, 10.0, 24.0, 45.0, 80.0]) {
        final apparent = apparentAltitudeDegrees(trueAlt);
        final back = trueAltitudeDegrees(apparent);
        expect(
          arcminutes((back - trueAlt).abs()),
          lessThan(0.2),
          reason: '$trueAlt derece',
        );
      }
    });
  });

  group('basinc ve sicaklik', () {
    test('yuksek rakimda kirilma azalir', () {
      // ~2000 m'de basinc ~795 mbar.
      final seaLevel = refractionFromTrueAltitude(10);
      final highAltitude = refractionFromTrueAltitude(
        10,
        pressureMillibars: 795,
      );
      expect(highAltitude, lessThan(seaLevel));
      expect(highAltitude / seaLevel, closeTo(795 / 1010, 0.01));
    });

    test('soguk havada kirilma artar', () {
      final warm = refractionFromTrueAltitude(10, temperatureCelsius: 30);
      final cold = refractionFromTrueAltitude(10, temperatureCelsius: -10);
      expect(cold, greaterThan(warm));
    });

    test('standart kosullar carpani tam 1', () {
      final withDefaults = refractionFromTrueAltitude(10);
      final explicit = refractionFromTrueAltitude(
        10,
        pressureMillibars: standardPressureMillibars,
        temperatureCelsius: standardTemperatureCelsius,
      );
      expect(explicit, closeTo(withDefaults, 1e-15));
    });
  });

  group('ufkun altinda', () {
    test('taban degerin altinda patlamaz', () {
      // Formul -1 derecenin altinda fiziksel anlamini yitirir; sabitlenir.
      for (final h in [-5.0, -30.0, -90.0]) {
        final r = refractionFromTrueAltitude(h);
        expect(r.isFinite, isTrue, reason: '$h');
        expect(r, greaterThan(0.0), reason: '$h');
      }
    });

    test('taban degerin altinda hep ayni sonuc', () {
      expect(
        refractionFromTrueAltitude(-30),
        closeTo(refractionFromTrueAltitude(refractionFloorDegrees), 1e-15),
      );
    });
  });
}
