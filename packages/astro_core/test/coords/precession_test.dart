import 'package:astro_core/astro_core.dart';
import 'package:test/test.dart';

void main() {
  group('Meeus 21.b — theta Persei, 2028-11-13.19', () {
    // Ozdevinim (proper motion) Meeus tarafindan zaten uygulanmis konum.
    // Presesyon ile ozdevinim ayri duzeltmelerdir; bu paket sadece
    // presesyon yapar.
    final start = Equatorial.fromHours(
      rightAscensionHours: 2 + 44 / 60 + 12.9747 / 3600,
      declinationDegrees: 49 + 13 / 60 + 39.896 / 3600,
    );
    const targetJd = 2462088.69;

    test('sag aciklik 2h46m11.331s', () {
      final r = precessFromJ2000(j2000Position: start, toJd: targetJd);
      const expected = 2 + 46 / 60 + 11.331 / 3600;
      // 0.001 saniye = 0.015 yay saniyesi. Tolerans projenin ihtiyacinin
      // ~24.000 kati altinda; formulun dogru uygulandigini kanitliyor.
      expect(r.rightAscensionHours, closeTo(expected, 0.001 / 3600));
    });

    test('sapma +49°20\'54.54"', () {
      final r = precessFromJ2000(j2000Position: start, toJd: targetJd);
      const expected = 49 + 20 / 60 + 54.54 / 3600;
      expect(r.declinationDegrees, closeTo(expected, 0.05 / 3600));
    });
  });

  group('temel ozellikler', () {
    final star = Equatorial(
      rightAscensionDegrees: 45.0,
      declinationDegrees: 20.0,
    );

    test('sifir aralik konumu degistirmez', () {
      final r = precess(position: star, fromJd: j2000, toJd: j2000);
      expect(r.rightAscensionDegrees, closeTo(45.0, 1e-9));
      expect(r.declinationDegrees, closeTo(20.0, 1e-9));
    });

    test('ileri sonra geri: baslangica doner', () {
      final forward = precessFromJ2000(
        j2000Position: star,
        toJd: j2000 + 26 * 365.25,
      );
      final back = precess(
        position: forward,
        fromJd: j2000 + 26 * 365.25,
        toJd: j2000,
      );
      expect(
        angularSeparationDegrees(
          back.rightAscensionDegrees,
          back.declinationDegrees,
          star.rightAscensionDegrees,
          star.declinationDegrees,
        ),
        lessThan(1e-7),
      );
    });

    test('buyukluk: 26 yilda ~0.36 derece kayma', () {
      // Yol haritasinin iddiasi: "25 yilda 0.35 derece kayma yapar, ekle".
      // Ihmal edilirse projenin 0.1 derecelik toleransi tek basina asilir.
      final moved = precessFromJ2000(
        j2000Position: star,
        toJd: j2000 + 26 * 365.25,
      );
      final shift = angularSeparationDegrees(
        star.rightAscensionDegrees,
        star.declinationDegrees,
        moved.rightAscensionDegrees,
        moved.declinationDegrees,
      );
      expect(shift, greaterThan(0.30));
      expect(shift, lessThan(0.42));
    });

    test('kayma zamanla dogrusala yakin buyur', () {
      double shiftAfterYears(double years) {
        final m = precessFromJ2000(
          j2000Position: star,
          toJd: j2000 + years * 365.25,
        );
        return angularSeparationDegrees(
          star.rightAscensionDegrees,
          star.declinationDegrees,
          m.rightAscensionDegrees,
          m.declinationDegrees,
        );
      }

      final s10 = shiftAfterYears(10);
      final s20 = shiftAfterYears(20);
      expect(s20 / s10, closeTo(2.0, 0.02));
    });
  });

  group('kutba yakin cisimler — acos dali', () {
    // Kutup Yildizi J2000: RA 2h31m49.09s, Dec +89°15'50.8"
    final polaris = Equatorial.fromHours(
      rightAscensionHours: 2 + 31 / 60 + 49.09 / 3600,
      declinationDegrees: 89 + 15 / 60 + 50.8 / 3600,
    );

    test('sapma 90 dereceyi asmaz', () {
      for (final years in [26.0, 100.0, 500.0]) {
        final r = precessFromJ2000(
          j2000Position: polaris,
          toJd: j2000 + years * 365.25,
        );
        expect(r.declinationDegrees, lessThanOrEqualTo(90.0), reason: '$years');
        expect(r.declinationDegrees.isNaN, isFalse, reason: '$years');
      }
    });

    test('Kutup Yildizi 2100\'e dogru kutba yaklasir', () {
      // Bilinen astronomik olgu: en yakin gecis ~2100 civari.
      final now = precessFromJ2000(
        j2000Position: polaris,
        toJd: j2000 + 26 * 365.25,
      );
      expect(now.declinationDegrees, greaterThan(polaris.declinationDegrees));
    });

    test('ileri-geri gidis donus kutup yakininda da kapali', () {
      const jd = j2000 + 50 * 365.25;
      final forward = precessFromJ2000(j2000Position: polaris, toJd: jd);
      final back = precess(position: forward, fromJd: jd, toJd: j2000);
      expect(
        angularSeparationDegrees(
          back.rightAscensionDegrees,
          back.declinationDegrees,
          polaris.rightAscensionDegrees,
          polaris.declinationDegrees,
        ),
        lessThan(1e-6),
      );
    });
  });

  group('angularSeparationDegrees', () {
    test('ayni nokta sifir verir', () {
      expect(angularSeparationDegrees(45, 20, 45, 20), closeTo(0.0, 1e-12));
    });

    test('kutuptan kutba 180 derece', () {
      expect(angularSeparationDegrees(0, 90, 0, -90), closeTo(180.0, 1e-9));
    });

    test('ekvatorda boylam farki dogrudan ayrimdir', () {
      expect(angularSeparationDegrees(0, 0, 30, 0), closeTo(30.0, 1e-9));
    });

    test('tur sinirini dogru gecer', () {
      expect(angularSeparationDegrees(359, 0, 1, 0), closeTo(2.0, 1e-9));
    });

    test('cok kucuk ayrimlarda hassasiyet korunur', () {
      // acos tabanli formul burada gurultuye bogulurdu; haversine korur.
      expect(angularSeparationDegrees(0, 0, 0.0001, 0), closeTo(0.0001, 1e-12));
    });
  });
}
